#!/usr/bin/env bash
# SO LEITURA do banco da V1.0 (nenhuma chamada a TTLock): estadias de hoje/amanha e quem esta na casa -- quarto, ficha
# feita?, 4 digitos?, senha emitida (portas feitas/faltando), FNRH, e recusas de senha de hoje (cameras: senha errada).
# Sem nome completo: so a inicial do primeiro nome. Sem senha, sem codigo de reserva.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
from app.main import build_state
from app.core.event import EventState
from app.reservation.intents import OPERATIONAL_INSTANCES
from app.reservation.guest import ficha_done
from app.reservation import access as A
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone); agora = datetime.now(timezone.utc)
hoje = agora.astimezone(tz).date()
print("agora:", agora.astimezone(tz).strftime("%d/%m %H:%M"))
for key, e in sorted(s.events.items(), key=lambda kv: kv[1].when.start):
    if e.instance in OPERATIONAL_INSTANCES or e.state not in (EventState.CONFIRMED, EventState.IN_PROGRESS): continue
    ini, fim = e.when.start.astimezone(tz).date(), e.when.end.astimezone(tz).date()
    if not (ini <= hoje + timedelta(days=1) and fim >= hoje): continue
    p = s.persons.get(e.who.person)
    ini_nome = (str(getattr(p, "name", "") or "?").strip()[:1] or "?") + "."
    fic = ficha_done(s, e)
    dig = f"digitos:{e.who.person}" in s.vault
    cred = {}
    if f"cred:{e.event_id}" in s.vault:
        try: cred = dict(s.vault._read(f"cred:{e.event_id}"))
        except Exception: cred = {}
    portas = [i.split(":")[0] for i in str(cred.get("doors", "")).split(";") if i.count(":") == 2]
    fn = st.outbox.get(f"fnrh:submit:{e.event_id}")
    mot = A._motivos_da_pessoa(s, st.outbox, e, now=agora)
    print(f"{','.join(e.where):6} {ini.strftime('%d/%m')}->{fim.strftime('%d/%m')} {ini_nome:3} {e.state.value:11} ficha={'S' if fic else 'N'} "
          f"digitos={'S' if dig else 'N'} portas={'+'.join(portas) or '-'} completa={cred.get('complete','-')} "
          f"falta={cred.get('missing','') or '-'} fnrh={fn.status.value if fn else '-'} motivos={'; '.join(m.split(': ',1)[-1] for m in mot) or '-'}")
print("== recusas/tentativas de hoje (cameras)")
h0 = datetime.now(tz).replace(hour=0, minute=0, second=0, microsecond=0)
for r in sorted((getattr(s, "cameras_pedidos", {}) or {}).values(), key=lambda r: str(r.get("at"))):
    try: q = datetime.fromisoformat(str(r.get("at")))
    except ValueError: continue
    if q >= h0 and ("errad" in str(r.get("motivo", "")) or "recus" in str(r.get("motivo", "")) or "travad" in str(r.get("motivo", ""))):
        print("  ", q.astimezone(tz).strftime("%H:%M:%S"), r.get("porta"), r.get("espaco"), str(r.get("motivo"))[:60])
PY
echo fim
