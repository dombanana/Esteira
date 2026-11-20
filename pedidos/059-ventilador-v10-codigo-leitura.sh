#!/usr/bin/env bash
# 059 -- SO LEITURA (codigo, nao dados): como a V1.0 guarda e le o ventilador dos quartos (tuya_casa/ventilador.py),
# para a sombra da rotina de ventiladores da V1.1 (Dom 20/11 18h03: "rodar em sombra" no fim de semana).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
f=$A/tuya_casa/ventilador.py
wc -l $f
grep -nE "^(def|class|[A-Z_]+ *=)|^    def " $f | head -80
echo "== primeiras 120 linhas"
sed -n 1,120p $f
echo "== quem chama (fora de testes)"
grep -rnE "tuya_casa(\.ventilador| import ventilador)|from app\.tuya_casa\.ventilador" $A --include=*.py | grep -v tests | head -20
echo "== onde o estado do ventilador fica no store"
grep -rnE "vent(ilador)?_(estado|cfg|state)|store\.vent" $A --include=*.py | grep -v tests | head -20
echo "fim"
