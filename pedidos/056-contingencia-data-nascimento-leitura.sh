#!/usr/bin/env bash
# 056 -- SO LEITURA: a abertura da porta pela data de nascimento (contingencia) esta ligada? Onde o texto aparece para o hospede?
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "versao no ar: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env ../.venv/bin/python - <<'PY'
import os
for k in ("PMS_CONTINGENCIA_DATA","PMS_REMOTE_OPEN"):
    print(k, "=", repr(os.environ.get(k)))
PY
echo "== onde o codigo liga a contingencia =="
grep -rn "PMS_CONTINGENCIA_DATA" $A --include=*.py | grep -v /tests/ | head
echo "== textos ao hospede que citam data de nascimento na porta (fora de tests) =="
grep -rlni "data de nascimento" $A --include=*.py --include=*.json --include=*.html --include=*.md | grep -v /tests/ | head -30
grep -rni "nascimento abre\|DDMMAA\|porta sem celular" $A --include=*.py --include=*.json --include=*.html | grep -v /tests/ | cut -c1-200 | head -20
echo "== aberturas pela contingencia registradas (contagem) =="
grep -rli "contingencia" /opt/PMS-Banana-AI/SISTEMA/api/data 2>/dev/null | head -5
