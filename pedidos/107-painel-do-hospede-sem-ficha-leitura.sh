#!/usr/bin/env bash
# SO LEITURA (codigo): o que a pagina do hospede esconde sem ficha (senha, automacao, wi-fi...) e se existe acao do
# anfitriao para dispensar a ficha de uma estadia.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn -i "dispens\|sem_ficha\|ficha_dispensada\|waive\|ficha_ok_anfitriao\|anfitriao_libera" $A --include=*.py | grep -v tests | head -15
echo "== ficha_done"; grep -rn "def ficha_done" -A25 $A/reservation/guest.py | head -35
echo "== onde a pagina usa ficha_done"; grep -rn "ficha_done" $A/panel/guest_service.py | head -20
echo fim
