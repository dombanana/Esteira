#!/usr/bin/env bash
# 049 -- so leitura (codigo, nao dados): onde o painel do hospede controla luz, ventilador e ar, e as regras de horario
# que ja existem (dia da saida 10h30 etc.), para montar a regra "so a partir das 14h no dia da chegada".
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
echo "== arquivos que falam de luz/ventilador/ar no painel do hospede"
grep -rlE "ventilador|luz_da_cama|luz da cama|ar_condicionado|ar-condicionado" $A --include=*.py | grep -v tests | head -30
echo "== rotas do hospede ligadas a aparelhos"
grep -rnE "@.*(post|get)\(.*(/h/|hospede).*(aparelh|luz|vent|ar|tuya|automac)" $A --include=*.py | head -20
echo "== regras de horario existentes (10:30, 14, checkin_hora, dia da saida)"
grep -rnE "10:30|10h30|dia_da_saida|dia da saida|CHECKIN_HORA|checkin_hora|hora_checkin|14:00|\(14, ?0\)|hour *[<>]=? *14" $A --include=*.py | grep -v tests | head -40
