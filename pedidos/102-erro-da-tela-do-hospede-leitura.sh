#!/usr/bin/env bash
# SO LEITURA: o que a tela do hospede reportou em POST /api/h/<codigo>/erro (onde fica gravado e as ultimas entradas,
# so mensagem/arquivo/linha do erro de JavaScript; sem dado pessoal). Versao do front.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn '"/api/h/{code}/erro"\|/erro"' $A --include=*.py | grep -v tests | head -5
f=$(grep -rln '/erro"' $A --include=*.py | grep -v tests | head -1); echo "arquivo: $f"
grep -n '/erro"' -A30 "$f" | head -45
echo "== journal (erros reportados pela tela)"
journalctl -u pms-banana-ai --since "-8h" --no-pager -q 2>/dev/null | grep -iE "tela do hospede|erro da tela|front|js:|javascript|TypeError|ReferenceError|SyntaxError|undefined" | sed -E 's/\b[0-9a-f]{20,}\b/<id>/g' | tail -30
echo fim
