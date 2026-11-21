#!/usr/bin/env bash
exec 2>&1
journalctl -u pms-banana-ai --since "-10h" --no-pager -q | grep "erro mostrado na pagina" | tail -30
echo fim
