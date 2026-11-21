#!/usr/bin/env bash
exec 2>&1
grep -rn "def climbing" -A12 /opt/PMS-Banana-AI/SISTEMA/api/app --include=*.py | grep -v tests | head -20
grep -n "climbing" /opt/PMS-Banana-AI/SISTEMA/api/app/worker.py | head -3
echo fim
