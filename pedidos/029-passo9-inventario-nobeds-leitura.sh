#!/usr/bin/env bash
# 029 -- so leitura: por que o passo 9 (inventario do Nobeds) da instalacao de hoje falhou (linhas do registro, sem segredo)
set -u
exec 2>&1
L=$(ls -t /opt/PMS-Banana-AI/subida-v1-*.log 2>/dev/null | head -1); echo "registro: $L"
[ -r "$L" ] || { echo "(sem acesso ao registro)"; exit 0; }
grep -n -iE "passo 9|inventario|nobeds|401|402|404|Traceback|Error" "$L" | grep -viE "token|senha|password|secret" | tail -40 | cut -c1-220
