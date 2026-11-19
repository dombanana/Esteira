#!/usr/bin/env bash
# 013 -- etapa 1 (saida da Nobeds), so leitura. Para cada reserva NOVA do Airbnb (e-mail, 150 dias) casada com o
# sistema pelo codigo: qual quarto da Nobeds (room_id) recebeu a reserva (get_booking_details, so leitura).
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
from app.channel.adapters import NobedsMcpClient
st = build_state(); s = st.store; agora = datetime.now(timezone.utc)
mcp = NobedsMcpClient.from_environment()
def lista(x):
    if isinstance(x, dict):
        for k in ("data", "result", "rentals", "items"):
            if isinstance(x.get(k), list): return x[k]
        return [x]
    return x if isinstance(x, list) else []
def um(x):
    if isinstance(x, list): x = x[0] if x and isinstance(x[0], dict) else {}
    if isinstance(x, dict):
        for k in ("data", "result", "booking"):
            if isinstance(x.get(k), dict): return x[k]
    return x if isinstance(x, dict) else {}
titulos = {str(r.get("room_id")): str(r.get("title") or "") for r in lista(mcp.call_tool("list_rentals", {})) if isinstance(r, dict)}
def suf(t): return t.rsplit("|", 1)[-1].strip() if "|" in t else "-"
def tipo(t):
    m = re.match(r"\s*(\d+[A-Z]?)\s+(Smart|Hostel)", t, re.I); return f"{m.group(1)} {m.group(2)}" if m else t[:18]
maps = getattr(s, "mappings", {}) or {}
print("quartos na Nobeds:", len(titulos), "· mapeamentos no sistema:", len(maps))
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
    try: b = um(mcp.call_tool("get_booking_details", {"order_id": int(oid)}))
    except Exception as e: falhas["erro " + type(e).__name__] += 1; continue
    rid = str(b.get("room_id") or "")
    if not rid: falhas["sem room_id"] += 1; continue
    mapa[aid][rid] += 1
print("falhas:", dict(falhas))
um_so = [a for a in mapa if len(mapa[a]) == 1]
print(f"anuncios: {len(mapa)} · caem em UM quarto da Nobeds: {len(um_so)} · em mais de um: {len(mapa) - len(um_so)}")
def desc(rid):
    m = maps.get(rid); t = titulos.get(rid, "?")
    return f"{rid} [{tipo(t)} | {suf(t)}] -> {getattr(m, 'space', '?') if m else 'SEM MAPEAMENTO'}/{getattr(m, 'instance', '') if m else ''}{' APOSENTADO' if m is not None and getattr(m, 'aposentado', '') else ''}"
for aid in sorted(mapa, key=lambda a: -sum(mapa[a].values())):
    print(f"anuncio {aid} ({sum(mapa[aid].values())} res.):", " ; ".join(f"{desc(r)} x{n}" for r, n in mapa[aid].most_common()))
# quartos da Nobeds com sufixo AIR que nenhum anuncio visto usa
usados = {r for a in mapa for r in mapa[a]}
sobra = sorted(r for r, t in titulos.items() if suf(t).upper().startswith("AIR") and r not in usados)
print("quartos AIR/AIR-ECO da Nobeds sem anuncio visto:", len(sobra), [f"{r} [{tipo(titulos[r])} | {suf(titulos[r])}]" for r in sobra])
PY
echo fim
