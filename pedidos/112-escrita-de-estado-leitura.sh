#!/usr/bin/env bash
set -u; exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
P=$A/record/persistence.py
grep -n "    def all\b\|    def all(\|    def items(\|    def put\|    def upsert\|    def write\|^class \|def apply_changes\|def _apply\|INSERT INTO record_state\|INSERT INTO state" $P | head -30
n=$(grep -n "    def items(" $P | head -1 | cut -d: -f1); [ -n "$n" ] && sed -n "$((n-40)),$((n+12))p" $P
grep -rn "def handle_intent\|def run_intent\|def execute_intent\|def dispatch_intent\|def invoke\b\|def call_intent" $A --include=*.py | grep -v tests | head -6
sed -n 1790,1820p $A/reservation/intents.py
echo fim
