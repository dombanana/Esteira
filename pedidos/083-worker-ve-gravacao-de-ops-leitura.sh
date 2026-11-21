#!/usr/bin/env bash
# SO LEITURA (codigo): o worker e a API enxergam o que um script de ops grava no banco? (recarga do store)
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -n "recarreg\|reload\|build_state\|refresh_store\|sincroniz\|novidades\|ler_novos\|tail_ledger\|catch_up\|replay" $A/worker.py | head -30
grep -rn "def recarregar\|def reload\|def catch_up\|def acompanhar" $A --include=*.py | grep -v tests | head
echo "== tuya_vent_aplicar"; grep -rn "tuya_vent_aplicar" $A --include=*.py | grep -v tests | head -5
echo fim
