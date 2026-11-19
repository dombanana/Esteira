#!/usr/bin/env bash
# 034 -- HOMOLOGACAO (so leitura) da 1.0.276 no ar: versao, worker, a 1a volta do calendario do Airbnb (sombra), a saude
# "airbnb_ical", e o modo sombra das reservas pelo e-mail. Sem link, nome ou valor.
set -u
exec 2>&1
echo "no ar: $(grep -oP 'VERSAO = "\K[^"]+' /opt/PMS-Banana-AI/SISTEMA/api/app/versao.py) · worker: $(systemctl is-active pms-banana-ai-worker.service) · API: $(systemctl is-active pms-banana-ai.service)"
echo "diario do worker (ultima hora):"
journalctl -u pms-banana-ai-worker --since "60 min ago" --no-pager -o cat 2>/dev/null | grep -iE "calend.rio do Airbnb|caixa das reservas|airbnb" | tail -6 | sed -E 's/HM[A-Z0-9]{8}/HM******/g; s/t=[0-9a-f]+/t=***/g' | cut -c1-200
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import os
from collections import Counter
from app.main import build_state
from app.entrada import airbnb_ical as IC, airbnb_reservas as AR
s = build_state().store
print("modos: e-mail =", AR.modo(), "· calendario =", IC.modo(), "· links validos:", len(IC.links()))
f = s.fontes_saude.get("airbnb_ical")
if f:
    d = f.get("dados") or {}
    print("saude airbnb_ical:", f.get("estado"), "· lido em", str(f.get("lido_em") or f.get("ultimo_ok"))[:16], "· anuncios", d.get("anuncios"), "lidos", d.get("lidos"), "falhas", d.get("falhas"), "· reservas no Airbnb", d.get("reservas_no_airbnb"), "· achados", dict(Counter(a["tipo"] for a in d.get("achados") or [])))
else:
    print("saude airbnb_ical: (ainda sem registro)")
rows = [x for x in s.entradas.values() if x.get("ota") == "Airbnb" and x.get("plano")]
print("e-mails do Airbnb com plano (sombra):", len(rows), dict(Counter(f"{x['tipo']}->{x['plano']['acao']}" for x in rows)))
PY
