#!/usr/bin/env bash
# SO LEITURA (codigo + estado dos ventiladores 02-11): como a automacao em massa do anfitriao (v1.0.283) liga
# ventiladores e se ha ordem ativa. Dom 21/11 14h07 pediu ligar todos os ventiladores na fraca (o que estiver na alta fica).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
grep -nE "^def |^    def |^[A-Z_]+ = " $A/tuya_casa/anfitriao.py
sed -n 1,200p $A/tuya_casa/anfitriao.py
echo "== intents/rotas que chamam anfitriao"
grep -rn "anfitriao\." $A --include=*.py | grep -v "^$A/tuya_casa/anfitriao.py" | grep -v tests | head -20
cd /opt/PMS-Banana-AI/SISTEMA/api
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from datetime import datetime, timezone
from app.main import build_state
from app.tuya_casa import ventilador as V
from app.tuya_casa.service import _refrescar, ultimo
st = build_state(); at = datetime.now(timezone.utc); _refrescar(st, os.environ, at)
aps = V.aparelhos(); print("cache", len(ultimo(st)), "invertidos", sorted(V.invertidos()))
for q in sorted(aps):
    ap = aps[q]; e = V.hospede_do_quarto(st.store, q, at)
    row = (getattr(st.store, "tuya_vent", {}) or {}).get(q) or {}
    print(q, "ocupado=%d" % (e is not None), "ligado=%s" % V.estado_real(st, ap), "vel=%s" % V.vel_real(st, ap), "fora=%d" % V.fora_do_ar(st, ap), "modo_hospede=%s" % (V.linha(st.store, q, e.event_id)["modo"] if e else "-"))
print("ordens do anfitriao:", {k: v for k, v in (getattr(st.store, "anfitriao_ordens", {}) or {}).items()} if hasattr(st.store, "anfitriao_ordens") else "campo?")
PY
echo fim
