#!/usr/bin/env bash
# 019 -- etapa 1, so leitura. Prova da leitura dos e-mails de ALTERACAO e CANCELAMENTO do Airbnb (150 dias) contra o que
# o sistema tem hoje (que veio da Nobeds ate 18/11): a data lida e a data NOVA? o cancelado esta cancelado no sistema?
# Saida so com contagens e formas (sem nome, codigo, valor).
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
cfg = I.config(os.environ)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
M.select('"INBOX.03_Reservas"', readonly=True)
typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=150)).strftime('%d-%b-%Y')})")
res = defaultdict(Counter); formas = Counter(); assuntos = Counter(); ult = {}
def forma(t):
    t = re.sub(r"HM[A-Z0-9]{8}", "<HM>", t); t = re.sub(r"\d+", "9", t)
    return re.sub(r"(?i)(reserva|reservation)\s+(de|for|com|with)\s+\S+(\s+\S+)?", r"\1 \2 <nome>", t)[:90]
for n in (d[0] or b"").split():
    t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM)])")
    rem = parseaddr(I._dec(email.message_from_bytes(c[0][1]).get("From")))[1].lower()
    if ota_do_dominio(rem.rsplit("@", 1)[-1]) != "Airbnb": continue
    t, c = M.fetch(n, "(BODY.PEEK[])"); em = I.para_porta(c[0][1])
    cl = classificar(em["dominio"], em["assunto"], em["texto"]); tipo = cl.get("tipo") or cl.get("classe")
    if tipo not in ("alteracao", "cancelamento"): continue
    try: quando = parsedate_to_datetime(em["quando"])
    except Exception: quando = None
    lt = A.ler(em["assunto"], em["texto"], quando)
    assuntos[(tipo, forma(em["assunto"] or ""))] += 1
    R = res[tipo]; R["e-mails"] += 1
    R["com codigo" if lt.get("codigo") else "SEM codigo"] += 1
    if not lt.get("codigo"): continue
    r = casar(s, lt["codigo"])
    if r is None: R["sem reserva no sistema"] += 1; continue
    st_r = str(getattr(r.status, "value", r.status))
    if tipo == "cancelamento":
        R[f"sistema: {st_r}"] += 1
    else:
        tem = "checkin" in lt and "checkout" in lt
        if not tem: R["sem datas lidas"] += 1; continue
        ok = (lt["checkin"] == r.checkin.isoformat(), lt["checkout"] == r.checkout.isoformat())
        R[{(True, True): "datas lidas = datas atuais do sistema", (True, False): "so check-in igual", (False, True): "so checkout igual", (False, False): "datas diferentes"}[ok]] += 1
        R["hospedes lidos = sistema" if lt.get("hospedes") == int(r.paid_occupancy) else ("hospedes nao lidos" if "hospedes" not in lt else "hospedes diferentes")] += 1
        R["com anuncio" if lt.get("anuncio_id") else "sem anuncio"] += 1
        R["completa" if lt.get("completa") else "incompleta"] += 1
        if "aviso" in lt: R["aviso noites x datas"] += 1
M.logout()
for k, v in res.items(): print(k, dict(v))
print("formas de assunto:")
for (tp, f), n in assuntos.most_common(30): print(f"  {tp:12} x{n:3}  {f}")
PY
echo fim
