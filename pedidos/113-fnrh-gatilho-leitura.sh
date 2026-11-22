#!/usr/bin/env bash
set -u; exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -n "VERSAO = " $A/versao.py
grep -rln "fnrh" $A --include=*.py -i | grep -v tests | head -20
grep -rn "idempotency_key=f\"fnrh\|idempotency_key=f'fnrh\|\"fnrh:\|f\"fnrh:" $A --include=*.py | grep -v tests | head -8
echo fim
