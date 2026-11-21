#!/usr/bin/env bash
# SO LEITURA (codigo): doors.py, access.py, rota do aviso e a leitura do aviso no servico de luz
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "===== reservation/doors.py"; cat $A/reservation/doors.py
echo "===== reservation/access.py"; cat $A/reservation/access.py
echo "===== luz/routes.py"; cat $A/luz/routes.py
echo "===== luz/service.py 240-330"; sed -n 240,330p $A/luz/service.py
echo fim
