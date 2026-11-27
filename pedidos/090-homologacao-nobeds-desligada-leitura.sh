#!/usr/bin/env bash
# SO LEITURA -- homologacao do desligamento automatico da Nobeds (27/11/2026 00h SP, PMS_NOBEDS=auto).
# Nenhuma chamada a Nobeds, TTLock ou Airbnb. Sem nome, telefone, e-mail ou senha de hospede.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "== versao no ar"
grep VERSAO app/versao.py
echo "== diario do worker desde 26/11 23:50 SP (max 30 linhas)"
journalctl -u pms-banana-ai-worker --since "2026-11-26 23:50:00 America/Sao_Paulo" --no-pager 2>&1 \
  | grep -E "Nobeds desligada|reconciliacao|vigia do Nobeds|caixa das reservas|calend" \
  | sed -E 's/HM[A-Z0-9]{8}/HM******/g' | head -30
echo "== sistema"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import json, os, re
from collections import Counter
from datetime import datetime
from zoneinfo import ZoneInfo
from app.channel import nobeds_fim as NF
print("PMS_NOBEDS:", os.environ.get("PMS_NOBEDS", ""))
print("NF.ligada():", NF.ligada())
from app.main import build_state
st = build_state(); s = st.store
fs = getattr(s, "fontes_saude", {}) or {}
def limpa(t):
    t = re.sub(r"HM[A-Z0-9]{8}", "HM******", t)
    t = re.sub(r"[\w.+-]+@[\w-]+\.[\w.]+", "<email>", t)
    t = re.sub(r"\+?\d[\d ()-]{8,}\d", "<num>", t)
    return t[:400]
for k in ("nobeds", "nobeds_mcp", "nobeds_dia", "nobeds_erros"):
    d = fs.get(k)
    if d is None:
        print(f"SAUDE;{k};AUSENTE"); continue
    d = d if isinstance(d, dict) else getattr(d, "__dict__", {})
    print(f"SAUDE;{k};estado={d.get('estado')};quando={d.get('quando') or d.get('atualizado') or d.get('em')};dados={limpa(json.dumps(d.get('dados'), default=str, ensure_ascii=False))}")
tz = ZoneInfo(getattr(s, "timezone", "America/Sao_Paulo") or "America/Sao_Paulo")
hoje = datetime.now(tz).date()
def dia(x):
    return x.date() if hasattr(x, "date") and callable(x.date) else x
c = Counter(); c_origem = Counter()
for r in s.reservations.values():
    co = getattr(r, "checkout", None)
    if not co or dia(co) < hoje: continue
    st_ = str(getattr(r.status, "value", r.status))
    c[st_] += 1
    c_origem[(st_, str(getattr(r, "source", getattr(r, "origem", "?"))))] += 1
print("hoje:", hoje)
print("reservas com checkout >= hoje por status:", dict(c))
print("por status/origem:", {f"{a}/{b}": n for (a, b), n in sorted(c_origem.items())})
PY
echo "== fim"
