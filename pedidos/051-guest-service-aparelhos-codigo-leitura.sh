#!/usr/bin/env bash
# 051 -- so leitura (codigo): funcoes de luz/ventilador/ar do painel do hospede e o arquivo inteiro em base64 (para o patch).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
F=$A/panel/guest_service.py
wc -l $F; sha256sum $F
grep -nE "^def my_light|^def ventilador_quarto|^def ar_quarto|^def light_alarm|^def _event_for|^def _stay|^def _guest_event|^def _resolve|^class PanelError|^SAO_PAULO|^from|^import" $F | head -60
echo "-----"
N=$(grep -n "^def my_light" $F | cut -d: -f1); sed -n "$((N-5)),$((N+45))p" $F
echo "-----"
sed -n 700,800p $F
echo "== testes de luz/ar/ventilador do hospede"
grep -rlE "my_light|ventilador_quarto|ar_quarto" $A --include=test_*.py | head
