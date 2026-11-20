#!/usr/bin/env bash
# Gera e envia um pedido SO LEITURA da sombra dos ventiladores (V1.1 Automacao 1.1.0, Dom 20/11 18h03).
# Uso: ferramentas/sombra-vent.sh   (a partir da raiz do repositorio Esteira)
set -eu
cd "$(dirname "$0")/.."
git pull -q
n=$(ls pedidos | grep -oE '^[0-9]+' | sort -n | tail -1); n=$(printf "%03d" $((10#$n + 1)))
quando=$(TZ=America/Sao_Paulo date +%Y%m%d-%H%M)
f="pedidos/$n-sombra-vent-$quando-leitura.sh"
cat > "$f" <<'EOF'
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
hora = at.astimezone(ZoneInfo(st.store.timezone)).strftime("%Y-%m-%d %H:%M")
aps = V.aparelhos(); print("cache:", len(ultimo(st)), "aparelhos")
for q in ("Q07", "Q08", "Q09", "Q10"):
    ap = aps.get(q)
    if not ap: print(f"SOMBRA;{hora};{q};?;?;?;sem aparelho"); continue
    oc = V.hospede_do_quarto(st.store, q, at) is not None
    print(f"SOMBRA;{hora};{q};{int(oc)};{V.estado_real(st, ap)};{V.vel_real(st, ap)};{int(V.fora_do_ar(st, ap))}")
PY
echo "fim"
EOF
chmod +x "$f"; git add "$f"; git commit -qm "$(basename "$f") (sombra ventiladores, so leitura)"; git push -q
echo "$f"
