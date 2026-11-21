#!/usr/bin/env bash
# SO LEITURA (codigo): o cofre registra leitura? ajustes de portas (_ajustar_portas/_armarios), o lookup do evento,
# o inbox (como listar) e as liberdades das instancias. Nenhuma chamada a TTLock.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "===== Vault.open"; grep -n "class Vault" -A60 $A/record/persistence.py | grep -n "def open\|def put\|def __contains__\|INSERT\|access" | head -20
grep -n "    def open" -A25 $A/record/persistence.py | head -40
echo "===== _janela/_ajustar/_armarios"; sed -n 1600,1640p $A/reservation/adapters.py
echo "===== _event_lookup"; grep -rn "def _event_lookup" -A50 $A/worker.py | head -70
echo "===== inbox"; grep -rn "class .*Inbox" -A30 $A/core/*.py $A/record/*.py | grep -n "def \|class" | head -20
echo "===== SMART/HOSTEL"; grep -n "^SMART\|^HOSTEL" -A3 $A/inventory/ipiranga.py
echo fim
