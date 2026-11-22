#!/usr/bin/env bash
# SO LEITURA: (1) o arquivo visual da pagina do hospede chega ao celular? status e tamanho por dia no nginx;
# (2) erros js da pagina do hospede por dia (log da API, sem link); (3) o ramo socorro (correcao testada) ainda
# encaixa em cima do main que esta no ar.
set -u; exec 2>&1
echo "== casa.js no nginx (status, ultimos 3 dias)"
for L in /var/log/nginx/access.log /var/log/nginx/access.log.1; do [ -r "$L" ] || continue
  grep -h "/visual/casa.js" "$L" | awk '{print substr($4,2,11), $9}' | sort | uniq -c | tail -12; done
zcat -f /var/log/nginx/access.log.2.gz 2>/dev/null | grep -h "/visual/casa.js" | awk '{print substr($4,2,11), $9}' | sort | uniq -c | tail -6
echo "== casa.js: tamanho e cache"
ls -la /opt/PMS-Banana-AI/SISTEMA/api/app/panel/static/visual/casa.js 2>/dev/null || find /opt/PMS-Banana-AI/SISTEMA -name casa.js -path "*visual*" -exec ls -la {} \; | head -3
grep -rn "visual" /etc/nginx/sites-enabled/ 2>/dev/null | head -5
echo "== erros mostrados na pagina (API), por dia e onde"
journalctl -u pms-banana-ai --since "3 days ago" --no-pager 2>/dev/null | grep -o "erro mostrado na pagina: .*" | sed -E 's/link=[^ ]+/link=***/; s/chave=([a-z_]+).*/chave=\1/' | sort | uniq -c | sort -rn | head -8
journalctl -u pms-banana-ai --since "3 days ago" --no-pager 2>/dev/null | grep "erro mostrado na pagina" | awk '{print $1, $2}' | uniq -c | tail -5
echo "== ramo socorro na fila"
F=/opt/pms-banana-ai-fila.git
git -C $F log --oneline -1 refs/heads/main; git -C $F log --oneline -3 refs/heads/socorro 2>/dev/null
git -C $F merge-base --is-ancestor refs/heads/main eec6840b 2>/dev/null && echo "eec6840b esta EM CIMA do main atual" || echo "eec6840b NAO esta em cima do main atual"
git -C $F diff --stat refs/heads/main eec6840b 2>/dev/null | tail -8
ls -la /root/relatorios/ 2>/dev/null | grep -i "sc\|socorro" | tail -3
echo fim
