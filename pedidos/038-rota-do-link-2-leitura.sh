#!/usr/bin/env bash
# 038 -- so leitura do CODIGO: quem usa link_aliases (a pagina que abre dombanana.tech/<codigo>)
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api/app || exit 1
grep -rn "link_aliases\|def _por_link\|def reserva_do_link\|nao encontrad\|Reserva n.o encontrada" --include=*.py . | grep -v /tests/ | cut -c1-180 | head -30
echo ==; grep -rnE "\.(get|api_route)\(\"/\{" --include=*.py . | grep -v tests | cut -c1-160 | head
echo ==; grep -rn "www.dombanana.tech\|server_name www" /etc/nginx/sites-enabled/*.conf 2>/dev/null | head -5
