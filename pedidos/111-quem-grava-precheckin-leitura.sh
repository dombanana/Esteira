#!/usr/bin/env bash
set -u; exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn '"precheckin"' $A --include=*.py | grep -v tests | head -8
grep -rn '"person", \|kind="person"\|("person",' $A --include=*.py | grep -v tests | head -5
f=$(grep -rln '"precheckin"' $A --include=*.py | grep -v tests | grep -v persistence | head -1); echo "== $f"
n=$(grep -n '"precheckin"' $f | head -1 | cut -d: -f1); sed -n "$((n-25)),$((n+8))p" $f
grep -n "senha:email:" -B3 -A10 $A/reservation/senha_copias.py | sed -n 1,5p
grep -rn 'idempotency_key=f"senha:email' $A --include=*.py | grep -v tests | head -3
echo fim
