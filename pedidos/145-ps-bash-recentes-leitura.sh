#!/bin/bash
# So leitura: processos iniciados nos ultimos 15 min (sem argumentos longos).
ps -eo pid,ppid,etimes,user,args --sort=etimes 2>/dev/null | awk '$3<900' | cut -c1-140 | grep -v "ps -eo\|awk\|cut -c" | head -30
