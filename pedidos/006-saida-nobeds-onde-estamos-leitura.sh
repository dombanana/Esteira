#!/usr/bin/env bash
# 006 -- etapa 1 do cronograma (saida da Nobeds): onde estamos. Versao no ar; a caixa IMAP esta ligada?; prontidao da
# reserva-sombra (14 dias); reservas da Nobeds x leituras do e-mail. Nenhum nome, codigo ou valor e mostrado.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao no ar: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
echo "--- diario (24 h): imap / entrada.email / RES-09"
for p in 'imap' 'entrada.email' 'RES-09' 'nobeds'; do echo "   $p: $(journalctl -u pms-banana-ai-worker -u pms-banana-ai --since '24 hours ago' --no-pager -o cat 2>/dev/null | grep -ci "$p")"; done
journalctl -u pms-banana-ai-worker --since '24 hours ago' --no-pager -o short-iso 2>/dev/null | grep -i 'imap' | tail -4 | cut -c1-170
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from collections import Counter
from datetime import datetime, timedelta, timezone
from app.main import build_state
from app.entrada import imap_reservas as I
st = build_state(); s = st.store; agora = datetime.now(timezone.utc)
cfg = I.config(os.environ)
print("caixa IMAP configurada:", "sim" if cfg else "NAO", "| pastas:", (cfg or {}).get("pastas"))
ent = getattr(s, "entradas", {}) or {}
print("entradas gravadas:", len(ent), "| por fonte:", dict(Counter(str(r.get("fonte") or r.get("canal") or "?") for r in ent.values())))
rec = [r for r in ent.values() if str(r.get("quando") or r.get("at") or "") >= (agora - timedelta(days=3)).isoformat()[:10]]
print("entradas dos ultimos 3 dias:", len(rec), dict(Counter(str(r.get("tipo") or r.get("classe") or "?") for r in rec)))
try:
    from app.entrada.airbnb_email import prontidao
    p = prontidao(s, agora)
    print("prontidao:", {k: (v if not isinstance(v, (list, dict)) else (len(v) if isinstance(v, list) else {kk: vv for kk, vv in v.items() if not isinstance(vv, (list, dict))})) for k, v in p.items()})
except Exception as ex:
    print("prontidao: erro", type(ex).__name__, str(ex)[:120])
res = getattr(s, "reservations", {}) or {}
fut = [r for r in res.values() if str(getattr(r, "status", getattr(r, "state", ""))).lower().find("cancel") < 0]
print("reservas no sistema:", len(res), "| por canal:", dict(Counter(str(getattr(r, "channel", getattr(r, "canal", "?"))) for r in res.values())))
PY
echo "fim"
