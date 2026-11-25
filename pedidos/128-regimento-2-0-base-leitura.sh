#!/usr/bin/env bash
# 128 -- so leitura: base para o regimento 2.0 no sistema (versao no ar, fila, arquivos do regimento, testes que citam o texto, regras do Economico).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
G="git -c safe.directory=* -C /opt/pms-banana-ai-fila.git"
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' $A/versao.py)"
echo "instalado HEAD: $(git -c safe.directory=* -C /opt/PMS-Banana-AI rev-parse --short HEAD 2>&1)"
echo "== fila main"; $G log --format='%h %ci %s' -5 main 2>&1 | cut -c1-160
echo "== ramos"; $G for-each-ref --sort=-committerdate --format='%(refname:short) %(objectname:short) %(committerdate:iso) %(subject)' refs/heads refs/tags 2>&1 | head -15 | cut -c1-180
echo "== diff instalado x main"; $G diff --stat $(git -c safe.directory=* -C /opt/PMS-Banana-AI rev-parse HEAD) main 2>&1 | tail -3
echo "== arquivos regimento"; ls -la $A/reservation/ | grep -i regim
grep -rln -i "regimento" $A --include=*.py | grep -v __pycache__ | head -60
echo "== testes que citam texto do regimento"; grep -rn -iE "pousada|hostel|House Pass|lojinha|animais|VERSAO|1\.8|1\.9" $A --include=test_*.py | grep -i -E "regim" | head -60 | cut -c1-220
echo "=== FILE regimento.py"; cat $A/reservation/regimento.py
echo "=== FILE regimento_textos.py (cabeca e tamanho)"; wc -c $A/reservation/regimento_textos.py; head -c 6000 $A/reservation/regimento_textos.py
echo; echo "=== estrutura textos"; grep -n -E '^[A-Z_]+ *=|^    "[a-z]{2}":' $A/reservation/regimento_textos.py | head -30
echo "=== quem usa regimento"; grep -rn -E "regimento\.(TEXTO|VERSAO|pagina|texto)|from .*regimento import|import regimento" $A --include=*.py | grep -v __pycache__ | head -40 | cut -c1-200
echo "=== Economico (18h, 10h, micro, quintal)"; grep -rn -iE "econ[oô]mico|economico" $A --include=*.py | grep -v -E "/tests/|__pycache__" | grep -iE "18|10|micro|quintal|cozinha|hor|area|smart" | head -60 | cut -c1-230
