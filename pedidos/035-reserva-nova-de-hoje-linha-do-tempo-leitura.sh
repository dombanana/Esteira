#!/usr/bin/env bash
# 035 -- so leitura: a reserva nova do Airbnb desta manha (Dom 08h49: "a ficha ainda nao saiu"). Linha do tempo do e-mail
# ate a reserva na casa, o plano da sombra (1.0.275) e o estado da ficha/convite. Nome so usado para achar (nunca impresso).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
echo "diario (desde 6h SP):"; journalctl -u pms-banana-ai-worker --since "2026-11-19 09:00:00 UTC" --no-pager -o short-iso 2>/dev/null | grep -iE "caixa das reservas|airbnb|calend.rio|Nobeds.*(nova|Criei|import)|reserva nova|Criei|precheckin|convite" | sed -E 's/HM[A-Z0-9]{8}/HM******/g' | tail -25 | cut -c1-220
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from datetime import datetime, timezone, timedelta
from app.main import build_state
st = build_state(); s = st.store
alvo = "baus"
def m(c): return (c or "")[:4] + "******" if c else "-"
rows = sorted([x for x in s.entradas.values() if x.get("ota") == "Airbnb" and str(x.get("recebido_em") or "") >= "2026-11-19T09"], key=lambda x: x["recebido_em"])
print("e-mails do Airbnb desde 06h SP:", len(rows))
for x in rows:
    p = x.get("plano") or {}
    print("  ", x["recebido_em"][:19], x.get("tipo"), m(x.get("codigo")), "| plano:", p.get("acao", "(sem plano)"), p.get("unidade", ""), str(p.get("motivo", ""))[:80].replace(x.get("codigo") or "~", "HM******"))
# a reserva pelo nome (so para achar)
achadas = []
for r in s.reservations.values():
    pe = s.persons.get(r.main_guest)
    if pe and alvo in str(getattr(pe, "name", "")).lower():
        achadas.append(r)
print("reservas com esse nome:", len(achadas))
for r in achadas:
    ev = s.events.get(r.reservation_id)
    print("   chave:", "HM" if str(r.external_id).startswith("HM") else ("numero da Nobeds" if str(r.external_id).isdigit() else "?"),
          "| codigo:", m(r.ota_code), "| referral:", r.referral, "| status:", getattr(r.status, "value", r.status),
          "| datas:", r.checkin, "a", r.checkout, "| lugar:", getattr(ev, "where", None), "| hospedes:", r.paid_occupancy)
    # quando entrou (diario do sistema)
    recs = [x for x in st.ledger.records() if getattr(x, "subject_id", None) in (r.reservation_id, r.external_id)] if hasattr(st.ledger, "records") else []
    if recs: print("   1o registro no diario:", min(getattr(x, "at", "") for x in recs))
    email = [x for x in s.entradas.values() if x.get("codigo") and x.get("codigo") == r.ota_code]
    for x in email: print("   e-mail:", x.get("tipo"), x.get("recebido_em", "")[:19], "plano:", (x.get("plano") or {}).get("acao"))
    for nome in ("precheckin", "convites", "invites", "fichas", "fnrh"):
        tab = getattr(s, nome, None)
        if isinstance(tab, dict):
            v = [k for k, y in tab.items() if r.reservation_id in str(k) or r.reservation_id in str(y)[:400]]
            if v: print("   ", nome, ":", len(v), "registro(s)")
PY
