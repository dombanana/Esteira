"""Gera um pedido SO LEITURA: mapa de reservas por anuncio do Airbnb (Economico e Smart), a partir dos e-mails do Airbnb
das duas caixas + o que a V1.0 tem gravado. Pedido do Dom 24/11 18h42 e 25/11 08h45 (apagar anuncios do Economico sem
reserva atual nem futura). Saida: id do anuncio, versao, unidade, fim do codigo (3 letras), datas, estado. Sem nome."""
import base64, os, subprocess, sys
from datetime import datetime
from zoneinfo import ZoneInfo
DIAS = int(sys.argv[1]) if len(sys.argv) > 1 else 200
R = "/home/claude/v11/reservas-canais"
b64 = lambda p: base64.b64encode(open(p, "rb").read()).decode()
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(raiz)
subprocess.run(["git", "pull", "-q"], check=False, capture_output=True)
n = max(int(f.split("-")[0]) for f in os.listdir("pedidos") if f[:3].isdigit()) + 1
quando = datetime.now(ZoneInfo("America/Sao_Paulo")).strftime("%Y%m%d-%H%M")
nome = f"pedidos/{n:03d}-mapa-reservas-economico-{quando}-leitura.sh"
script = r'''#!/usr/bin/env bash
# SO LEITURA -- mapa de reservas por anuncio (Economico e Smart): e-mails do Airbnb (%(DIAS)s dias, IMAP readonly + PEEK)
# cruzados com as reservas gravadas na V1.0. Nada e gravado. Sem nome, sem codigo inteiro (so as 3 ultimas letras).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 900 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import base64, email, imaplib, types
from datetime import date, datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
def modulo(nome, b):
    m = types.ModuleType(nome); exec(compile(base64.b64decode(b).decode(), nome, "exec"), m.__dict__); return m
A11 = modulo("v11_airbnb_email", "%(EMAIL)s")
import os
from app.main import build_state
from app.entrada import imap_reservas as I
from app.entrada.intents import ota_do_dominio, casar
from app.entrada.anuncios_airbnb import TABELA
st = build_state(); s = st.store
hoje = datetime.now(timezone(timedelta(hours=-3))).date()
desde = datetime.now(timezone.utc) - timedelta(days=%(DIAS)s)
contas = [c for c in (I.contas(os.environ) if hasattr(I, "contas") else [I.config(os.environ)]) if c]
print("caixas lidas:", len(contas), "| hoje:", hoje)
res = {}   # ref -> dados
alter = set()
vistos = set(); n = 0
for cfg in contas:
    M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
    for pasta in cfg["pastas"]:
        typ, _ = M.select(f'"{pasta}"', readonly=True)
        if typ != "OK": continue
        typ, d = M.search(None, f"(SINCE {desde.strftime('%%d-%%b-%%Y')} FROM \"airbnb\")")
        for num in ((d[0] or b"").split() if typ == "OK" else []):
            t, c = M.fetch(num, "(BODY.PEEK[HEADER.FIELDS (FROM DATE MESSAGE-ID)])")
            h = email.message_from_bytes(c[0][1]); mid = str(h.get("Message-ID") or "").strip()
            if mid in vistos: continue
            if ota_do_dominio(parseaddr(I._dec(h.get("From")))[1].lower().rsplit("@", 1)[-1]) != "Airbnb": continue
            vistos.add(mid)
            t, c = M.fetch(num, "(BODY.PEEK[])"); em = I.para_porta(c[0][1]); n += 1
            r = A11.converter({"dominio": em["dominio"], "assunto": em["assunto"], "texto": em["texto"], "quando": em["quando"]})
            if "reserva" in r:
                x = r["reserva"]; ref = x["ref"]
                if x["estado"] == "cancelada":
                    res.setdefault(ref, {})["cancelada_email"] = True
                else:
                    res.setdefault(ref, {}).update({"anuncio": str(x["anuncio"]), "chegada": x["chegada"], "saida": x["saida"]})
            elif r.get("codigo") and "alterou" in str(r.get("alarme", "")):
                alter.add(r["codigo"])
    M.logout()
print("e-mails do Airbnb lidos:", n, "| reservas achadas:", len(res))
ativos = {}
for ref, x in sorted(res.items(), key=lambda kv: kv[1].get("chegada", "")):
    if "anuncio" not in x: continue
    r = casar(s, ref)
    if r is not None:
        estado = str(getattr(r.status, "value", r.status)); ci, co = str(r.checkin)[:10], str(r.checkout)[:10]; fonte = "sistema"
    else:
        estado = "cancelled" if x.get("cancelada_email") else "confirmada(e-mail)"; ci, co = x["chegada"], x["saida"]; fonte = "e-mail"
    if co < hoje.isoformat(): continue
    un, cat, ver = TABELA.get(x["anuncio"], ("?", "fora da tabela", "?"))
    alt = " ALTERADA-conferir" if ref in alter else ""
    print(f"RES;{x['anuncio']};{ver};{un};...{ref[-3:]};{ci};{co};{estado};{fonte}{alt}")
    if "cancel" not in estado.lower():
        ativos.setdefault(x["anuncio"], []).append(f"{ci}>{co}")
print("== ECONOMICO: anuncio;unidade;reservas atuais ou futuras")
for aid, (un, cat, ver) in TABELA.items():
    if ver == "economico":
        print(f"ECO;{aid};{un};{len(ativos.get(aid, []))};{' '.join(ativos.get(aid, []))}")
print("== SMART com reserva atual ou futura: anuncio;unidade;datas")
for aid, (un, cat, ver) in TABELA.items():
    if ver == "smart" and ativos.get(aid):
        print(f"SMT;{aid};{un};{' '.join(ativos[aid])}")
fora = [a for a in ativos if a not in TABELA]
print("anuncios com reserva fora da tabela:", fora)
PY
echo "fim"
''' % {"DIAS": DIAS, "EMAIL": b64(f"{R}/reservas_canais/airbnb_email.py")}
open(nome, "w").write(script); os.chmod(nome, 0o755)
subprocess.run(["bash", "-n", nome], check=True)
subprocess.run(["git", "add", nome], check=True)
subprocess.run(["git", "commit", "-qm", f"{os.path.basename(nome)} (mapa de reservas Economico x Smart, so leitura)"], check=True)
subprocess.run(["git", "push", "-q"], check=False, capture_output=True)
print(nome)
