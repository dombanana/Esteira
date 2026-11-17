#!/usr/bin/env bash
# 004 -- prova dos limites depois do en4 (disco so leitura para a nuvem, 17/11).
set -u
exec 2>&1
echo "virar root: $(sudo -n true 2>/dev/null && echo 'SIM (ERRADO)' || echo 'nao (certo)')"
echo "escrever no sistema: $(touch /opt/PMS-Banana-AI/SISTEMA/.teste-nuvem 2>/dev/null && { rm -f /opt/PMS-Banana-AI/SISTEMA/.teste-nuvem; echo 'SIM (ERRADO)'; } || echo 'nao (certo)')"
echo "ler a pasta do root: $(ls /root >/dev/null 2>&1 && echo 'SIM (ERRADO)' || echo 'nao (certo)')"
echo "porteiro roda como: $(sudo -n /opt/esteira-nuvem/com-segredos id -un 2>&1)"
echo "segredos no ambiente da leitura: $(env | grep -c '^PMS_') (tem que ser 0)"
echo "escrever como pms: $(sudo -n /opt/esteira-nuvem/com-segredos touch /var/lib/pms-banana-ai/.teste-nuvem 2>/dev/null && echo "SIM (ERRADO)" || echo "nao (certo)")"
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -c "from app.main import build_state; from app.versao import VERSAO; s=build_state(); print('abre o sistema: sim', VERSAO)" 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)' | tail -1
