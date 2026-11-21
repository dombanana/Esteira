#!/usr/bin/env bash
# SO LEITURA (codigo): ops/anfitriao_agir.py e V._chamar/luz.tuya_vent_aplicar (como um script de ops manda o ventilador).
set -u
exec 2>&1
cat /opt/PMS-Banana-AI/SISTEMA/ops/anfitriao_agir.py
echo "== tuya_vent_aplicar"; grep -n "tuya_vent_aplicar" -A40 /opt/PMS-Banana-AI/SISTEMA/api/app/tuya_casa/service.py | head -70
echo fim
