#!/usr/bin/env bash
# SO LEITURA -- depurar por que a janela de 30 h da sombra diaria achou 0 e-mails (so contagens e datas dos cabecalhos).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
from app.entrada import imap_reservas as I
from app.entrada.intents import ota_do_dominio
cfg = I.config(os.environ); agora = datetime.now(timezone.utc)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
for pasta in cfg["pastas"]:
    typ, x = M.select(f'"{pasta}"', readonly=True); print("pasta", pasta, typ, x)
    typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=3)).strftime('%d-%b-%Y')})")
    nums = (d[0] or b"").split(); print("  SINCE 3 dias:", len(nums))
    for num in nums[-12:]:
        t, c = M.fetch(num, "(BODY.PEEK[HEADER.FIELDS (FROM DATE)])")
        h = email.message_from_bytes(c[0][1]); rem = parseaddr(I._dec(h.get("From")))[1].lower()
        print("  ", ota_do_dominio(rem.rsplit("@", 1)[-1]) or "outro", "|", str(h.get("Date"))[:40])
M.logout()
PY
echo fim
