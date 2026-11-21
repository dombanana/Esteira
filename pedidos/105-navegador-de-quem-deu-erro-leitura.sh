#!/usr/bin/env bash
# SO LEITURA: o navegador (User-Agent) de quem teve "erro mostrado na pagina" hoje -- so o UA e a rota, sem IP completo.
set -u
exec 2>&1
L=$(ls /var/log/nginx/*access*.log 2>/dev/null | head -5); echo "logs: $L"
for ip in 191.38.17.123 177.73.42.222 187.90.202.141 177.54.156.201 179.151.175.14; do
  echo "== ${ip%.*}.x"
  grep -h "^$ip " $L 2>/dev/null | grep -E '/api/h/[A-Z0-9]+(/erro)? ' | awk -F'"' '{print $2" | "$6}' | sed -E 's#/api/h/[A-Z0-9]+#/api/h/<link>#' | sort | uniq -c | head -4
done
echo fim
