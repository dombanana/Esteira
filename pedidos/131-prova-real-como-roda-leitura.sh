#!/usr/bin/env bash
# 131 -- so leitura: como a "prova real" roda no teste sem instalar (nomes e cabecalhos em ops/), no main da fila.
set -u
exec 2>&1
G="git -c safe.directory=* -C /opt/pms-banana-ai-fila.git"
$G ls-tree -r --name-only main SISTEMA/ops | grep -i -E "prova|instalar|reinstal|teste" | head -30
for f in $($G ls-tree -r --name-only main SISTEMA/ops | grep -i -E "prova_real|prova-real|instalar-do-git" | head -3); do echo "=== $f"; $G show main:$f | head -60 | cut -c1-200; done
echo "=== quem chama prova"; $G grep -n -i -E "prova(_| )real|prova_real|30/30" main -- SISTEMA/ops | head -20 | cut -c1-200
