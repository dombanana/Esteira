#!/usr/bin/env bash
# 043 -- so leitura: a versao no ar e o main da fila (outra sessao pode ter andado), e os testes do IMAP que existem.
set -u
exec 2>&1
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' /opt/PMS-Banana-AI/SISTEMA/api/app/versao.py)"
git -C /opt/pms-banana-ai-fila.git log --oneline -4 main 2>&1 | cut -c1-100
git -C /opt/pms-banana-ai-fila.git for-each-ref --sort=-committerdate --format='%(refname:short) %(objectname:short) %(committerdate:iso)' refs/heads 2>&1 | head -8
ls /opt/PMS-Banana-AI/SISTEMA/api/app/entrada/tests/ 2>&1 | grep -iE "imap|243|275" 
