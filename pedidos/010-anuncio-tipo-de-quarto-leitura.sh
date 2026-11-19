#!/usr/bin/env bash
# 010 -- (= 009, 60 dias) os anuncios 'ambiguos' apontam para um tipo de quarto so? (sala/grupo da Nobeds). etapa 1 (saida da Nobeds), so leitura. Depois do nb1 (caixa ligada): (1) a caixa abre? quantos e-mails de OTA nos
# ultimos 3 dias; (2) os e-mails de reserva do Airbnb dos ultimos 150 dias, lidos pelo leitor da 244 e casados com as
# reservas do sistema pelo codigo: quanto le completo, quanto casa, quantos anuncios dariam mapa certo; (3) das reservas
# futuras do sistema, quantas tem o e-mail do Airbnb. So contagens: nenhum nome, codigo, valor ou endereco.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 600 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
from app.main import build_state
from app.entrada import imap_reservas as I, airbnb_email as A
from app.entrada.intents import classificar, ota_do_dominio, casar
st = build_state(); s = st.store; agora = datetime.now(timezone.utc); hoje = agora.date()
cfg = I.config(os.environ)
print("caixa configurada:", "sim" if cfg else "NAO")
ent = getattr(s, "entradas", {}) or {}
print("chaves de uma linha de entrada:", sorted(next(iter(ent.values())).keys()) if ent else "-")
print("linhas de entrada nas ultimas 24 h:", sum(1 for r in ent.values() if str(r.get("recebido_em") or "") >= (agora - timedelta(days=1)).isoformat()))
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
def busca(pasta, dias):
    typ, _ = M.select(f'"{pasta}"', readonly=True)
    if typ != "OK": return []
    typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=dias)).strftime('%d-%b-%Y')})")
    return (d[0] or b"").split() if typ == "OK" else []
for pasta in ["INBOX.03_Reservas"]:
    nums = busca(pasta, 3); ota = Counter()
    for n in nums:
        t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM)])")
        rem = parseaddr(I._dec(email.message_from_bytes(c[0][1]).get("From")))[1].lower()
        o = ota_do_dominio(rem.rsplit("@", 1)[-1]); ota[o or "outro"] += 1
    print(f"pasta {pasta}: {len(nums)} e-mail(s) nos ultimos 3 dias, por origem: {dict(ota)}")
# 150 dias de Airbnb em 03_Reservas
nums = busca("INBOX.03_Reservas", 90)
CAMPOS = [k for k in ('room_id', 'nobeds_room_id', 'mapping_id', 'unit_type', 'room_type', 'instance', 'listing_instance') if hasattr(next(iter(s.reservations.values())), k)]
tipos = defaultdict(Counter)
print('atributos da reserva:', sorted(k for k in vars(next(iter(s.reservations.values()))).keys()))
classes = Counter(); leit = Counter(); casa = Counter(); mapa = defaultdict(Counter); por_codigo = {}
for n in nums:
    t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)])")
    h = email.message_from_bytes(c[0][1]); rem = parseaddr(I._dec(h.get("From")))[1].lower()
    if ota_do_dominio(rem.rsplit("@", 1)[-1]) != "Airbnb": continue
    t, c = M.fetch(n, "(BODY.PEEK[])"); em = I.para_porta(c[0][1])
    cl = classificar(em["dominio"], em["assunto"], em["texto"]); tipo = cl.get("tipo") or cl.get("classe") or "?"
    classes[tipo] += 1
    if tipo != "reserva_nova": continue
    try: quando = parsedate_to_datetime(em["quando"])
    except Exception: quando = None
    lt = A.ler(em["assunto"], em["texto"], quando); lt.pop("_nome", None)
    leit["completa" if lt.get("completa") else "incompleta"] += 1
    for k in ("codigo", "checkin", "checkout", "hospedes", "anuncio_id", "noites"):
        if k not in lt: leit[f"sem {k}"] += 1
    if not lt.get("codigo"): continue
    por_codigo[lt["codigo"]] = lt
    r = casar(s, lt["codigo"])
    if r is None: casa["sem reserva no sistema"] += 1; continue
    cf = A.conferir(s, lt); casa[cf["estado"]] += 1
    for campo in cf["campos"]: casa[f"diverge {campo}"] += 1
    if cf["estado"] == "confere" and lt.get("anuncio_id"):
        esp = A._espaco_da_reserva(s, r)
        if esp: mapa[lt["anuncio_id"]][esp] += 1
        tipos[lt["anuncio_id"]][tuple(str(getattr(r, k, "")) for k in CAMPOS)] += 1
M.logout()
print(f"INBOX.03_Reservas, 150 dias: e-mails do Airbnb por classe: {dict(classes)}")
print(f"reservas novas lidas: {dict(leit)}")
print(f"casadas com o sistema: {dict(casa)}")
un = sum(1 for a, e in mapa.items() if len(e) == 1); amb = sum(1 for a, e in mapa.items() if len(e) > 1)
print(f"anuncios do Airbnb vistos: {len(mapa)} · um espaco so: {un} · mais de um espaco: {amb}")
print("campos de tipo usados:", CAMPOS)
print("anuncios com UM tipo so (pelos campos acima):", sum(1 for a in mapa if len(tipos[a]) == 1), "de", len(mapa))
print("   tipos por anuncio:", sorted(len(tipos[a]) for a in mapa))
print("   (espacos por anuncio ambiguo, so quantidades):", sorted(len(e) for e in mapa.values() if len(e) > 1))
# reservas futuras do sistema
def canal(r): return str(getattr(r, "channel", "") or getattr(r, "canal", "") or "")
def ota_ref(r):
    for k in ("ota_reference", "external_reference", "ota_code", "confirmation_code", "codigo"):
        v = getattr(r, k, None)
        if v: return str(v)
    return ""
fut = [r for r in (getattr(s, "reservations", {}) or {}).values()
       if getattr(r, "checkout", None) and r.checkout >= hoje and "cancel" not in str(getattr(r, "status", "")).lower()]
print("reservas futuras/em curso no sistema:", len(fut), "por canal:", dict(Counter(canal(r) for r in fut)))
com_hm = [r for r in fut if ota_ref(r).upper().startswith("HM")]
print("   com codigo HM (Airbnb):", len(com_hm), "· com e-mail de reserva achado:", sum(1 for r in com_hm if ota_ref(r) in por_codigo))
print("   campos de referencia na reserva:", [k for k in ("ota_reference", "external_reference", "ota_code", "confirmation_code", "codigo") if hasattr(next(iter(s.reservations.values())), k)])
PY
echo fim
