#!/usr/bin/env bash
# SO LEITURA: ordens/regras do anfitriao que existem hoje (automacao_ordens/regras) e como os scripts de ops gravam
# (se usam o router direto ou a API), para ligar os ventiladores pedidos pelo Dom (21/11 14h07).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
ls ../ops | head -60
echo "== ops/entregas_ota.py (inicio)"; sed -n 1,60p ../ops/entregas_ota.py
grep -ln "router.call\|unit_of_work" ../ops/*.py | head
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from app.main import build_state
st = build_state(); s = st.store
print("ordens:", {k: {x: v.get(x) for x in ("ligar", "ate", "origem", "solta", "at")} for k, v in (getattr(s, "automacao_ordens", {}) or {}).items()})
print("regras:", [{x: r.get(x) for x in ("nome", "tipo", "chaves", "liga", "desliga", "ocupados", "ativa", "removida")} for r in (getattr(s, "automacao_regras", {}) or {}).values()])
PY
echo fim
