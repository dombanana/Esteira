#!/usr/bin/env bash
# 018 -- so leitura do CODIGO instalado (sem dados): onde o sistema decide pelo canal da reserva, e o link /<codigo>
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api/app || exit 1
echo "== channel == / channel in"; grep -rnE "\.channel *(==|!=|in |not in )|channel *== *\"|\"nobeds\"" --include=*.py . | grep -v /tests/ | cut -c1-170 | head -80
echo "== link por codigo (rota raiz)"; grep -rnE "@(app|router)\.get\(\"/\{|external_id\.isdigit|ota_code" --include=*.py . | grep -v /tests/ | cut -c1-170 | head -40
echo "== allocate_beds / has_beds"; grep -rn "def allocate_beds\|def has_beds\|def instance(" --include=*.py . | head
echo "== PMS_RESERVAS_IMAP"; grep -rn "PMS_RESERVAS_IMAP" --include=*.py . | grep -v tests | cut -c1-160
