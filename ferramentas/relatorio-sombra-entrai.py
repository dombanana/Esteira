#!/usr/bin/env python3
"""Relatorio da sombra do entrai (V1.1): le a saida mais nova (ou a indicada) e compara com o plano da V1.1."""
import glob, os, sys
sys.path.insert(0, "/home/claude/v11/entrai")
from entrai import sombra  # noqa: E402
arqs = sorted(glob.glob(os.path.join(os.path.dirname(__file__), "..", "saidas", "*sombra-entrai*")))
alvo = sys.argv[1] if len(sys.argv) > 1 else (arqs[-1] if arqs else None)
if not alvo:
    sys.exit("nenhuma saida da sombra do entrai ainda")
texto = open(alvo, encoding="utf-8").read()
print(os.path.basename(alvo))
print(sombra.relatorio(texto))
for l in texto.splitlines():
    if l.startswith(("RESUMO", "ERRO", "Traceback", "versao")) or "Error" in l:
        print(l)
