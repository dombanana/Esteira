#!/usr/bin/env bash
# SO LEITURA (codigo + estado da estadia do Q06 de hoje): o bloqueio "reserva pessoal e intransferivel / nao e o titular"
# e como o anfitriao libera. Sem nome, sem documento.
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
grep -rn -i "intransfer\|nao e o titular\|não é o titular\|titular_confere\|nome_confere\|outra_pessoa\|bloqueio_titular\|titular_bloq" $A --include=*.py | grep -v tests | head -20
echo "== intents de liberar"; grep -rn 'name="reservation\.\(liberar\|desbloquear\|titular\)[a-z_]*"' $A --include=*.py | head -10
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 200 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from zoneinfo import ZoneInfo
from app.main import build_state
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone)
for k, e in s.events.items():
    if "Q06" in e.where and e.when.start.astimezone(tz).date().isoformat() == "2026-11-21":
        print("estadia", e.state.value, "chave ...", str(k)[-4:], "evento ...", e.event_id[-6:])
        for nome in [a for a in dir(s) if any(x in a for x in ("bloq", "titular", "block", "suspen", "tentativ"))]:
            col = getattr(s, nome, None)
            if isinstance(col, dict):
                for kk, v in col.items():
                    if e.event_id in str(kk) or str(k) in str(kk) or e.who.person in str(kk):
                        print("  ", nome, "->", {a: str(b)[:60] for a, b in (v.items() if isinstance(v, dict) else [("v", v)]) if a not in ("nome", "name", "documento", "cpf")})
PY
echo fim
