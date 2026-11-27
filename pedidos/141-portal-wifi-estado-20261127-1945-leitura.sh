#!/bin/bash
# So leitura: estado do portal do Wi-Fi (servidor de hotspot) e do PC da casa visto pelo roteador.
cd /opt/PMS-Banana-AI/SISTEMA/api && sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 120 ../.venv/bin/python -u - <<'PY'
import os
from app.network.routeros import RouterOS
r = RouterOS.from_environment(os.environ)
for s in r._records("ip/hotspot"):
    print("servidor", s.get("name"), "desligado=" + str(s.get("disabled")))
print("logados agora:", len(r._records("ip/hotspot/active")))
print("hosts vistos:", len(r._records("ip/hotspot/host")))
pc = [l for l in r._records("ip/dhcp-server/lease") if l.get("address") == "10.10.10.5"]
for l in pc:
    print("PC da casa (10.10.10.5): status=" + str(l.get("status")), "visto ha", l.get("last-seen"))
if not pc:
    print("PC da casa: sem reserva no DHCP")
PY
