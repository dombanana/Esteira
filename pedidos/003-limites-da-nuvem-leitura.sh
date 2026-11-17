#!/usr/bin/env bash
# 003 -- prova dos limites da esteira na nuvem (17/11): o pedido 002 (sem "-leitura") NAO pode rodar; o usuario nao vira root.
set -u
exec 2>&1
echo "virar root: $(sudo -n true 2>/dev/null && echo 'SIM (ERRADO)' || echo 'nao (certo)')"
echo "escrever no sistema: $(touch /opt/PMS-Banana-AI/SISTEMA/.teste-nuvem 2>/dev/null && { rm -f /opt/PMS-Banana-AI/SISTEMA/.teste-nuvem; echo 'SIM (ERRADO)'; } || echo 'nao (certo)')"
echo "ler a pasta do root: $(ls /root >/dev/null 2>&1 && echo 'SIM (ERRADO)' || echo 'nao (certo)')"
echo "porteiro roda como: $(sudo -n /opt/esteira-nuvem/com-segredos id -un 2>&1)"
echo "segredos no ambiente da leitura: $(env | grep -c '^PMS_') (tem que ser 0)"
echo "saida do 002 existe: $([ -e /var/lib/esteira-nuvem/repo/saidas/002-instalar-nao-deve-rodar.sh.txt ] && echo 'SIM (ERRADO)' || echo 'nao (certo)')"
