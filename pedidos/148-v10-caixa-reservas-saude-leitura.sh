#!/usr/bin/env bash
# SO LEITURA: a V1.0 continua lendo a caixa de reservas? (diario dos ultimos 40 min, so linhas de IMAP/caixa, sem e-mail)
set -u; exec 2>&1
journalctl -u pms-banana-ai -u pms-banana-ai-worker --since "-40min" --no-pager 2>/dev/null | grep -iE "imap|caixa|reservas_email|login" | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<email>/g' | tail -25
echo "== teste de login (so o resultado, sem usuario)"
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PYTHONDONTWRITEBYTECODE=1 timeout 60 ../.venv/bin/python - <<'PY'
import os, imaplib
for pre in ("PMS_RESERVAS_IMAP", "PMS_RESERVAS_IMAP2"):
    u = os.environ.get(pre + "_USUARIO"); s = os.environ.get(pre + "_SENHA")
    srv = os.environ.get(pre + "_SERVIDOR") or os.environ.get("PMS_RESERVAS_IMAP_SERVIDOR") or "imap.hostinger.com"
    try:
        c = imaplib.IMAP4_SSL(srv, 993, timeout=20); c.login(u, s)
        typ, pastas = c.list()
        print(pre, "login ok |", srv, "| pastas:", len(pastas or []))
        c.logout()
    except Exception as e:
        print(pre, "ERRO", type(e).__name__, str(e)[:120].replace(u or "x", "<u>"))
PY
