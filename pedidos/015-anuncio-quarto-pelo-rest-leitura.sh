#!/usr/bin/env bash
# 015 -- (013: MCP da Nobeds 401; 014: a fila de entrada nao guarda o quarto) -- agora pela leitura REST da Nobeds (a que o sistema usa e esta ok) etapa 1 (saida da Nobeds), so leitura. Para cada reserva NOVA do Airbnb (e-mail, 150 dias) casada com o
# sistema pelo codigo: qual quarto da Nobeds (room_id) recebeu a reserva -- lido na Nobeds (REST, so leitura, list_bookings por mes).
# Atencao: e o quarto ATUAL da reserva na Nobeds (o painel pode ter trocado depois).
# Pergunta: cada anuncio do Airbnb cai em UM quarto da Nobeds? Se sim, o mapa anuncio -> quarto -> (espaco, versao)
# fica exato e o e-mail pode criar a reserva sozinho. Saida: ids de anuncio e de quarto (da casa) e contagens.
# Nenhum nome, codigo de reserva, valor ou contato.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 840 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
from app.main import build_state
from app.entrada import imap_reservas as I, airbnb_email as A
from app.entrada.intents import classificar, ota_do_dominio, casar
st = build_state(); s = st.store; agora = datetime.now(timezone.utc)
fs = (getattr(s, "fontes_saude", {}) or {})
for k in ("nobeds_mcp", "nobeds", "nobeds_conta", "nobeds_rest"):
    if k in fs:
        v = fs[k]; print(f"saude {k}:", {x: v.get(x) for x in ("estado", "codigo", "desde", "ultimo_ok", "atualizado_em") if isinstance(v, dict) and x in v})
from app.channel.adapters import NobedsReadOnlyClient
from datetime import date
nb = NobedsReadOnlyClient.from_environment()
primeiro, ultimo = {}, {}
d0 = (agora - timedelta(days=200)).date().replace(day=1); fimj = date(agora.year + 1, 12, 31); err = Counter(); n_b = 0
while d0 <= fimj:
    d1 = (d0.replace(day=28) + timedelta(days=4)).replace(day=1) - timedelta(days=1)
    try: bs = nb.list_bookings(d0, d1)
    except Exception as e: err[type(e).__name__] += 1; bs = []
    for bk in bs or []:
        if not isinstance(bk, dict): continue
        n_b += 1; oid, rid = str(bk.get("order_id") or ""), str(bk.get("room_id") or "")
        if oid and rid: primeiro[oid] = rid; ultimo[oid] = rid
    d0 = d1 + timedelta(days=1)
print("REST: reservas lidas", n_b, "· com quarto:", len(primeiro), "· erros:", dict(err))
maps = getattr(s, "mappings", {}) or {}
print("mapeamentos no sistema:", len(maps))
cfg = I.config(os.environ)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
M.select('"INBOX.03_Reservas"', readonly=True)
typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=150)).strftime('%d-%b-%Y')})")
nums = (d[0] or b"").split()
par = {}   # codigo -> anuncio_id
for n in nums:
    t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM)])")
    rem = parseaddr(I._dec(email.message_from_bytes(c[0][1]).get("From")))[1].lower()
    if ota_do_dominio(rem.rsplit("@", 1)[-1]) != "Airbnb": continue
    t, c = M.fetch(n, "(BODY.PEEK[])"); em = I.para_porta(c[0][1])
    cl = classificar(em["dominio"], em["assunto"], em["texto"])
    if (cl.get("tipo") or cl.get("classe")) != "reserva_nova": continue
    try: quando = parsedate_to_datetime(em["quando"])
    except Exception: quando = None
    lt = A.ler(em["assunto"], em["texto"], quando)
    if lt.get("codigo") and lt.get("anuncio_id"): par[lt["codigo"]] = str(lt["anuncio_id"])
M.logout()
print("reservas novas do Airbnb com codigo e anuncio:", len(par))
mapa = defaultdict(Counter); falhas = Counter()
for cod, aid in par.items():
    r = casar(s, cod)
    if r is None: falhas["sem reserva no sistema"] += 1; continue
    oid = str(getattr(r, "external_id", "") or "")
    if not oid.isdigit(): falhas["sem numero da Nobeds"] += 1; continue
    rid = primeiro.get(oid, "")
    if not rid: falhas["sem room_id"] += 1; continue
    mapa[aid][rid] += 1
print("falhas:", dict(falhas))
um_so = [a for a in mapa if len(mapa[a]) == 1]
print(f"anuncios: {len(mapa)} · caem em UM quarto da Nobeds: {len(um_so)} · em mais de um: {len(mapa) - len(um_so)}")
def desc(rid):
    m = maps.get(rid)
    return f"{rid} -> {getattr(m, 'space', '?') if m else 'SEM MAPEAMENTO'}/{getattr(m, 'instance', '') if m else ''}{' APOSENTADO' if m is not None and getattr(m, 'aposentado', '') else ''}"
for aid in sorted(mapa, key=lambda a: -sum(mapa[a].values())):
    print(f"anuncio {aid} ({sum(mapa[aid].values())} res.):", " ; ".join(f"{desc(r)} x{n}" for r, n in mapa[aid].most_common()))
usados = {r for a in mapa for r in mapa[a]}
print("mapeamentos ativos (nao aposentados) sem anuncio visto:", sum(1 for r, m in maps.items() if not getattr(m, "aposentado", "") and r not in usados), "de", sum(1 for m in maps.values() if not getattr(m, "aposentado", "")))
PY
echo fim
