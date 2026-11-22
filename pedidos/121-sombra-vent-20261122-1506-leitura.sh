#!/usr/bin/env bash
# SO LEITURA -- sombra dos ventiladores Q07-Q10 (V1.1). Le a memoria da ponte Tuya NESTE processo (GET), sem comando,
# sem salvar nada. Saida: SOMBRA;hora;quarto;ocupado;ligado;vel;fora_do_ar. Sem nome, codigo ou valor.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from app.main import build_state
from app.tuya_casa import ventilador as V
from app.tuya_casa.service import _refrescar, ultimo
st = build_state(); at = datetime.now(timezone.utc)
_refrescar(st, os.environ, at)
if not ultimo(st):                      # a ponte nao respondeu (aconteceu em 21/11 11h): tenta mais 2 vezes
    import time
    from app.tuya_casa import service as SV
    for _ in range(2):
        time.sleep(8); SV._refrescado.clear(); _refrescar(st, os.environ, datetime.now(timezone.utc))
        if ultimo(st): break
hora = at.astimezone(ZoneInfo(st.store.timezone)).strftime("%Y-%m-%d %H:%M")
aps = V.aparelhos(); print("cache:", len(ultimo(st)), "aparelhos")
for q in ("Q07", "Q08", "Q09", "Q10"):
    ap = aps.get(q)
    if not ap: print(f"SOMBRA;{hora};{q};?;?;?;sem aparelho"); continue
    oc = V.hospede_do_quarto(st.store, q, at) is not None
    print(f"SOMBRA;{hora};{q};{int(oc)};{V.estado_real(st, ap)};{V.vel_real(st, ap)};{int(V.fora_do_ar(st, ap))}")
PY
echo "fim"
