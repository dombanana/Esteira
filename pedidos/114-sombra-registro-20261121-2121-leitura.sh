#!/usr/bin/env bash
# SO LEITURA -- sombra do Registro de pessoas (V1.1). Compara, estadia a estadia, o que a V1.0 decidiu (ficha, 4
# digitos, menor, FNRH) com o que o Registro 1.1.0 decidiria. Nenhum dado pessoal sai: so sim/nao e estados.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import hashlib
from collections import Counter
from datetime import datetime, timedelta, timezone
from app.main import build_state
from app.core.event import EventState
from app.reservation.guest import ficha_done, ficha_feita_aqui
from app.reservation.intents import OPERATIONAL_INSTANCES, bloqueio_de_menor
st = build_state(); s = st.store; ob = st.outbox; agora = datetime.now(timezone.utc)
H = lambda x: hashlib.sha256(("registro|" + str(x)).encode()).hexdigest()[:10]
c = Counter(); dif = []
for key, e in list(s.events.items()):
    if e.instance in OPERATIONAL_INSTANCES or e.state not in (EventState.CONFIRMED, EventState.IN_PROGRESS):
        continue
    if e.when.end < agora - timedelta(days=1) or e.when.start > agora + timedelta(days=8):
        continue
    inst = s.inventory.instance(e.instance)
    exige = bool(inst and inst.fnrh_required)
    row = (getattr(s, "prechecks", {}) or {}).get(e.event_id) or {}
    disp = str(row.get("ficha_ref") or "") == "dispensada-pelo-anfitriao" or row.get("state") == "dispensada"
    fd = ficha_done(s, e)
    mb = bloqueio_de_menor(s, e.event_id) or {}
    dig = f"digitos:{e.who.person}" in s.vault or f"pin:{e.event_id}" in s.vault
    cmd = ob.get(f"fnrh:submit:{e.event_id}")
    f10 = getattr(cmd.status, "value", str(cmd.status)) if cmd is not None else "-"
    # o que o Registro 1.1.0 decide
    est11 = "dispensada" if disp else ("feita" if fd else ("barrada" if mb and not mb.get("senha") else "aberta"))
    portas11 = est11 in ("feita", "dispensada") and dig
    portas10 = (fd or disp) and dig
    fnrh11 = exige and est11 == "feita"
    fnrh10 = f10 != "-"
    h = H(e.event_id); c["estadias"] += 1; c[f"ficha {est11}"] += 1
    print(f"EST;{h};{e.where[0] if e.where else '?'};{e.when.start.date()};{e.when.end.date()};v11={est11};"
          f"4dig={'s' if dig else 'n'};portas10={'s' if portas10 else 'n'};portas11={'s' if portas11 else 'n'};"
          f"fnrh10={f10};fnrh11={'vai' if fnrh11 else 'nao'}")
    if portas10 != portas11:
        dif.append(f"{h} portas: V1.0={'libera' if portas10 else 'segura'} V1.1={'libera' if portas11 else 'segura'}")
    if fnrh10 != fnrh11 and not (fnrh11 and not fnrh10 and f10 == "-"):
        dif.append(f"{h} FNRH: V1.0={f10} V1.1={'enviaria' if fnrh11 else 'nunca envia'}"
                   + (" (FICHA DISPENSADA: a V1.0 tentou mandar sem documento)" if disp and fnrh10 else ""))
    elif fnrh11 and not fnrh10:
        c["fnrh ainda na fila da V1.0"] += 1
print("== RESUMO:", dict(c))
print(f"== DIFERENCAS ({len(dif)}):"); [print("   " + x) for x in dif]
PY
