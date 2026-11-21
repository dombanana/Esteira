#!/usr/bin/env bash
set -u; exec 2>&1
P=/opt/PMS-Banana-AI/SISTEMA/api/app/record/persistence.py
grep -n "def \|precheck\|INSERT INTO.*person\|document_ref" $P | grep -in "precheck\|person\|def save\|def persist\|def sync\|def flush\|document_ref" | head -40
sed -n 700,725p $P
grep -n "class OutboxCommand" -A14 /opt/PMS-Banana-AI/SISTEMA/api/app/core/outbox.py
grep -rn "senha:email:" /opt/PMS-Banana-AI/SISTEMA/api/app --include=*.py | grep -v tests | head -5
echo fim
