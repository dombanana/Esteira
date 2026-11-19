#!/usr/bin/env bash
# 020 -- etapa 1, so leitura. A FORMA do texto dos e-mails "A alteracao em sua reserva foi aceita" e "Reserva atualizada"
# do Airbnb (onde estao as datas novas), para o leitor aprender a ler. Mascara forte: toda palavra com letra maiuscula fora
# de uma lista fixa vira <X>, codigo HM vira <HM>, valores em R$ viram <R$>. So 2 exemplos de cada, 40 linhas cada.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 600 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr
from app.entrada import imap_reservas as I, airbnb_email as A
from app.entrada.intents import classificar, ota_do_dominio
agora = datetime.now(timezone.utc); cfg = I.config(os.environ)
OK = set("""Check-in Check-out Checkout Check In Out Hóspedes Hospedes Hóspede Adultos Adulto Crianças Bebês Noites Noite Total Datas Data
Reserva Reservas Código Confirmação Airbnb Dom Banana Smart Econômico Cápsula Quarto Privativo Compartilhado Misto Casal Solteiro
Antes Depois Novas Nova Novo Anterior Original Alteração Alterações Alterada Alterado Atualizada Aceita Pedido Detalhes Ver Itinerário
Você Seu Sua Seus Suas Valor Pagamento Ganhos Diferença Reembolso Taxa Taxas Limpeza Serviço Anfitrião Hóspede
Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez Seg Ter Qua Qui Sex Sáb Dom São Paulo Brasil
Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro
Segunda Terça Quarta Quinta Sexta Sábado Domingo De Para Em Do Da Dos Das O A Os As Um Uma E Ou No Na""".split())
def masc(l):
    l = re.sub(r"HM[A-Z0-9]{8}", "<HM>", l); l = re.sub(r"R\$\s?[\d.,]+", "<R$>", l)
    l = re.sub(r"\S+@\S+", "<email>", l); l = re.sub(r"https?://\S+", lambda m: "<link:" + re.sub(r"\d{6,}", "<id>", m.group(0))[:60] + ">", l)
    return " ".join(w if (not re.search(r"[A-ZÁÉÍÓÚÂÊÔÃÕÇ]", w) or re.sub(r"[^\wÀ-ÿ-]", "", w) in OK) else "<X>" for w in l.split())
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
M.select('"INBOX.03_Reservas"', readonly=True)
typ, d = M.search(None, f"(SINCE {(agora - timedelta(days=150)).strftime('%d-%b-%Y')})")
vistos = {}
for n in reversed((d[0] or b"").split()):
    t, c = M.fetch(n, "(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT)])")
    h = email.message_from_bytes(c[0][1]); rem = parseaddr(I._dec(h.get("From")))[1].lower()
    if ota_do_dominio(rem.rsplit("@", 1)[-1]) != "Airbnb": continue
    sub = I._dec(h.get("Subject"))
    k = "aceita" if "foi aceita" in sub else ("atualizada" if sub.strip().startswith("Reserva atualizada") else None)
    if not k or vistos.get(k, 0) >= 2: continue
    vistos[k] = vistos.get(k, 0) + 1
    t, c = M.fetch(n, "(BODY.PEEK[])"); em = I.para_porta(c[0][1])
    linhas = [x.strip() for x in A.limpo(em["texto"]).splitlines() if x.strip()]
    if len(linhas) < 5: linhas = [x.strip() for x in re.split(r"(?<=[.!?])\s+|\s{2,}", A.limpo(em["texto"])) if x.strip()]
    print(f"===== {k} #{vistos[k]} ({len(linhas)} linhas)")
    for x in linhas[:45]: print("   ", masc(x)[:150])
    if all(v >= 2 for v in (vistos.get("aceita", 0), vistos.get("atualizada", 0))): break
M.logout()
PY
echo fim
