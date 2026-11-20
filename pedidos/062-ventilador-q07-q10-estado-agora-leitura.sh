#!/usr/bin/env bash
# 062 -- SO LEITURA: (1) codigo de tuya_casa.service.ultimo/_refrescar (de onde vem o estado dos aparelhos);
# (2) teste da leitura para a sombra da V1.1: Q07-Q10 agora -- ocupado (sim/nao), ligado, velocidade, fora do ar,
# idade da leitura. Nenhum nome, codigo de reserva ou valor. Nao chama _refrescar, nao manda comando, nao salva nada.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
f=app/tuya_casa/service.py
for fn in ultimo _refrescar; do
  n=$(grep -nE "^def $fn\(" $f | cut -d: -f1); echo "== $fn (linha $n)"; [ -n "$n" ] && sed -n "${n},$((n+40))p" $f
done
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from datetime import datetime, timezone
from app.main import build_state
from app.tuya_casa import ventilador as V
from app.tuya_casa.service import ultimo
st = build_state(); at = datetime.now(timezone.utc)
aps = V.aparelhos(); u = ultimo(st)
print("aparelhos:", sorted(aps)); print("cache ultimo: %d aparelhos" % len(u))
for q in ("Q07", "Q08", "Q09", "Q10"):
    ap = aps.get(q)
    if not ap: print(q, "sem aparelho"); continue
    reg = u.get(ap["device"]) or {}
    idade = None
    for k in ("at", "lido_em", "ts", "quando", "t"):
        if reg.get(k):
            try: idade = round((at - datetime.fromisoformat(str(reg[k]))).total_seconds()); break
            except Exception: pass
    print(q, "ocupado=%s" % (V.hospede_do_quarto(st.store, q, at) is not None), "ligado=%s" % V.estado_real(st, ap),
          "vel=%s" % V.vel_real(st, ap), "fora_do_ar=%s" % V.fora_do_ar(st, ap), "reles=%s" % bool(ap.get("reles")),
          "chaves_cache=%s" % sorted(k for k in reg if k != "status"), "idade_s=%s" % idade)
PY
echo "fim"
