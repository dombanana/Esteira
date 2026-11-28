#!/bin/bash
# So leitura: o que a esteira do PC esta rodando agora (sem argumentos sensiveis).
ps -eo pid,etimes,user,comm,args --sort=-etimes 2>/dev/null | grep -E "021-v20|runuser|python3 -" | grep -v grep | cut -c1-160 | head -20
