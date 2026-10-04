#!/usr/bin/env python3
"""Consolida a matriz da execução inicial e da revisão preliminar."""
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "docs/avaliacao"
review = list(csv.DictReader((root / "revisao_preliminar.csv").open(encoding="utf-8")))
sample = json.loads((root / "amostra.json").read_text())
projects = [entry["id"] for entry in sample["projects"]]
rules = [f"SAC{i:03d}" for i in range(1, 10)]
groups = defaultdict(list)
for row in review:
    groups[row["projeto"], row["regra"]].append(row)

matrix = []
for project in projects:
    for rule in rules:
        counts = Counter(r["classificacao_preliminar"] for r in groups[project, rule])
        matrix.append({"projeto": project, "regra": rule, "avisos": sum(counts.values()),
                       "pertinentes": counts["pertinente"], "falsos_positivos": counts["falso positivo"],
                       "inconclusivos": counts["inconclusivo"]})

with (root / "matriz_por_regra.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(matrix[0]), lineterminator="\n")
    writer.writeheader()
    writer.writerows(matrix)

expected = {p: len(json.loads((root / "resultados_iniciais" / p / "report.json").read_text())["diagnostics"])
            for p in projects}
assert all(sum(r["avisos"] for r in matrix if r["projeto"] == p) == expected[p] for p in projects)
assert len(review) == sum(expected.values()) == 333
print("Matriz: 45 células, 333 diagnósticos, totais conferidos com os JSON iniciais.")
