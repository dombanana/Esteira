#!/usr/bin/env bash
# SO LEITURA: inicio do laco do worker (recarga do store a cada volta?) e vigia dos ventiladores
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
sed -n 3333,3470p $A/worker.py
echo "== persistence no worker"; grep -n "persistence\|load_store\|recarregar_store\|reload_from\|_recarregar\|mtime\|data_version" $A/worker.py | head -20
echo "== persistence defs"; grep -n "^def \|^    def " $A/record/persistence.py | head -40
echo fim
