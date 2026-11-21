"""Junta as saidas da sombra diaria do catalogo por ID (pedidos *-sombra-catalogo-*) e resume: e-mails lidos, tipos
iguais, campos diferentes, decisoes da V1.1 e encaixe igual/diferente. Uso: python3 ferramentas/relatorio-sombra-catalogo.py"""
import glob
from collections import Counter
vistos, leitor, encaixe, dias = set(), Counter(), Counter(), Counter()
difs, dif_encaixe = [], []
for f in sorted(glob.glob("saidas/*-sombra-catalogo-*-leitura.sh.txt")):
    for l in open(f, encoding="utf-8"):
        l = l.strip()
        if l in vistos or not (l.startswith("LEITOR;") or l.startswith("ENCAIXE;")):
            continue                                   # as janelas se sobrepoem: cada linha conta uma vez
        vistos.add(l)
        p = l.split(";")
        if p[0] == "LEITOR":
            dias[p[1][:10]] += 1
            leitor["e-mails"] += 1
            leitor["tipo igual" if p[2] == p[3] else "tipo DIFERENTE"] += 1
            leitor[f"V1.1: {p[5]}"] += 1
            if p[4] != "-":
                leitor["reserva com campo diferente"] += 1; difs.append(l)
        else:
            if len(p) >= 6 and p[5] in ("IGUAL", "DIFERENTE"):
                encaixe[p[5]] += 1
                if p[5] == "DIFERENTE": dif_encaixe.append(l)
            else:
                encaixe["alarme / fora"] += 1
print("dias:", dict(sorted(dias.items())))
print("leitor:", dict(leitor))
print("encaixe:", dict(encaixe))
for l in difs + dif_encaixe:
    print(" ", l)
