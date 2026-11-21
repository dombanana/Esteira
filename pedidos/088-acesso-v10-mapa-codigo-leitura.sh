#!/usr/bin/env bash
# SO LEITURA (codigo, nada de API): mapa do acesso/fechaduras da V1.0 para virar modulo da V1.1
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
cd $A
echo "== arquivos"; grep -rlE "ttlock|keyboardPwd|TtlockClient|house_locks" --include=*.py . | grep -v tests | xargs wc -l | sort -n | tail -40
echo "== rota do aviso"; grep -rn "ttlock/aviso\|def ttlock_aviso\|callback" --include=*.py . | grep -iv test | grep -i "ttlock\|aviso" | head -20
echo "== defs doors"; grep -n "^def \|^class \|^[A-Z_]* = " reservation/doors.py | head -80
echo "== intents de acesso"; grep -rn "name=\"access\.\|name=\"porta\.\|name=\"door\.\|name=\"lock\." --include=*.py . | grep -v tests | head -40
echo fim
