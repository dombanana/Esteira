#!/usr/bin/env bash
# 032 -- so leitura: a 1.0.275 no ar, em sombra -- o que os e-mails do Airbnb que chegaram depois da instalacao teriam feito
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from collections import Counter
from app.versao import VERSAO
from app.main import build_state
s = build_state().store
print("no ar:", VERSAO)
rows = [x for x in s.entradas.values() if x.get("ota") == "Airbnb" and x.get("plano")]
print("e-mails do Airbnb com plano:", len(rows), dict(Counter(f"{x['tipo']}->{x['plano']['acao']}" for x in rows)))
for x in sorted(rows, key=lambda x: x["recebido_em"])[-10:]:
    p = x["plano"]; print("  ", x["recebido_em"][:16], x["tipo"], p["acao"], p.get("unidade", ""), p["motivo"][:90].replace(x.get("codigo") or "~", "HM******"))
m = [r for r in s.reservations.values() if r.ota_code and r.ota_code.startswith("HM") and str(r.external_id).isdigit() and r.referral == "nobeds"]
print("reservas da Nobeds com HM e referral ainda 'nobeds' (as manuais ganham Airbnb so na proxima reimportacao):", len(m))
PY
