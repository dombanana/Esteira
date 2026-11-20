#!/usr/bin/env bash
# 061 (060 com nome errado, nunca rodou) -- SO LEITURA (codigo, nao dados): o resto do tuya_casa/ventilador.py da V1.0 -- vel_real, estado_real,
# fora_do_ar, hospede_do_quarto, view, vigiar -- para montar a sombra do fim de semana (V1.1, Dom 20/11 18h03).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
f=$A/tuya_casa/ventilador.py
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
grep -nE "^def |^    def " $f
echo "== linhas 130-366"
sed -n 130,366p $f
echo "== worker: como o vigiar e chamado"
sed -n 4010,4035p $A/worker.py
echo "fim"
