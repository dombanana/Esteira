#!/usr/bin/env bash
# SO LEITURA (codigo): o que faz a ficha contar como feita, e acoes do anfitriao sobre ficha
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -n "def ficha_feita_aqui" -A25 $A/reservation/guest.py
grep -rn 'name="reservation\.[a-z_]*ficha[a-z_]*"\|name="reservation\.[a-z_]*presencial[a-z_]*"\|name="panel\.[a-z_]*ficha[a-z_]*"' $A --include=*.py | head
grep -rn "ficha_done\b" $A --include=*.py | grep -v tests | grep -v "def ficha_done" | awk -F: '{print $1}' | sort | uniq -c
cat $A/versao.py | head -5
echo fim
