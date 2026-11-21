#!/usr/bin/env bash
# SO LEITURA (codigo): as constantes da classificacao do e-mail (TIPOS, NAO_CANCELADA, CODIGOS, OTA_DOMINIOS) e o
# _texto da caixa IMAP da V1.0, para a V1.1 classificar igual (Dom 21/11 "Alta").
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app/entrada
for c in TIPOS NAO_CANCELADA CODIGOS CODIGO_GERAL OTA_DOMINIOS; do n=$(grep -nE "^$c\b" $A/intents.py | head -1 | cut -d: -f1); echo "== $c (linha $n)"; [ -n "$n" ] && sed -n "${n},$((n+22))p" $A/intents.py; done
n=$(grep -nE "^def _texto\(" $A/imap_reservas.py | cut -d: -f1); echo "== _texto"; sed -n "${n},$((n+30))p" $A/imap_reservas.py
echo "fim"
