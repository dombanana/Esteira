#!/usr/bin/env bash
set -u
exec 2>&1
git -C /opt/pms-banana-ai-fila.git log --format='%h %H %s' -3 main 2>&1 | cut -c1-160
git -C /opt/pms-banana-ai-fila.git for-each-ref --sort=-committerdate --format='%(refname:short) %(objectname:short)' refs/heads 2>&1 | head -5
