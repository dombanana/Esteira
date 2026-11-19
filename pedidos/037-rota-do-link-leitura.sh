#!/usr/bin/env bash
# 037 -- so leitura do CODIGO: a rota que abre dombanana.tech/<codigo> (para a rede de seguranca do link) e o refresh da API
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api/app || exit 1
grep -rnE "def normalize_reservation_alias|def resolve_alias|def achar_reserva|alias" --include=*.py . | grep -v /tests/ | grep -E "def |@" | head -20
echo ==; grep -rnE "@(app|router)\.(get|api_route)\(\"/\{[a-z_]+\}\"" --include=*.py . | grep -v tests | head
echo ==; grep -rn "def refresh" --include=*.py . | grep -v tests | head
echo ==; sed -n 1,5p /etc/nginx/sites-enabled/* 2>/dev/null | head -3; grep -rn "dombanana.tech" /etc/nginx/sites-enabled/ 2>/dev/null | head -5
