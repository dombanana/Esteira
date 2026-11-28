#!/usr/bin/env bash
# SO LEITURA -- estadias da V1.0 que valem de hoje em diante (unidade e datas), para a 2.0 receber como bloqueio.
# Sem nome, sem codigo de reserva, sem senha: so um resumo de 10 letras por estadia.
set -u; exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import hashlib
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from app.main import build_state
from app.reservation.intents import OPERATIONAL_INSTANCES
from app.core.event import EventState
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone); agora = datetime.now(timezone.utc)
H = lambda x: hashlib.sha256(("v20|" + str(x)).encode()).hexdigest()[:10]
n = 0
for key, e in sorted(s.events.items(), key=lambda kv: kv[1].when.start):
    if e.instance in OPERATIONAL_INSTANCES or e.state not in (EventState.CONFIRMED, EventState.IN_PROGRESS):
        continue
    if e.when.end < agora:
        continue
    sp = ",".join(e.where)
    print(f"EST;{H(key)};{sp};{e.when.start.astimezone(tz).date()};{e.when.end.astimezone(tz).date()};{e.instance};{e.state.name}")
    n += 1
print(f"TOTAL;{n}")
PY
