#!/usr/bin/env bash
# SO LEITURA (codigo): onde a V1.0 guarda as aberturas de porta (registro da entrada, cameras, aviso do webhook)
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -n "store\.[a-z_]*\|getattr(store, \"[a-z_]*\"\|ctx.change(\"[a-z_]*\"" $A/reservation/entry_log.py | grep -oE "store\.[a-z_]+|getattr\(store, \"[a-z_]+\"|ctx.change\(\"[a-z_]+\"" | sort | uniq -c
echo "=== cameras/aberturas.py"; sed -n 1,60p $A/cameras/aberturas.py
echo "=== tuya_aberturas"; grep -rn "tuya_aberturas" $A --include=*.py | grep -v tests | head -3
echo fim
