#!/usr/bin/env bash
# 036 -- so leitura: quanto tempo o e-mail "Reserva confirmada" do Airbnb leva do envio (Date) ate chegar na caixa
# (INTERNALDATE da Hostinger), em 150 dias; e da chegada ate o sistema registrar (recebido_em), nos que o sistema ja leu.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 600 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re, statistics
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
from app.main import build_state
from app.entrada import imap_reservas as I
from app.entrada.intents import classificar, ota_do_dominio
s = build_state().store
agora = datetime.now(timezone.utc); cfg = I.config(os.environ)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
M.select('"INBOX.03_Reservas"', readonly=True)
typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=150)).strftime('%d-%b-%Y')})")
envio_chegada, chegada_sistema = [], []
for n in (d[0] or b"").split():
    t, c = M.fetch(n, "(INTERNALDATE BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE MESSAGE-ID)])")
    meta = c[0][0].decode(); h = email.message_from_bytes(c[0][1])
    if ota_do_dominio(parseaddr(I._dec(h.get("From")))[1].lower().rsplit("@", 1)[-1]) != "Airbnb": continue
    sub = I._dec(h.get("Subject"))
    if (classificar("airbnb.com", sub, "").get("tipo")) != "reserva_nova": continue
    try:
        env = parsedate_to_datetime(h.get("Date")); che = datetime(*imaplib.Internaldate2tuple(meta.encode())[:6], tzinfo=timezone.utc) if False else None
        it = imaplib.Internaldate2tuple(meta.encode()); import time as _t
        che = datetime.fromtimestamp(_t.mktime(it), tz=timezone.utc)
    except Exception: continue
    envio_chegada.append((che - env).total_seconds())
    mid = (h.get("Message-ID") or "").strip()
    for x in s.entradas.values():
        if x.get("id_na_fonte") == mid and x.get("recebido_em"):
            chegada_sistema.append((datetime.fromisoformat(x["recebido_em"]) - che).total_seconds())
M.logout()
def q(v, p): v = sorted(v); return v[min(len(v) - 1, int(round(p * (len(v) - 1))))]
for nome, v in (("envio do Airbnb -> chegada na caixa", envio_chegada), ("chegada na caixa -> sistema registrou", chegada_sistema)):
    if v: print(f"{nome}: {len(v)} e-mails · min {min(v):.0f}s · mediana {statistics.median(v):.0f}s · 95% {q(v, .95):.0f}s · max {max(v):.0f}s")
    else: print(nome + ": sem dados")
PY
