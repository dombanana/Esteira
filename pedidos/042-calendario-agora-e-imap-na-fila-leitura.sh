#!/usr/bin/env bash
# 042 -- so leitura: roda a comparacao do calendario do Airbnb AGORA (sem gravar nada) e mostra os achados SEM codigo de
# reserva (so tipo, unidade e datas). E mostra a saude registrada das fontes (airbnb_ical, imap).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os, collections
from datetime import datetime, timezone
from app.main import build_state
from app.entrada import airbnb_ical as C
from app.entrada.anuncios_airbnb import TABELA
st = build_state(); s = st.store; agora = datetime.now(timezone.utc)
lks = C.links(os.environ); feeds, falhas = {}, 0
for a, l in sorted(lks.items()):
    try: feeds[a] = C.ler_ics(C.baixar(l))
    except Exception: falhas += 1
todos = falhas == 0 and len(feeds) >= len(TABELA)
ach = C.comparar(s, feeds, todos_ok=todos, agora=agora)
print(f"modo={C.modo(os.environ)} · links={len(lks)} · lidos={len(feeds)} · falhas={falhas} · reservas futuras no Airbnb={len({e['codigo'] for v in feeds.values() for e in v if e['checkout']>=agora.date()})}")
print("achados:", dict(collections.Counter(a['tipo'] for a in ach)))
for a in ach:
    un = TABELA.get(a.get("anuncio_id"), ("?",))[0] if a.get("anuncio_id") else "-"
    print(f"   {a['tipo']:<15} unidade={un:<5} {a.get('checkin', (a.get('de') or ['?'])[0])} -> {a.get('checkout', (a.get('para') or ['?','?'])[1])}"
          + (f" (casa {a['de']} / airbnb {a['para']})" if a['tipo']=='datas' else "") + (" · ja tem cancelamento aqui" if a['tipo']=='cancelada_aqui' else ""))
for nome in ("airbnb_ical", "imap_reservas", "reservas_imap", "entrada_imap"):
    for attr in ("saude", "saudes", "fontes", "health"):
        d = getattr(s, attr, None)
        if isinstance(d, dict) and nome in d:
            v = d[nome]; v = v if isinstance(v, dict) else getattr(v, "__dict__", v)
            print("saude", nome, {k: v[k] for k in list(v)[:8] if k not in ("dados",)} if isinstance(v, dict) else v)
print("atributos do store com 'saud':", [k for k in vars(s) if 'saud' in k.lower()] if hasattr(s, '__dict__') else '?')
PY
