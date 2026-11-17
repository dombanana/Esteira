#!/usr/bin/env bash
# 001 -- primeira leitura pela esteira na nuvem (17/11/2026): quem roda, versao, saude e as rotinas do servidor.
set -u
exec 2>&1
echo "usuario: $(whoami) · maquina: $(hostname) · $(date -u +%FT%TZ)"
echo "/health: $(curl -s -o /dev/null -m 10 -w '%{http_code}' http://127.0.0.1:8090/health)"
echo "servicos: API $(systemctl is-active pms-banana-ai.service) · worker $(systemctl is-active pms-banana-ai-worker.service) · nuvem $(systemctl is-active esteira-nuvem.timer)"
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
from datetime import datetime, timezone
from app.main import build_state
from app.versao import VERSAO
st = build_state(); agora = datetime.now(timezone.utc)
vivas = [e for e in st.store.events.values() if e.state.value in ("confirmed", "in_progress") and e.when.start <= agora < e.when.end]
print(f"versao {VERSAO} · estadias valendo agora: {len(vivas)}")
PY
echo "--- diario do worker (30 min): espelho, sentinela, conferencia, erros"
journalctl -u pms-banana-ai-worker --since "30 min ago" --no-pager -o short-iso 2>/dev/null | grep -iE "portas x painel|sentinela|conferencia|Traceback|ERROR" | tail -6 | cut -c1-180
echo "fim do teste"
