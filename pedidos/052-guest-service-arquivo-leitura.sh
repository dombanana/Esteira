#!/usr/bin/env bash
# 052 -- so leitura (codigo): guest_service.py e versao.py inteiros, para montar o patch da 1.0.280 sobre a 1.0.279.
set -u
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "##GS"; base64 -w0 $A/panel/guest_service.py; echo
echo "##VS"; base64 -w0 $A/versao.py; echo
echo "##SVC"; grep -nE "^def _now|^SAO_PAULO|^TZ|ZoneInfo" $A/panel/service.py | head
echo "##RES"; grep -nE "^def resolve|^from app.panel.access|resolve" $A/panel/guest_service.py | head -5
