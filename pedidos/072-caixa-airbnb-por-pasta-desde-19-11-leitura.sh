#!/usr/bin/env bash
# SO LEITURA -- em que pasta estao hoje os e-mails do Airbnb chegados desde 19/11 (contagem por pasta e por dia; so
# remetente/data, nada de assunto ou texto).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os
from collections import Counter
from email.utils import parseaddr, parsedate_to_datetime
from app.entrada import imap_reservas as I
from app.entrada.intents import ota_do_dominio
cfg = I.config(os.environ)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
for pasta in ("INBOX", "INBOX.03_Reservas", "INBOX.05_Sistemas_e_Logs", "INBOX.02_Pagamentos", "INBOX.04_Seguranca", "INBOX.Junk", "INBOX.Trash"):
    t, _ = M.select(f'"{pasta}"', readonly=True)
    if t != "OK": print(pasta, t); continue
    t, d = M.search(None, "(SINCE 19-Nov-2026)")
    c = Counter()
    for num in (d[0] or b"").split():
        t, x = M.fetch(num, "(BODY.PEEK[HEADER.FIELDS (FROM DATE)])")
        h = email.message_from_bytes(x[0][1]); o = ota_do_dominio(parseaddr(I._dec(h.get("From")))[1].lower().rsplit("@", 1)[-1]) or "outro"
        try: dia = parsedate_to_datetime(str(h.get("Date"))).strftime("%d/%m")
        except Exception: dia = "?"
        c[f"{o} {dia}"] += 1
    print(pasta, dict(sorted(c.items())))
M.logout()
PY
echo fim
