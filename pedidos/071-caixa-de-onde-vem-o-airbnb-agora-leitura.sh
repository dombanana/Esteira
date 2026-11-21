#!/usr/bin/env bash
# SO LEITURA -- de onde a V1.0 esta lendo os e-mails do Airbnb desde 19/11 (a pasta 03_Reservas parou em 19/11 11h41):
# fonte/caixa/autoria das ultimas linhas do Airbnb, as variaveis de caixa (so os NOMES e se existem) e as pastas da conta.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos bash -c 'env | grep -oE "^PMS_[A-Z_]*(IMAP|EMAIL|HOSTINGER|CAIXA)[A-Z_]*" | sort' 2>/dev/null
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import imaplib, os
from collections import Counter
from app.main import build_state
from app.entrada import imap_reservas as I
st = build_state(); s = st.store
rows = sorted((r for r in (getattr(s, "entradas", {}) or {}).values() if r.get("ota") == "Airbnb"), key=lambda r: str(r.get("recebido_em") or ""))
print("ultimas linhas do Airbnb (recebido;tipo;fonte;caixa;autoria;assinatura):")
for r in rows[-10:]:
    print(" ", str(r.get("recebido_em"))[:16], r.get("tipo"), r.get("fonte"), r.get("caixa"), r.get("autoria"), r.get("assinatura"))
print("autoria desde 19/11:", dict(Counter(r.get("autoria") for r in rows if str(r.get("recebido_em")) >= "2026-11-19T12")))
cfg = I.config(os.environ); print("pastas configuradas:", cfg["pastas"] if cfg else None, "servidor:", cfg["servidor"] if cfg else None)
M = imaplib.IMAP4_SSL(cfg["servidor"], 993, timeout=30); M.login(cfg["usuario"], cfg["senha"])
typ, lista = M.list(); print("pastas da conta:")
for x in lista or []:
    nome = x.decode(errors="replace").split(' "." ')[-1]
    t, n = M.select(nome if nome.startswith('"') else f'"{nome}"', readonly=True)
    print("  ", nome, n[0].decode() if t == "OK" else t)
M.logout()
PY
echo fim
