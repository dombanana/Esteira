#!/usr/bin/env bash
# 044 -- so leitura: codigo (nao dados) do leitor IMAP instalado e do teste dele, para montar a 1.0.278 (duas caixas).
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
sha256sum $A/entrada/imap_reservas.py $A/versao.py
echo "--- test_v1243"; cat $A/entrada/tests/test_v1243_imap_reservas.py
echo "--- worker: chamada"; grep -n "imap_reservas" $A/worker.py
echo "--- versao.py"; head -30 $A/versao.py
