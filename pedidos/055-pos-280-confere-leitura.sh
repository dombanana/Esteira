#!/usr/bin/env bash
# 055 -- HOMOLOGACAO (so leitura) da 1.0.280: versao no ar, servicos, a trava das 14h presente no codigo instalado.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
for i in $(seq 1 20); do
  V=$(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)
  [ "$V" = "1.0.280" ] && break
  sleep 15
done
echo "no ar: $V · worker: $(systemctl is-active pms-banana-ai-worker.service) · API: $(systemctl is-active pms-banana-ai.service)"
echo "trava 14h no codigo: $(grep -c '_trava_aparelhos' $A/panel/guest_service.py) chamadas (esperado 4: definicao + luz + ar + ventilador)"
echo "teste da 280 instalado: $(ls $A/panel/tests/ | grep -c v1280)"
echo "API responde: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8090/api/h/1234567) (esperado 404)"
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -m pytest -q -p no:cacheprovider app/panel/tests/test_v1280_aparelhos_so_a_partir_das_14h.py 2>&1 | tail -2
