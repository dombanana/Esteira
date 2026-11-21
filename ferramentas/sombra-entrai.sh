#!/usr/bin/env bash
# Gera e envia um pedido SO LEITURA da sombra do entrai (V1.1 Acesso e fechaduras, Dom 21/11 18h38 "Alta").
# Le SO o banco da V1.0 -- nenhuma chamada a TTLock (regra do Dom, 21/11: "temos webhooks. Nao e para sair consultando").
# Uso: ferramentas/sombra-entrai.sh   (a partir da raiz do repositorio Esteira)
set -eu
cd "$(dirname "$0")/.."
git pull -q
n=$(ls pedidos | grep -oE '^[0-9]+' | sort -n | tail -1); n=$(printf "%03d" $((10#$n + 1)))
quando=$(TZ=America/Sao_Paulo date +%Y%m%d-%H%M)
f="pedidos/$n-sombra-entrai-$quando-leitura.sh"
cat > "$f" <<'EOF'
#!/usr/bin/env bash
# SO LEITURA -- sombra do entrai (V1.1). Le o banco da V1.0 (estadias, plano de portas da V1.0, o que ja foi gravado
# e as aberturas que o webhook trouxe). NENHUMA chamada a TTLock. Sem nome, sem senha, sem codigo de reserva: a estadia
# vira um resumo de 10 letras. Credencial lida = so portas e ids (a senha em claro nao e aberta).
set -u
exec 2>&1
cd /opt/PMS-Banana-AI/SISTEMA/api || exit 1
echo "versao: $(grep -oP 'VERSAO = "\K[^"]+' app/versao.py)"
sudo -n /opt/esteira-nuvem/com-segredos env PMS_TRANSCRICAO_AQUECER=off PYTHONDONTWRITEBYTECODE=1 timeout 300 ../.venv/bin/python -u - <<'PY' 2>&1 | grep -vE '^(WARNING|INFO|DEBUG)'
import hashlib, json, os
from dataclasses import replace
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from app.main import build_state
from app import worker as W
from app.reservation.doors import ARMARIO, door_plan
from app.reservation.intents import OPERATIONAL_INSTANCES
from app.core.event import EventState
st = build_state(); s = st.store; tz = ZoneInfo(s.timezone); agora = datetime.now(timezone.utc)
H = lambda x: hashlib.sha256(("entrai|" + str(x)).encode()).hexdigest()[:10]
locks = W.house_locks(st)
sem_gw = {x.strip().upper() for x in os.environ.get("PMS_TTLOCK_SEM_GATEWAY", "PANELAS").split(",") if x.strip()}
print(f"AGORA;{agora.isoformat()}")
print(f"CFG;quarto_desde;{os.environ.get('PMS_QUARTO_DESDE', '')}")
print(f"CFG;sem_gateway;{','.join(sorted(sem_gw))}")
print(f"CFG;senha_dias;{os.environ.get('PMS_SENHA_DIAS', '1')}")
for k, v in sorted(locks.rooms.items()): print(f"MAPA;quartos;{k};{v}")
for k, v in sorted(locks.armarios.items()): print(f"MAPA;armarios;{k};{v}")
for k, v in sorted(locks.common.items()): print(f"MAPA;comuns;{k};{v}")
lookup = W._event_lookup(st)
def climbing(table):                      # copia de worker.build_adapters.climbing (a cama sobe a arvore)
    def find(space):
        for sid in s.inventory.lineage(space):
            if sid in table:
                return table[sid]
        return None
    return find
room_lock = lambda sp: locks.rooms.get(sp) or climbing(locks.rooms)(sp)
arm_lock = lambda sp: locks.armarios.get(sp) or climbing(locks.armarios)(sp)
common = {k: v for k, v in locks.common.items() if k.upper() not in sem_gw}
vault = s.vault
suspensos = getattr(s, "access_suspensions", {}) or {}
n_est = 0
for key, e in list(s.events.items()):
    if e.instance in OPERATIONAL_INSTANCES or e.state not in (EventState.CONFIRMED, EventState.IN_PROGRESS):
        continue
    if e.when.end < agora - timedelta(days=1) or e.when.start > agora + timedelta(days=8):
        continue
    try:
        info = lookup(e.event_id)
    except Exception as erro:
        print(f"ERRO;{H(e.event_id)};lookup {type(erro).__name__}"); continue
    h = H(e.event_id); n_est += 1
    libs = set(info.get("liberties") or ())
    versao = "smart" if "kitchen" in libs else "hostel"
    jan = {r: list(v) for r, v in (info.get("janelas") or {}).items()}
    print(";".join(["EST", h, str(info["space"]), ",".join(info.get("camas_do_quarto") or ()), info["checkin"],
                    info["checkout"], versao, ",".join(info.get("extra_roles") or ()), ",".join(info.get("sem_roles") or ()),
                    json.dumps(jan), e.state.value, "1" if e.event_id in suspensos else "0"]))
    doors = door_plan(str(info["space"]), date.fromisoformat(info["checkin"]), date.fromisoformat(info["checkout"]),
                      libs, room_lock=room_lock, armario_lock=arm_lock, common=common,
                      extra_roles=info.get("extra_roles") or ())
    # copia fiel de make_ttlock_adapter._ajustar_portas e _armarios_do_quarto_inteiro (V1.0, adapters.py)
    sem = set(info.get("sem_roles") or ())
    aj = []
    for d in doors:
        if d.role in sem: continue
        par = (info.get("janelas") or {}).get(d.role)
        if par:
            try: d = replace(d, starts=datetime.fromisoformat(str(par[0])), ends=datetime.fromisoformat(str(par[1])))
            except (TypeError, ValueError, IndexError): pass
        aj.append(d)
    camas = tuple(info.get("camas_do_quarto") or ())
    base = next((d for d in aj if d.role == ARMARIO), None)
    if len(camas) >= 2 and base is not None:
        ja = {d.lock_id for d in aj if d.lock_id is not None}
        for cama in camas:
            lk = locks.armarios.get(cama)
            if lk is None or lk in ja: continue
            ja.add(lk); aj.append(replace(base, role=f"{ARMARIO}+{cama}", lock_id=lk))
    for d in aj:
        print(f"P10;{h};{d.role};{d.lock_id if d.lock_id is not None else '-'};{d.starts.isoformat()};{d.ends.isoformat()}")
    ref = f"cred:{e.event_id}"
    if ref in vault:
        try:
            cred = dict(vault._read(ref))
        except Exception:
            cred = {}
        if not cred.get("revoked"):
            for item in str(cred.get("doors", "")).split(";"):
                if item.count(":") == 2:
                    role, lk, pwd = item.split(":")
                    tipo = "id" if pwd.isdigit() else ("existente" if pwd == "existente" else
                                                       ("offline" if pwd.startswith("offline") else "outro"))
                    print(f"FEITO;{h};{role};{lk};{tipo}")
desde = agora - timedelta(days=7)
n_ab = 0
for ev in st.inbox:
    if getattr(ev, "partner", "") != "ttlock" or getattr(ev, "event_type", "") != "abertura_com_senha":
        continue
    p = dict(getattr(ev, "payload", {}) or {})
    try:
        quando = datetime.fromisoformat(str(p.get("at")))
    except (TypeError, ValueError):
        continue
    if quando < desde or not p.get("event_id"):
        continue
    n_ab += 1
    print(f"AB;{p.get('lock_id')};{quando.isoformat()};{H(p['event_id'])}")
print(f"RESUMO;estadias={n_est};aberturas7d={n_ab}")
PY
echo "fim"
EOF
chmod +x "$f"; git add "$f"; git commit -qm "$(basename "$f") (sombra entrai, so leitura, sem TTLock)"; git push -q
echo "$f"
