#!/usr/bin/env bash
# 047 -- so leitura: onde o .tech ainda esta em uso. (1) chaves do secrets cujo VALOR cita dombanana.tech (so o nome da
# chave e o endereco); (2) na caixa contato@dombanana.tech, 120 dias: quem manda e-mail (dominio do remetente) e para qual
# endereco .tech; (3) se a segunda caixa (IMAP2) ja foi gravada. Sem nomes de hospede, sem senhas.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 500 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import email, imaplib, os, re, collections
from datetime import datetime, timedelta, timezone
from email.utils import parseaddr, getaddresses
print("== 1. chaves do secrets que citam dombanana.tech")
for k in sorted(os.environ):
    v = os.environ[k]
    if "dombanana.tech" in v.lower() and not re.search(r"SENHA|PASS|TOKEN|SECRET|KEY", k):
        print(f"   {k} = {', '.join(sorted(set(re.findall(r'[\w.+-]+@dombanana\.tech', v.lower()))) or '(dominio, sem endereco)')}")
print("== 3. segunda caixa gravada:", "sim (" + os.environ.get("PMS_RESERVAS_IMAP2_USUARIO", "") + ")" if os.environ.get("PMS_RESERVAS_IMAP2_SENHA") else "ainda nao")
from app.entrada import imap_reservas as I
cfg = I.config(os.environ)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
pastas = [f.decode(errors="replace").split(' "." ')[-1].split(' "/" ')[-1].strip('"') for f in M.list()[1]]
desde = (datetime.now(timezone.utc) - timedelta(days=120)).strftime("%d-%b-%Y")
rem = collections.Counter(); para = collections.Counter(); par = collections.Counter()
for p in pastas:
    if re.search(r"Trash|Lixeira|Junk|Spam|Sent|Enviad|Drafts|Rascunh", p, re.I): continue
    if M.select(f'"{p}"', readonly=True)[0] != "OK": continue
    typ, d = M.search(None, f"(SINCE {desde})")
    nums = (d[0] or b"").split()
    for i in range(0, len(nums), 200):
        t, c = M.fetch(b",".join(nums[i:i+200]), "(BODY.PEEK[HEADER.FIELDS (FROM TO CC DELIVERED-TO)])")
        for part in c:
            if not isinstance(part, tuple): continue
            h = email.message_from_bytes(part[1])
            dom = parseaddr(I._dec(h.get("From")))[1].lower().rsplit("@", 1)[-1]
            alvos = {a.lower() for _, a in getaddresses([I._dec(h.get("To") or ""), I._dec(h.get("Cc") or ""), I._dec(h.get("Delivered-To") or "")]) if a.lower().endswith("@dombanana.tech")}
            rem[dom] += 1
            for a in alvos or {"(sem .tech no To)"}:
                para[a] += 1; par[(a, dom)] += 1
M.logout()
print("== 2. caixa", cfg["usuario"], "· 120 dias")
print("   enderecos .tech que recebem:", dict(para.most_common(12)))
print("   remetentes por dominio (top 40):")
for dom, n in rem.most_common(40): print(f"     {n:>5}  {dom}")
print("   endereco x remetente (top 40):")
for (a, dom), n in par.most_common(40): print(f"     {n:>5}  {a:<32} <- {dom}")
PY
