#!/usr/bin/env bash
# SO LEITURA (codigo): anfitriao.py linhas 199-420 (regra, planejar, _enviar, vigiar) e como o painel chama automacao.mandar.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
sed -n 199,420p $A/tuya_casa/anfitriao.py
echo "== quem chama automacao.mandar"; grep -rn "automacao.mandar\|automacao_mandar" $A --include=*.py | grep -v tests | head
echo "== aparelhos/invertidos"; n=$(grep -nE "^def aparelhos\(" $A/tuya_casa/ventilador.py | cut -d: -f1); sed -n "${n},$((n+36))p" $A/tuya_casa/ventilador.py
echo fim
