#!/usr/bin/env bash
# SO LEITURA (codigo, nao dados): o leitor do e-mail do Airbnb da V1.0 (app/entrada/airbnb_email.py), a classificacao
# (intents.classificar), as candidatas da reserva (airbnb_reservas.candidatas) e o que fica gravado na linha da entrada
# (chaves da "leitura"), para a V1.1 ler o mesmo e-mail do mesmo jeito (Dom 21/11 "Alta").
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
echo "== airbnb_email.py"; cat $A/entrada/airbnb_email.py
echo "== intents.py: classificar / ota_do_dominio"
for fn in classificar ota_do_dominio; do n=$(grep -nE "^def $fn\(" $A/entrada/intents.py | cut -d: -f1); [ -n "$n" ] && sed -n "${n},$((n+60))p" $A/entrada/intents.py; done
echo "== airbnb_reservas.candidatas"; n=$(grep -nE "^def candidatas\(" $A/entrada/airbnb_reservas.py | cut -d: -f1); sed -n "${n},$((n+12))p" $A/entrada/airbnb_reservas.py
echo "== imap_reservas.para_porta"; n=$(grep -nE "^def para_porta\(" $A/entrada/imap_reservas.py | cut -d: -f1); sed -n "${n},$((n+45))p" $A/entrada/imap_reservas.py
echo "fim"
