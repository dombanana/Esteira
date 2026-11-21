#!/usr/bin/env bash
# SO LEITURA (codigo e configuracao sem segredo): como o worker monta o adaptador TTLock (event_lookup) e os ids das
# fechaduras do Ipiranga (numeros de fechadura nao sao segredo). Nenhuma chamada a TTLock.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -n "make_ttlock_adapter(" -B3 -A25 $A/worker.py | head -60
echo "===== _ttlock_lookup / event_info"; grep -n "def _ttlock_info\|def _event_info\|def ttlock_event\|def _lookup" -A60 $A/worker.py | head -120
echo "===== ipiranga.py LOCKS"; grep -n "^LOCKS\|^COMMON_LOCKS\|^ARMARIOS" -A45 $A/inventory/ipiranga.py | head -120
echo "===== PMS_TTLOCK_LOCKS definido?"; sudo -n /opt/esteira-nuvem/com-segredos env | grep -c '^PMS_TTLOCK_LOCKS=' ; sudo -n /opt/esteira-nuvem/com-segredos env | grep -oE '^PMS_(SENHA_[A-Z0-9_]+|QUARTO_[A-Z_]+|ESPELHO_[A-Z_]+|VARREDURA_[A-Z_]+|SENTINELA_[A-Z_]+|CONTINGENCIA_[A-Z_]+|SAIDA_ZERO|FICHA_NA_PORTA|REMOTE_OPEN|LOCK_RECORDS_SECONDS|DISPATCH_SECONDS|AUTO_CREDENTIALS)=[^ ]{0,30}' | sed -E 's/(TOKEN|SECRET)=.*/\1=***/'
echo fim
