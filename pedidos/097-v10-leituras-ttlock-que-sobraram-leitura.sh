#!/usr/bin/env bash
# SO LEITURA (codigo e chaves sem segredo): quais leituras periodicas da TTLock a V1.0 ainda faz com o callback ligado
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
sed -n 3918,3995p $A/worker.py
echo "=====" ; sed -n 4050,4070p $A/worker.py
echo "===== contingencia.rotina"; grep -n "def rotina" -A30 $A/reservation/contingencia.py | head -40
echo "===== chaves"; sudo -n /opt/esteira-nuvem/com-segredos env | grep -oE '^PMS_(LOCK_RECORDS_SECONDS|ESPELHO_SEGUNDOS|ESPELHO_PORTAS|SENTINELA_SENHAS|VARREDURA_PORTAS|SAIDA_ZERO|FICHA_NA_PORTA|CONTINGENCIA_DATA|REMOTE_OPEN|LUZ_LEITURA|CONTINGENCIA_OFFLINE)=[a-z0-9]{0,10}'
echo "PMS_TTLOCK_CALLBACK_TOKEN definido: $(sudo -n /opt/esteira-nuvem/com-segredos env | grep -c '^PMS_TTLOCK_CALLBACK_TOKEN=')"
echo fim
