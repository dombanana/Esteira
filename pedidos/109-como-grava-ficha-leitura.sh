#!/usr/bin/env bash
set -u; exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn "prechecks\[\|prechecks.setdefault\|persons\[.*\] *=" $A --include=*.py | grep -v tests | head -12
grep -rn "def enqueue" -A12 $A --include=*.py | head -30
grep -rn "class ChannelStore" -A30 $A --include=*.py | grep -n "def \|class " | head -30
grep -rn "def record_precheck\|def save_precheck\|def _persist\|def apply_change\|def commit" $A --include=*.py | head
echo fim
