#!/usr/bin/env bash
# SO LEITURA -- sombra do catalogo por ID (V1.1 Reservas e canais, Dom 21/11 "Alta"): para cada e-mail do Airbnb que a
# V1.0 ja leu (store.entradas), o que a V1.0 decidiu: tipo, acao, anuncio, unidade do anuncio, unidade escolhida, versao,
# categoria. Codigo HM mascarado; nenhum nome, valor, telefone ou e-mail. Nao grava nada.
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import json, re
from collections import Counter
from app.main import build_state
st = build_state(); s = st.store
rows = list((getattr(s, "entradas", {}) or {}).values())
print("entradas:", len(rows))
air = [r for r in rows if r.get("ota") == "Airbnb"]
print("airbnb:", len(air), dict(Counter(str(r.get("tipo")) for r in air)))
if air: print("campos linha:", sorted(air[0].keys()))
mask = lambda t: re.sub(r"HM[A-Z0-9]{8}", "HM******", str(t or ""))
print("== LINHA;recebido;tipo;acao;anuncio;unidade_anuncio;unidade;versao;categoria;motivo")
for r in sorted(air, key=lambda r: str(r.get("recebido_em") or "")):
    p = r.get("plano") or {}
    if isinstance(p, str):
        try: p = json.loads(p)
        except Exception: p = {"motivo": p}
    print("LINHA;" + ";".join(mask(x).replace(";", ",") for x in (str(r.get("recebido_em") or "")[:16], r.get("tipo"), p.get("acao"),
          p.get("anuncio_id"), p.get("unidade_anuncio"), p.get("unidade"), p.get("versao"), p.get("categoria"), p.get("motivo"))))
PY
echo "fim"
