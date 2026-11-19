#!/usr/bin/env bash
# 016 -- so leitura: versao no ar e os ramos da fila de versoes (para montar a proxima versao sem pisar em outra sessao)
set -u
exec 2>&1
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' /opt/PMS-Banana-AI/SISTEMA/api/app/versao.py)"
cd /tmp
F=/opt/pms-banana-ai-fila.git
sudo -n /opt/esteira-nuvem/com-segredos git -C $F for-each-ref --sort=-committerdate --count=15 --format='%(committerdate:iso) %(refname:short) %(objectname:short)' refs/heads 2>&1 | head -20
echo "--- main:"; sudo -n /opt/esteira-nuvem/com-segredos git -C $F log --oneline -8 main 2>&1 | cut -c1-120
echo "--- instalado (repositorio do sistema):"; sudo -n /opt/esteira-nuvem/com-segredos git -C /opt/PMS-Banana-AI log --oneline -3 2>&1 | cut -c1-120
ls -t /root/relatorios 2>/dev/null | head -3 || echo "(relatorios: sem acesso)"
