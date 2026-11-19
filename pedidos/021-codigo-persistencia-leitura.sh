#!/usr/bin/env bash
# 021 -- so leitura do CODIGO: como um "kind" do ctx.change vira tabela/memoria (para criar um kind novo sem quebrar)
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api/app || exit 1
grep -rn "\"entrada\"" --include=*.py . | grep -v /tests/ | cut -c1-200 | head -20
echo ==; grep -rln "host_alert\b\|\"host_alert\"" --include=*.py . | grep -v tests | head
echo ==; grep -rn "def _apply\|KIND_TABLE\|_KINDS\s*=\|def replay\|def aplicar_change\|kinds\s*=\s*{" --include=*.py core persist* store* db* 2>/dev/null | head -20
ls
