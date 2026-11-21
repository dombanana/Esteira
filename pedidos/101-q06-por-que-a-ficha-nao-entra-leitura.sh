#!/usr/bin/env bash
# SO LEITURA: por que a ficha da estadia do Q06 (chega hoje 21/11) nao entra -- logs da API das ultimas 6 h filtrados
# (so rota, codigo HTTP e tipo de erro; sem corpo, sem nome, sem documento) e o que o banco tem dessa estadia.
set -u
exec 2>&1
journalctl -u pms-banana-ai --since "-6h" --no-pager -q 2>/dev/null | grep -iE "ficha|precheck|cadastro|/h/|/e/|guest|hospede|422|400 |500 |Traceback|Error" \
  | sed -E 's/[0-9]{3}\.[0-9]{3}\.[0-9]{3}-?[0-9]{2}/<cpf>/g; s/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<email>/g; s/\b[0-9a-f]{20,}\b/<id>/g; s/(token|t)=[^& ]+/\1=<x>/g' | tail -60
echo "== banco"
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from app.main import build_state
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone)
alvo = [ (k, e) for k, e in s.events.items() if "Q06" in e.where and e.when.start.astimezone(tz).date().isoformat() == "2026-11-21"]
for k, e in alvo:
    print("estadia:", e.state.value, e.instance, "chave termina em", str(k)[-4:])
    pid = e.who.person
    # o que o diario tem desta pessoa/estadia hoje (so tipo e hora)
    n = 0
    for rec in list(st.ledger)[-4000:]:
        d = getattr(rec, "entity_id", "") or ""
        if pid in str(d) or e.event_id in str(d):
            n += 1
            print("  ", str(getattr(rec, "at", ""))[:19], getattr(rec, "entity", ""), getattr(rec, "action", getattr(rec, "kind", "")))
    print("  registros no diario (ultimos 4000):", n)
    for c in st.outbox:
        if e.event_id in c.idempotency_key or pid in str(c.payload.get("person_ref", "")):
            print("  fila:", c.idempotency_key.split(":")[0:2], c.command_type, c.status.value, str(c.last_error or "")[:80])
PY
echo fim
