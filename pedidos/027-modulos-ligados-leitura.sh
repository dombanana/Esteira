#!/usr/bin/env bash
# 027 -- so leitura: quais modulos tem efeito externo ligado (lista de nomes, nao e segredo) e o modo do e-mail do Airbnb
set -u
exec 2>&1
cd /tmp
sudo -n /opt/esteira-nuvem/com-segredos bash -c 'echo "PMS_LIVE_MODULES=${PMS_LIVE_MODULES:-(vazio)}"; echo "PMS_AIRBNB_EMAIL_RESERVAS=${PMS_AIRBNB_EMAIL_RESERVAS:-(nao definido = sombra)}"; echo "PMS_RESERVAS_IMAP_PASTAS=${PMS_RESERVAS_IMAP_PASTAS:-(padrao)}"'
