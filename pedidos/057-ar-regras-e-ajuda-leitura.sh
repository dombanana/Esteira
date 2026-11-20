#!/usr/bin/env bash
# 057 -- SO LEITURA: textos atuais do ar-condicionado no painel (para a placa A4 do ar) e se /ajuda/ar abre.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
echo "== /ajuda/ar =="
for u in https://www.dombanana.tech/ajuda/ar https://painel.dombanana.tech/ajuda/ar; do echo "$u -> $(curl -s -L -o /tmp/ajuda_ar.html -w '%{http_code}' $u) $(grep -o '<title>[^<]*' /tmp/ajuda_ar.html | head -1)"; done
grep -o '<h[123][^>]*>[^<]*' /tmp/ajuda_ar.html | head -12
echo "== frases do ar no painel (pt) =="
grep -rhn "janela\|24 *°\|22 *°\|30 min\|liga sozinho\|Ligar o ar" $A/panel/*.py $A/tuya_casa/*.py 2>/dev/null | grep -iv "^\s*#" | grep -i "ar\b\|ar \|janela" | cut -c1-230 | head -40
echo "== regra (constantes) =="
grep -rn "TRAVA\|_MIN\b\|LIGA_SOZINHO\|AR_MIN\|AR_MAX" $A/tuya_casa/*.py 2>/dev/null | grep -v tests | cut -c1-200 | head -20
