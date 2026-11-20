#!/usr/bin/env bash
# 058 -- SO LEITURA (estudo "Operacao Airbnb", Dom 20/11 05h03): mapa room_id da Nobeds -> espaco/versao e
# ocupacao agregada por noite, a partir das reservas do sistema (soberano).
# Nenhum nome, codigo de reserva, valor ou contato: so ids de quarto, espacos e contagens por data.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 600 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import dataclasses
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from app.main import build_state
st = build_state(); s = st.store
maps = getattr(s, "mappings", {}) or {}
print("== MAPA room_id;espaco;instancia;por_pessoa;aposentado ==")
for k, m in sorted(maps.items(), key=lambda kv: str(kv[0])):
    print(f"{getattr(m,'room_id',k)};{getattr(m,'space','')};{getattr(m,'instance','')};{int(bool(getattr(m,'per_person',False)))};{getattr(m,'aposentado','')}")
rs = list((getattr(s, "reservations", {}) or {}).values())
print("== RESERVAS no sistema:", len(rs))
if rs:
    r0 = rs[0]
    campos = [f.name for f in dataclasses.fields(r0)] if dataclasses.is_dataclass(r0) else sorted(vars(r0).keys())
    print("campos:", ",".join(campos))
def pega(r, *nomes):
    for n in nomes:
        v = getattr(r, n, None)
        if v not in (None, ""): return v
    return None
def dia(v):
    if isinstance(v, datetime): return v.date()
    if isinstance(v, date): return v
    try: return date.fromisoformat(str(v)[:10])
    except Exception: return None
st_c = Counter(); noites = defaultdict(Counter); canal = Counter(); antecedencia = []
hoje = date.today()
for r in rs:
    stt = str(pega(r, "status") or "").split(".")[-1].lower(); st_c[stt] += 1
    if "cancel" in stt or "no_show" in stt: continue
    ci, co = dia(pega(r, "check_in", "checkin", "arrival", "start", "inicio")), dia(pega(r, "check_out", "checkout", "departure", "end", "fim"))
    if not ci or not co: continue
    esp = str(pega(r, "space", "espaco", "unit", "room") or "?")
    canal[str(pega(r, "channel", "canal", "source", "origem") or "?")] += 1
    cr = dia(pega(r, "created_at", "criada_em", "created", "booked_at"))
    if cr: antecedencia.append((ci - cr).days)
    d = ci
    while d < co:
        if hoje - timedelta(days=120) <= d <= hoje + timedelta(days=180): noites[d][esp] += 1
        d += timedelta(days=1)
print("status:", dict(st_c)); print("canal:", dict(canal))
if antecedencia:
    a = sorted(antecedencia); n = len(a)
    print("antecedencia (dias) p25/mediana/p75:", a[n//4], a[n//2], a[3*n//4], "· ate 1 dia:", sum(1 for x in a if x <= 1), "de", n)
print("== NOITE;unidades_ocupadas;espacos ==")
for d in sorted(noites):
    c = noites[d]
    print(f"{d};{sum(c.values())};{'|'.join(f'{k}:{v}' for k, v in sorted(c.items()))}")
PY
echo "fim"
