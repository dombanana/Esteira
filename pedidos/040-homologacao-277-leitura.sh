#!/usr/bin/env bash
# 040 -- HOMOLOGACAO (so leitura) da 1.0.277: versao, servicos, link de codigo do Airbnb desconhecido -> 202 "preparando",
# link conhecido continua 200, numero errado continua 404, Nobeds ainda ligada (contrato ate 26/11) e e-mail ligado.
set -u
exec 2>&1
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' /opt/PMS-Banana-AI/SISTEMA/api/app/versao.py) · worker: $(systemctl is-active pms-banana-ai-worker.service) · API: $(systemctl is-active pms-banana-ai.service)"
A=http://127.0.0.1:8090
echo "codigo do Airbnb que nao existe (HMZZZZ9999): $(curl -s -o /tmp/r40 -w '%{http_code}' -H 'X-Lang: pt' $A/api/h/HMZZZZ9999) · $(head -c 160 /tmp/r40)"
echo "numero que nao existe (1234567): $(curl -s -o /dev/null -w '%{http_code}' $A/api/h/1234567)"
echo "pagina do hospede com a espera: $(curl -s $A/HMZZZZ9999 | grep -c 'r.status===202&&r.preparando')"
journalctl -u pms-banana-ai-worker --since "20 min ago" --no-pager -o cat 2>/dev/null | grep -iE "Nobeds desligada|reconciliacao:|caixa das reservas|calend.rio do Airbnb" | tail -4 | sed -E 's/HM[A-Z0-9]{8}/HM******/g' | cut -c1-160
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 120 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from app.channel import nobeds_fim as NF
from app.entrada import airbnb_reservas as AR, airbnb_ical as IC
from app.main import build_state
s = build_state().store
r = [x for x in s.reservations.values() if (x.ota_code or "").startswith("HMF9")]
print("Nobeds ligada agora:", NF.ligada(), "· desliga em", NF.ATE_PADRAO, "· e-mail:", AR.modo(), "· calendario:", IC.modo())
print("reserva HMF9 continua na casa:", bool(r), "· status:", r[0].status.value if r else "-")
PY
