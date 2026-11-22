#!/usr/bin/env bash
# Gera e envia um pedido SO LEITURA da sombra da Carteira (V1.1, Dom 21/11 21h56 "Alta").
# Le SO o banco da V1.0. Sem nome, sem valor em reais, sem codigo de reserva (resumo de 10 letras).
set -eu
cd "$(dirname "$0")/.."
git pull -q
n=$(ls pedidos | grep -oE '^[0-9]+' | sort -n | tail -1); n=$(printf "%03d" $((10#$n + 1)))
quando=$(TZ=America/Sao_Paulo date +%Y%m%d-%H%M)
f="pedidos/$n-sombra-carteira-$quando-leitura.sh"
cat > "$f" <<'EOF'
#!/usr/bin/env bash
# SO LEITURA -- sombra da Carteira (V1.1): compara, estadia a estadia, o que a V1.0 decide sobre pagamento (payment_state
# e se segura a porta) com o que a Carteira 1.1.0 decidiria com a mesma origem e as mesmas cobrancas. Sem valores.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import hashlib
from collections import Counter
from datetime import datetime, timedelta, timezone
from app.main import build_state
from app.core.event import EventState
from app.reservation.intents import OPERATIONAL_INSTANCES
from app.finance.direct import payment_state, payment_pending, reservation_for_event, charges_of, is_direct, is_hostelworld
st = build_state(); s = st.store; agora = datetime.now(timezone.utc)
H = lambda x: hashlib.sha256(("carteira|" + str(x)).encode()).hexdigest()[:10]
DIRETAS = {"one page", "onepage", "website", "motor de reservas", "site", "direta", "direto", "reserva direta", "motor"}
MAPA = {"paid": "paga", "requested": "aguardando", "pending": "aguardando", "manual_review": "revisao"}
c = Counter(); dif = []
for key, e in list(s.events.items()):
    if e.instance in OPERATIONAL_INSTANCES or e.state not in (EventState.CONFIRMED, EventState.IN_PROGRESS):
        continue
    if e.when.end < agora - timedelta(days=1) or e.when.start > agora + timedelta(days=8):
        continue
    r = reservation_for_event(s, e)
    if r is None:
        continue
    ref = str(getattr(r, "referral", "") or "").strip()
    direta11 = ref.casefold() in DIRETAS or is_direct(r, s)
    p10 = payment_state(s, r); seg10 = payment_pending(s, r)
    cobs = [MAPA.get(x["status"], "cancelada") for x in charges_of(s, r.reservation_id)]
    # a Carteira: revisao > aberta > paga > a_pagar (direta) > nao_se_aplica
    if "revisao" in cobs: s11 = "revisao"
    elif "aguardando" in cobs: s11 = "aguardando"
    elif "paga" in cobs: s11 = "pago"
    elif direta11 or (is_hostelworld(r) and r.balance_amount > 0): s11 = "a_pagar"
    else: s11 = "nao_se_aplica"
    seg11 = s11 not in ("pago", "nao_se_aplica")
    h = H(e.event_id); c["estadias"] += 1; c[f"v10 {p10}"] += 1
    print(f"EST;{h};{e.where[0] if e.where else '?'};origem={ref or '-'};v10={p10};v11={s11};segura10={'s' if seg10 else 'n'};segura11={'s' if seg11 else 'n'}")
    if seg10 != seg11:
        dif.append(f"{h} origem={ref or '-'}: V1.0 {p10} ({'segura' if seg10 else 'libera'}) x V1.1 {s11} ({'segura' if seg11 else 'libera'})")
print("== RESUMO:", dict(c))
print(f"== DIFERENCAS NA PORTA ({len(dif)}):"); [print("   " + x) for x in dif]
PY
EOF
chmod +x "$f"
git add "$f" ferramentas/sombra-carteira.sh
git commit -qm "$n sombra da Carteira (V1.1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015hfBPPTH2mP2V6GT2fgPtP"
git push -q 2>/dev/null
echo "$n"
