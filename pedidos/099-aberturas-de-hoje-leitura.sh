#!/usr/bin/env bash
# SO LEITURA do banco da V1.0 (nenhuma chamada a TTLock): as aberturas de hoje ja guardadas (registro da entrada,
# pedidos das cameras), com porta, hora, tipo e o QUARTO da estadia -- sem nome, sem senha, sem codigo de reserva.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import hashlib, json
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
from app.main import build_state
from app import worker as W
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone)
hoje0 = datetime.now(tz).replace(hour=0, minute=0, second=0, microsecond=0)
locks = W.house_locks(st)
nome_lock = {str(v): k for k, v in locks.common.items()}
nome_lock.update({str(v): k for k, v in locks.rooms.items()})
nome_lock.update({str(v): "ARM_" + k for k, v in locks.armarios.items()})
quarto = {e.event_id: ",".join(e.where) for e in s.events.values()}
print("atributos com abertura/camera/entry:", [a for a in dir(s) if any(x in a for x in ("abert", "camera", "entry", "opening", "foto"))])
SEG = ("at", "when", "quando", "lock_date", "lockDate", "tipo", "kind", "classe", "via", "door", "porta", "lock", "lock_id",
       "space", "quarto", "ok", "success", "dono", "origem", "rotulo", "status")
def linha(r):
    d = r if isinstance(r, dict) else getattr(r, "__dict__", {}) or {}
    out = {k: d.get(k) for k in SEG if k in d}
    for k in ("event_id", "evento"):
        if d.get(k):
            out["quarto_estadia"] = quarto.get(d[k], "?")
    for k in ("lock_id", "lock", "door", "porta"):
        if str(d.get(k)) in nome_lock:
            out["porta_nome"] = nome_lock[str(d.get(k))]
    return out
def quando(r):
    d = r if isinstance(r, dict) else getattr(r, "__dict__", {}) or {}
    for k in ("at", "when", "quando", "lock_date", "lockDate"):
        v = d.get(k)
        if v is None: continue
        try:
            if isinstance(v, (int, float)): return datetime.fromtimestamp(v / 1000, timezone.utc)
            return datetime.fromisoformat(str(v))
        except ValueError: pass
    return None
for nome in [a for a in dir(s) if any(x in a for x in ("abert", "camera", "entry"))]:
    col = getattr(s, nome, None)
    if not isinstance(col, dict): continue
    itens = list(col.values())
    if itens:
        primeiro = itens[0] if isinstance(itens[0], dict) else getattr(itens[0], "__dict__", {})
        print(f"== {nome}: {len(itens)} itens; campos: {sorted(primeiro.keys())[:25]}")
    hoje = [(quando(r), r) for r in itens if quando(r) and quando(r) >= hoje0]
    hoje.sort(key=lambda x: x[0])
    print(f"   hoje: {len(hoje)}; ultimos 15:")
    for q, r in hoje[-15:]:
        print("  ", q.astimezone(tz).strftime("%H:%M:%S"), json.dumps(linha(r), default=str, ensure_ascii=False))
PY
echo fim
