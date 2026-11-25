#!/usr/bin/env bash
# 130 -- so leitura: onde a V1.0 (main 1.0.288) trata o Economico/hostel com horario e areas diferentes do Smart.
set -u
exec 2>&1
G="git -c safe.directory=* -C /opt/pms-banana-ai-fila.git"
F() { echo "=== $1 ($2)"; $G show main:SISTEMA/api/app/$1 2>&1 | sed -n "$2p" | cut -c1-220; }
F inventory/ipiranga.py 40,130
echo "=== Instance (core)"; $G grep -n -E "class Instance|checkin|check_in|checkout|check_out|start_hour|end_hour|hora_entrada|hora_saida" main -- SISTEMA/api/app/inventory SISTEMA/api/app/core | grep -v /tests/ | head -40 | cut -c1-220
echo "=== 18h/10h por instancia"; $G grep -n -E "time\(18|time\(10|\b18h\b.*10h|18h às 10h|18h-10h|18h–10h|hour *== *18|hour *< *10" main -- SISTEMA/api/app | grep -v /tests/ | head -40 | cut -c1-220
F reservation/perfil_mensagem.py 150,240
F finance/catalog.py 36,100
F messaging/inteligencia.py 600,640
F messaging/knowledge.py 175,190
F messaging/knowledge.py 352,372
F network/policy.py 55,80
echo "=== base_casa quintal/cozinha/hostel"; $G show main:SISTEMA/api/app/messaging/base_casa.json | sed -n '416,425p;865,870p;923,931p' | cut -c1-400
