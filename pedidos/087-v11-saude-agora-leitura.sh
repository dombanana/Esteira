#!/usr/bin/env bash
# SO LEITURA: saude da V1.1 agora (servicos, reinicios, enderecos, memoria). Sem chave, sem dado de hospede.
set -u
exec 2>&1
for s in dbv11-integracao dbv11-equipe dbv11-automacao dbv11-pegai; do
  echo "$s: $(systemctl is-active $s) | reinicios=$(systemctl show -p NRestarts --value $s) | desde=$(systemctl show -p ActiveEnterTimestamp --value $s) | mem=$(( $(systemctl show -p MemoryCurrent --value $s 2>/dev/null || echo 0) / 1048576 ))MB"
  echo "  erros 24h: $(journalctl -u $s --since '-24h' -p err --no-pager -q 2>/dev/null | wc -l)"
done
for h in equipe integracao automacao loja; do
  echo "https://$h.dombanana.tech -> $(curl -s -o /dev/null -w '%{http_code}' --max-time 8 https://$h.dombanana.tech/)"
done
echo "V1.0: api=$(systemctl is-active pms-banana-ai) worker=$(systemctl is-active pms-banana-ai-worker)"
free -m | head -2
echo fim
