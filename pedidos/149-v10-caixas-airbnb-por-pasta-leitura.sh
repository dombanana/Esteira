#!/usr/bin/env bash
# SO LEITURA (BODY.PEEK, readonly): quantos e-mails do Airbnb (3 dias) ha em cada pasta das duas caixas da V1.0.
set -u; exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PYTHONDONTWRITEBYTECODE=1 timeout 120 ../.venv/bin/python - <<'PY'
import os, imaplib, email, re
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr
desde = (datetime.now(timezone.utc) - timedelta(days=3)).strftime("%d-%b-%Y")
print("pastas configuradas na V1.0:", os.environ.get("PMS_RESERVAS_IMAP_PASTAS"), "|", os.environ.get("PMS_RESERVAS_IMAP2_PASTAS"))
for pre in ("PMS_RESERVAS_IMAP", "PMS_RESERVAS_IMAP2"):
    u = os.environ.get(pre + "_USUARIO"); s = os.environ.get(pre + "_SENHA")
    c = imaplib.IMAP4_SSL("imap.hostinger.com", 993, timeout=20); c.login(u, s)
    typ, lst = c.list()
    nomes = []
    for l in lst or []:
        m = re.search(rb'"([^"]+)"\s*$|\s(\S+)$', l)
        nomes.append((m.group(1) or m.group(2)).decode() if m else l.decode())
    print(pre, "pastas:", nomes)
    for p in nomes:
        typ, _ = c.select(f'"{p}"', readonly=True)
        if typ != "OK":
            print("  ", p, "nao abre"); continue
        typ, d = c.search(None, f"(SINCE {desde})")
        n = air = 0
        for num in (d[0] or b"").split():
            n += 1
            typ, cab = c.fetch(num, "(BODY.PEEK[HEADER.FIELDS (FROM)])")
            if typ == "OK" and cab and isinstance(cab[0], tuple):
                rem = parseaddr(email.message_from_bytes(cab[0][1]).get("From") or "")[1].lower()
                if rem.rsplit("@", 1)[-1].endswith("airbnb.com") or ".airbnb." in rem or rem.endswith("airbnb.com.br"):
                    air += 1
        print("  ", p, "| 3 dias:", n, "| do Airbnb:", air)
    c.logout()
PY
