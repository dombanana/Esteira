#!/usr/bin/env bash
# 033 -- so leitura: permissoes da pasta dos segredos e com que usuario o worker roda (para o arquivo do calendario)
set -u
exec 2>&1
stat -c '%n %U:%G %a' /etc/pms-banana-ai 2>&1
systemctl show pms-banana-ai-worker.service -p User -p Group -p EnvironmentFiles -p ReadOnlyPaths -p ProtectSystem 2>&1 | sed 's/secrets[^ ]*/secrets(...)/'
id pms 2>&1
cd /tmp; sudo -n /opt/esteira-nuvem/com-segredos test -r /etc/pms-banana-ai/airbnb-ical.json && echo "pms le o arquivo: sim" || echo "pms le o arquivo: NAO"
