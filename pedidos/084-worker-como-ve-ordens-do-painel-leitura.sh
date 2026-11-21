#!/usr/bin/env bash
# SO LEITURA: como uma ordem gravada pela API (painel) chega ao worker? servicos e recarga do store
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
systemctl list-units --type=service --no-pager 2>/dev/null | grep -i "pms\|banana\|worker" | head
echo "== automacao_ordens"; grep -rn "automacao_ordens" $A --include=*.py | grep -v tests | grep -v "anfitriao.py" | head -15
echo "== worker loop"; grep -n "def main\|def loop\|def rodar\|while True\|state = \|build_state\|ledger.*novos\|since\|cursor\|apply_new\|follow" $A/worker.py | head -30
echo "== store load"; grep -rn "def build_state" $A --include=*.py | head -3
grep -rn "def catch_up\|def sync\|def poll_ledger\|def refresh\|def reler\|def atualizar_store\|LISTEN\|pg_notify\|notify(" $A/core $A/main.py $A/worker.py 2>/dev/null | head -15
echo fim
