#!/bin/bash
ps -eo pid,etimes,user,args 2>/dev/null | grep -E "python3 -|runuser" | grep -v grep | cut -c1-120
journalctl -u dbv11-integracao --since "-10min" --no-pager 2>/dev/null | tail -8 | sed -E "s/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<email>/g" | cut -c1-200
