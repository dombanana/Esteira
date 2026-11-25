#!/usr/bin/env bash
# 134 -- so leitura: o main da fila e a versao no ar continuam na 1.0.288 (antes de instalar a 289)?
set -u
exec 2>&1
G="git -c safe.directory=* -C /opt/pms-banana-ai-fila.git"
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' /opt/PMS-Banana-AI/SISTEMA/api/app/versao.py)"
$G log --format='%h %ci %s' -2 main | cut -c1-140
$G for-each-ref --sort=-committerdate --format='%(refname:short) %(objectname:short) %(committerdate:iso)' refs/heads | head -3
