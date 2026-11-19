#!/usr/bin/env bash
# 041 -- so leitura: (1) quais caixas de e-mail o sistema tem credencial (so NOMES das chaves e o endereco, nunca senha);
# (2) os e-mails do Airbnb chegando na caixa lida hoje, hora a hora, e para qual endereco foram (To); (3) o calendario em sombra.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re, collections
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr, getaddresses
print("== 1. chaves de e-mail no secrets (sem valores de senha)")
for k in sorted(os.environ):
    if re.search(r"IMAP|SMTP|MAIL|EMAIL", k):
        v = os.environ[k]
        if re.search(r"SENHA|PASS|TOKEN|KEY|SECRET", k): print(f"   {k} = (tem valor, {len(v)} car.)" if v else f"   {k} = (vazio)")
        elif "@" in v or re.search(r"USUARIO|USER|FROM|SERVIDOR|HOST|PASTAS|SEGUNDOS|^PMS_RESERVAS_IMAP$|AIRBNB", k): print(f"   {k} = {v[:80]}")
        else: print(f"   {k} = ({len(v)} car.)")
from app.entrada import imap_reservas as I
cfg = I.config(os.environ)
print("== 2. caixa lida:", cfg and cfg["usuario"], "· pastas:", cfg and cfg["pastas"])
hoje = datetime.now(timezone(timedelta(hours=-3))).replace(hour=0, minute=0, second=0, microsecond=0)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
por_hora = collections.Counter(); para = collections.Counter(); ultimo = None
for pasta in cfg["pastas"]:
    if M.select(f'"{pasta}"', readonly=True)[0] != "OK": continue
    typ, d = M.search(None, f"(SINCE {(hoje - timedelta(days=1)).strftime('%d-%b-%Y')})")
    for n in (d[0] or b"").split():
        t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM TO DELIVERED-TO X-ORIGINAL-TO DATE)])")
        h = email.message_from_bytes(c[0][1])
        if not parseaddr(I._dec(h.get("From")))[1].lower().endswith("airbnb.com"): continue
        try: dt = email.utils.parsedate_to_datetime(h.get("Date")).astimezone(hoje.tzinfo)
        except Exception: continue
        por_hora[(pasta, dt.strftime("%d/%m %Hh"))] += 1
        for _, a in getaddresses([I._dec(h.get("To") or "")]): para[a.lower()] += 1
        if not ultimo or dt > ultimo: ultimo = dt
M.logout()
for k in sorted(por_hora): print(f"   {k[0]:<18} {k[1]}: {por_hora[k]}")
print("   destinatarios (To):", dict(para)); print("   ultimo e-mail do Airbnb:", ultimo and ultimo.strftime("%d/%m %H:%M"))
print("== 3. calendario (sombra) e saude das fontes")
from app.main import build_state
st = build_state(); s = st.store
for nome in ("airbnb_ical", "imap_reservas", "nobeds"):
    x = [v for v in getattr(s, "saude", {}).values() if v.get("fonte") == nome] if hasattr(s, "saude") else []
    print("  ", nome, x[-1] if x else "(sem registro em store.saude)")
al = [a for a in getattr(s, "alerts", {}).values() if str(a.get("alert_id", a.get("id", ""))).startswith(("ical", "airbnb-ical", "airbnb_ical"))] if hasattr(s, "alerts") else []
print("   alertas do calendario:", len(al))
ev = [e for e in getattr(s, "eventos", {}).values()] if hasattr(s, "eventos") else []
print("   switch PMS_AIRBNB_ICAL =", os.environ.get("PMS_AIRBNB_ICAL"), "· PMS_AIRBNB_EMAIL_RESERVAS =", os.environ.get("PMS_AIRBNB_EMAIL_RESERVAS"))
PY
echo "== 4. log do worker: calendario de hoje"
sudo -n journalctl -u pms-banana-ai-worker --since today --no-pager 2>/dev/null | grep -iE "ical|calend" | tail -8 | cut -c1-220 || echo "(sem acesso ao journal)"
