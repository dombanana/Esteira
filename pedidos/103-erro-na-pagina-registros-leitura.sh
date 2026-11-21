#!/usr/bin/env bash
# SO LEITURA: guest_service.erro_na_pagina (onde grava) e os ultimos erros de pagina de hoje (so o que a pagina mandou:
# tela, mensagem, arquivo, linha). Sem dado pessoal.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn "def erro_na_pagina" -A40 $A --include=*.py | grep -v tests | head -50
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import json
from app.main import build_state
st = build_state(); s = st.store
for nome in [a for a in dir(s) if "erro" in a or "pagina" in a or "falha" in a]:
    col = getattr(s, nome, None)
    if isinstance(col, dict) and col:
        itens = sorted(col.values(), key=lambda r: str((r if isinstance(r, dict) else {}).get("at") or (r if isinstance(r, dict) else {}).get("quando") or ""))
        print("==", nome, len(itens))
        for r in itens[-12:]:
            if isinstance(r, dict):
                print("  ", json.dumps({k: (str(v)[:160]) for k, v in r.items() if k not in ("ip", "person", "pessoa", "nome", "event_id")}, ensure_ascii=False))
PY
echo fim
