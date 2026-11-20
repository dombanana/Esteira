"""Relatorio da sombra dos ventiladores (V1.1 Automacao 1.1.0): junta as linhas SOMBRA das saidas e roda
agenda.simular_dia com o padrao do Dom nos quartos Q07-Q10. Uso: python3 ferramentas/relatorio-sombra-vent.py [AAAA-MM-DD ...]"""
import glob, sys
from collections import defaultdict
sys.path.insert(0, "/home/claude/v11/automacao")
from automacao import agenda

dias = set(sys.argv[1:])
por_dia = defaultdict(list)
for f in sorted(glob.glob("saidas/*sombra-vent-*-leitura.sh.txt")):
    for l in open(f, encoding="utf-8"):
        if not l.startswith("SOMBRA;"):
            continue
        _, quando, q, oc, lig, vel, fora = l.strip().split(";")
        dia, hora = quando.split()
        if dias and dia not in dias:
            continue
        por_dia[dia].append({"hora": hora, "quarto": q, "ocupado": oc == "1", "ligado": lig == "True",
                             "vel": None if vel in ("None", "?") else int(vel), "fora": fora == "1", "lido": lig != "None"})
cfg = dict(agenda.PADRAO_DOM, quartos=["Q07", "Q08", "Q09", "Q10"])
N = agenda.NOMES_VEL
for dia, leit in sorted(por_dia.items()):
    print(f"\n== {dia} ({len(leit)} leituras)")
    muda = 0
    for r in agenda.simular_dia(cfg, leit):
        hoje = N[r["vel"] or 0] if r["ligado"] else "desligado"
        faria = N[r["faria"][1] or 0] if r["faria"][0] else "desligado"
        obs = " (sem leitura do aparelho)" if not r["lido"] else (" (fora do ar)" if r["fora"] else "")
        muda += r["muda"]
        print(f"{r['hora']} {r['quarto']} {'ocupado' if r['ocupado'] else 'vazio  '} | hoje {hoje:9} | agenda faria {faria:9}"
              f" | {'MUDARIA' if r['muda'] else 'igual  '} | {r['motivo']}{obs}")
    print(f"-- mudaria {muda} de {len(leit)} leituras")
