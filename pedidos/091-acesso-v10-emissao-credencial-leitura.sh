#!/usr/bin/env bash
# SO LEITURA (codigo): emissao/retirada no adaptador TTLock, formato da credencial e o mapa das fechaduras
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "===== adapters.py 1135-1240"; sed -n 1135,1240p $A/reservation/adapters.py
echo "===== adapters.py 1380-1500"; sed -n 1380,1500p $A/reservation/adapters.py
echo "===== adapters.py 1640-1900"; sed -n 1640,1900p $A/reservation/adapters.py
echo "===== house_locks"; grep -n "def house_locks" -A30 $A/worker.py
echo fim
