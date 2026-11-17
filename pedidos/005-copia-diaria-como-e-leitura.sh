#!/usr/bin/env bash
# 005 -- como e a copia diaria do sistema hoje (unidade, script sem segredos, o que guarda, quantos dias, ultima rodada)
set -u
exec 2>&1
systemctl cat pms-banana-ai-copia-diaria.service pms-banana-ai-copia-diaria.timer 2>&1 | grep -vE '^\s*$' | cut -c1-160
X=$(systemctl show pms-banana-ai-copia-diaria.service -p ExecStart --value | grep -oE 'path=[^ ;]+' | head -1 | cut -d= -f2)
echo "== script: $X"
for f in $(systemctl show pms-banana-ai-copia-diaria.service -p ExecStart --value | grep -oE '/[^ ;]+\.(sh|py)' | sort -u); do
  echo "--- $f ($(wc -l < "$f" 2>/dev/null) linhas)"
  grep -vE '^\s*$' "$f" 2>/dev/null | grep -viE 'senha|password|token|secret|key=' | cut -c1-170 | head -90
done
echo "== ultima rodada:"; systemctl show pms-banana-ai-copia-diaria.service -p ExecMainStartTimestamp -p ExecMainStatus --value | paste -sd' '
journalctl -u pms-banana-ai-copia-diaria.service --since "3 days ago" --no-pager -o short-iso 2>/dev/null | tail -12 | cut -c1-200
echo "== arquivos em /var/backups/pms-banana-ai (fora wifi):"
find /var/backups/pms-banana-ai -maxdepth 1 -type f -printf '%TY-%Tm-%Td %TH:%TM  %s  %f\n' 2>/dev/null | sort | tail -20 | awk '{printf "   %s %s  %.1f MB  %s\n",$1,$2,$3/1048576,$4}'
