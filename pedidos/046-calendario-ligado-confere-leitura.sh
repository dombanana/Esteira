#!/usr/bin/env bash
# 046 -- so leitura: depois do ic3, o worker esta com o calendario ligado e a ultima saude dele (sem codigos de reserva).
set -u
exec 2>&1
sleep 120
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 120 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from app.main import build_state
s = build_state().store
print("PMS_AIRBNB_ICAL (secrets) =", os.environ.get("PMS_AIRBNB_ICAL"))
fs = getattr(s, "fontes_saude", {}) or {}
for k, v in fs.items():
    if "ical" in str(k) or "imap" in str(k):
        v = v if isinstance(v, dict) else getattr(v, "__dict__", {})
        d = v.get("dados") or {}
        print(k, {x: v.get(x) for x in ("ok", "desde", "visto_em", "atualizado_em", "codigo") if x in v},
              {x: d.get(x) for x in ("modo", "anuncios", "lidos", "falhas", "reservas_no_airbnb")}, "achados:", len(d.get("achados") or []))
al = [a for a in (getattr(s, "host_alerts", {}) or {}) if str(a).startswith("airbnb-ical")]
print("alarmes do calendario:", len(al))
PY
