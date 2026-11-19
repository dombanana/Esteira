#!/usr/bin/env bash
# 048 -- so leitura: depois da 1.0.278, versao, calendario ligado e quantas caixas o leitor enxerga (sem enderecos/senhas).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 120 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from app.versao import VERSAO
from app.entrada import imap_reservas as I
from app.main import build_state
s = build_state().store
print("versao:", VERSAO, "· calendario:", os.environ.get("PMS_AIRBNB_ICAL"), "· caixas lidas:", len(I.contas(os.environ)), "(2 = a nova tambem)")
d = ((getattr(s, "fontes_saude", {}) or {}).get("airbnb_ical") or {})
d = d if isinstance(d, dict) else getattr(d, "__dict__", {})
x = d.get("dados") or {}
print("calendario:", {k: x.get(k) for k in ("modo", "lidos", "falhas", "reservas_no_airbnb")}, "achados:", len(x.get("achados") or []))
PY
