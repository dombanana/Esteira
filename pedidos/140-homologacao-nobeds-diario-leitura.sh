#!/usr/bin/env bash
# SO LEITURA -- complemento do 090: o filtro do diario voltou vazio (suspeita: --since com fuso nao aceito).
set -u
exec 2>&1
echo "== teste do --since com fuso (primeiras 3 linhas, sem filtro)"
journalctl -u pms-banana-ai-worker --since "2026-11-26 23:50:00 America/Sao_Paulo" --no-pager -q 2>&1 | head -3 | cut -c1-60
echo "== diario desde 27/11 02:50 UTC (= 26/11 23:50 SP), filtrado, max 30"
journalctl -u pms-banana-ai-worker --since "2026-11-27 02:50:00 UTC" --no-pager -q 2>&1 \
  | grep -iE "Nobeds desligada|nobeds|reconciliacao|vigia do Nobeds|caixa das reservas|calend" \
  | sed -E 's/HM[A-Z0-9]{8}/HM******/g; s/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[a-z]{2,}/<email>/g' | cut -c1-220 | head -30
echo "== quantas linhas o worker escreveu desde entao"
journalctl -u pms-banana-ai-worker --since "2026-11-27 02:50:00 UTC" --no-pager -q 2>&1 | wc -l
echo "== quando o worker subiu pela ultima vez"
systemctl show pms-banana-ai-worker -p ActiveEnterTimestamp 2>&1
echo "== fim"
