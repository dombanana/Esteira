#!/usr/bin/env bash
# 008 -- so leitura: nomes reais das pastas da caixa (LIST) e quantos e-mails do Airbnb ha em cada (3 e 150 dias).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re
from collections import Counter
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr
from app.entrada import imap_reservas as I
cfg = I.config(os.environ); agora = datetime.now(timezone.utc)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
typ, pastas = M.list(); nomes = []
for p in pastas or []:
    s = p.decode(errors="ignore") if isinstance(p, bytes) else str(p)
    mm = re.match(r'\((?P<f>[^)]*)\)\s+(?:"[^"]*"|\S+)\s+(?:"(?P<n1>(?:[^"\\]|\\.)*)"|(?P<n2>.+))$', s.strip())
    if mm and "\\Noselect" not in (mm.group("f") or ""): nomes.append((mm.group("n1") if mm.group("n1") is not None else mm.group("n2")).strip())
print("pastas:", nomes, "| configuradas:", cfg["pastas"])
for pasta in nomes:
    if M.select(f'"{pasta}"', readonly=True)[0] != "OK": print(f"  {pasta}: nao abre"); continue
    for dias in (3, 150):
        typ, d = M.search(None, "SINCE", (agora - timedelta(days=dias)).strftime("%d-%b-%Y"))
        ids = d[0].split() if d and d[0] else []
        air = 0
        for i in range(0, len(ids), 200):
            typ, resp = M.fetch(b",".join(ids[i:i+200]), "(BODY.PEEK[HEADER.FIELDS (FROM)])")
            for parte in resp:
                if isinstance(parte, tuple) and "airbnb" in parseaddr(str(email.message_from_bytes(parte[1]).get("From", "")))[1].lower(): air += 1
        print(f"  {pasta} · {dias} dias: {len(ids)} e-mail(s), do Airbnb: {air}")
M.logout()
PY
