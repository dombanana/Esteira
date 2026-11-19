#!/usr/bin/env bash
# 050 -- so leitura (codigo): as rotas /luz /ventilador /ar do painel do hospede e os testes que as usam.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
sed -n 1,40p $A/panel/routes.py | grep -nE "^(from|import)|SAO_PAULO|def _now|datetime"
echo "-----"
sed -n 855,935p $A/panel/routes.py
echo "== testes que chamam essas rotas"
grep -rlnE "/luz\"|/ventilador\"|/ar\"|/luz'|/ventilador'|/ar'" $A --include=test_*.py | head
grep -rnE "def (aparelho|luz|ventilador|ar)_|def _guest_device|def hospede_(luz|ventilador|ar)" $A/panel/*.py | head
echo "== hospede.html: chamadas"
grep -nE "'/luz'|/ventilador|/ar'|\+ *'/ar|api\(.*(luz|ventilador|ar)" $A/panel/static/hospede.html | head -20
