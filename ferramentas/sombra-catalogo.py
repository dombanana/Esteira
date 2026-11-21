"""Gera e envia um pedido SO LEITURA da sombra diaria do catalogo por ID (V1.1 Reservas e canais 1.3.0 ao lado da V1.0;
Dom 21/11/2026 "Alta": 7 dias de sombra antes de qualquer "ligado").

Uso (na raiz do repositorio Esteira): python3 ferramentas/sombra-catalogo.py [horas=30]
Embute (so em memoria, nada e instalado na VPS) o leitor e o catalogo da V1.1 que estao em /home/claude/v11/reservas-canais.
Saida do pedido: LEITOR;... (cada e-mail do Airbnb da janela: tipo na V1.0 x V1.1, campos diferentes, decisao da V1.1)
e ENCAIXE;... (cada reserva criada pela V1.0 na janela: unidade da V1.0 x unidade que a V1.1 escolheria).
Nenhum nome, codigo HM, valor, telefone ou e-mail.
"""
import base64, os, subprocess, sys
from datetime import datetime
from zoneinfo import ZoneInfo

HORAS = int(sys.argv[1]) if len(sys.argv) > 1 else 30
R = "/home/claude/v11/reservas-canais"
b64 = lambda p: base64.b64encode(open(p, "rb").read()).decode()
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(raiz)
subprocess.run(["git", "pull", "-q"], check=False, capture_output=True)
n = max(int(f.split("-")[0]) for f in os.listdir("pedidos") if f[:3].isdigit()) + 1
quando = datetime.now(ZoneInfo("America/Sao_Paulo")).strftime("%Y%m%d-%H%M")
nome = f"pedidos/{n:03d}-sombra-catalogo-{quando}-leitura.sh"
script = r'''#!/usr/bin/env bash
# SO LEITURA -- sombra diaria do catalogo por ID (V1.1 Reservas e canais 1.3.0) ao lado da V1.0, janela de %(HORAS)s h.
# Leitor e catalogo da V1.1 embutidos (so em memoria). IMAP so leitura (readonly + BODY.PEEK). Nada e gravado.
# Saida: tipos, nomes de campo, ids de anuncio e unidades. Nenhum nome, codigo HM, valor, telefone ou e-mail.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 600 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import base64, email, imaplib, json, os, types
from datetime import date, datetime, timedelta, timezone
from email.utils import parseaddr, parsedate_to_datetime
def modulo(nome, b):
    m = types.ModuleType(nome); exec(compile(base64.b64decode(b).decode(), nome, "exec"), m.__dict__); return m
A11 = modulo("v11_airbnb_email", "%(EMAIL)s")
C11 = modulo("v11_catalogo", "%(CAT)s")
CAT = C11.validar(json.loads(base64.b64decode("%(JSON)s").decode()))
from app.main import build_state
from app.entrada import imap_reservas as I, airbnb_email as A10, airbnb_reservas as R10
from app.entrada.intents import classificar as classificar10, ota_do_dominio, casar
st = build_state(); s = st.store; agora = datetime.now(timezone.utc); desde = agora - timedelta(hours=%(HORAS)s)
# v1.0.278: a V1.0 le DUAS caixas (a .tech antiga e a contato@dombanana.com.br, para onde o Airbnb manda desde 19/11)
contas = I.contas(os.environ) if hasattr(I, "contas") else [I.config(os.environ)]
contas = [c for c in contas if c]
print("caixas lidas:", len(contas))
def emails():
    vistos = set()
    for cfg in contas:
        M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
        for pasta in cfg["pastas"]:
            typ, _ = M.select(f'"{pasta}"', readonly=True)
            if typ != "OK": continue
            typ, d = M.search(None, f"(SINCE {(desde - timedelta(days=1)).strftime('%%d-%%b-%%Y')})")
            for num in ((d[0] or b"").split() if typ == "OK" else []):
                t, c = M.fetch(num, "(BODY.PEEK[HEADER.FIELDS (FROM DATE MESSAGE-ID)])")
                h = email.message_from_bytes(c[0][1])
                mid = str(h.get("Message-ID") or "").strip()
                if mid in vistos: continue
                if ota_do_dominio(parseaddr(I._dec(h.get("From")))[1].lower().rsplit("@", 1)[-1]) != "Airbnb": continue
                try: q = parsedate_to_datetime(str(h.get("Date") or ""))
                except Exception: q = None
                if q is None or q < desde: continue
                vistos.add(mid)
                t, c = M.fetch(num, "(BODY.PEEK[])")
                yield q, I.para_porta(c[0][1])
        M.logout()
n = 0
for q, em in emails():
    n += 1
    t10 = classificar10(em["dominio"], em["assunto"], em["texto"]).get("tipo") or "outro"
    t11 = A11.classificar(em["assunto"], em["texto"])
    difs = []
    if t10 == "reserva_nova":
        l10 = A10.ler(em["assunto"], em["texto"], q); l11 = A11.ler(em["assunto"], em["texto"], q)
        difs = [k for k in ("codigo", "checkin", "checkout", "hospedes", "noites", "anuncio_id", "completa", "aviso") if l10.get(k) != l11.get(k)]
    r = A11.converter({"dominio": em["dominio"], "assunto": em["assunto"], "texto": em["texto"], "quando": em["quando"]})
    dec = ("reserva" if r.get("reserva", {}).get("estado") != "cancelada" else "cancelamento") if "reserva" in r else ("alarme" if "alarme" in r else "ignora")
    print(f"LEITOR;{q.astimezone(timezone(timedelta(hours=-3))).strftime('%%Y-%%m-%%d %%H:%%M')};{t10};{t11};{'|'.join(difs) or '-'};{dec}")
print(f"emails do Airbnb na janela: {n}")
for row in sorted((getattr(s, "entradas", {}) or {}).values(), key=lambda r: str(r.get("recebido_em") or "")):
    p = row.get("plano") or {}
    if row.get("ota") != "Airbnb" or str(row.get("recebido_em") or "") < desde.isoformat(): continue
    if p.get("acao") not in ("criar", "alarme") or row.get("tipo") != "reserva_nova": continue
    if p.get("acao") == "alarme":
        print(f"ENCAIXE;{str(row.get('recebido_em'))[:16]};{p.get('anuncio_id') or '-'};alarme na V1.0;{(p.get('motivo') or '')[:60].replace(';', ',')}"[:200]); continue
    res = casar(s, p.get("codigo") or ""); sem = res.reservation_id if res is not None else ""
    ci, co = date.fromisoformat(p["checkin"]), date.fromisoformat(p["checkout"])
    prod = C11.resolver(CAT, "airbnb", str(p.get("anuncio_id")))
    if prod is None or not prod["sozinho"]:
        print(f"ENCAIXE;{str(row.get('recebido_em'))[:16]};{p.get('anuncio_id')};{p.get('unidade')};V1.1 manda ao alarme"); continue
    cand = C11.candidatas(CAT, prod, p.get("hospedes"))
    esc = next((u for u in cand if not R10.ocupantes(s, u, ci, co, sem=sem)), "SEM VAGA")
    print(f"ENCAIXE;{str(row.get('recebido_em'))[:16]};{p.get('anuncio_id')};{p.get('unidade')};{esc};{'IGUAL' if esc == p.get('unidade') else 'DIFERENTE'};{prod['codigo']}")
PY
echo "fim"
''' % {"HORAS": HORAS, "EMAIL": b64(f"{R}/reservas_canais/airbnb_email.py"), "CAT": b64(f"{R}/reservas_canais/catalogo.py"),
       "JSON": b64(f"{R}/casas/ipiranga.json")}
open(nome, "w").write(script)
os.chmod(nome, 0o755)
subprocess.run(["bash", "-n", nome], check=True)
subprocess.run(["git", "add", nome], check=True)
subprocess.run(["git", "commit", "-qm", f"{os.path.basename(nome)} (sombra diaria do catalogo, so leitura)"], check=True)
subprocess.run(["git", "push", "-q"], check=False, capture_output=True)
print(nome)
