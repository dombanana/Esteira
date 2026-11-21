#!/usr/bin/env bash
# SO LEITURA (codigo): o que a V1.0 chama na TTLock, como le o aviso, e as rotinas de conferencia (docstrings)
set -u
exec 2>&1
A=/opt/PMS-Banana-AI/SISTEMA/api/app
echo "===== chamadas a API TTLock (caminhos)"; grep -rnoE "\"/v3/[a-zA-Z/]+\"|'/v3/[a-zA-Z/]+'" $A --include=*.py | grep -v tests | sort -t: -k3 | awk -F: '{print $1": "$3}' | sort | uniq -c
echo "===== class TtlockClient (defs)"; grep -n "class Ttlock\|    def " $A/reservation/adapters.py | sed -n '/Ttlock/,$p' | head -60
echo "===== openings()"; grep -n "def openings" -A45 $A/luz/service.py
for f in contingencia contingencia_offline espelho_portas varredura_portas sentinela_senhas entry_log saida_porta ficha_na_porta remote continuacao canceladas; do
  echo "===== $f (docstring + defs)"; python3 - "$A/reservation/$f.py" <<'PY'
import ast,sys
src=open(sys.argv[1]).read(); t=ast.parse(src)
print((ast.get_docstring(t) or "")[:2500])
for n in t.body:
    if isinstance(n,(ast.FunctionDef,ast.ClassDef)):
        d=(ast.get_docstring(n) or "").split("\n")[0][:160]
        print(f"  def {n.name}: {d}")
PY
done
echo "===== worker: chamadas periodicas a TTLock"; grep -n "lock_client\.\|list_records\|records_every\|segundos()\|SENTINELA\|VARREDURA" $A/worker.py | head -40
echo fim
