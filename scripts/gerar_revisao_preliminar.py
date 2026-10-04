#!/usr/bin/env python3
"""Materializa a primeira revisão por ocorrência dos JSON preservados.

As listas de exceções são decisões feitas após leitura dos trechos e contêineres
dos cinco apps. A classificação é preliminar e exige segundo avaliador.
"""
import csv
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/avaliacao/resultados_iniciais"
OUTPUT = ROOT / "docs/avaliacao"
PROJECTS = ["rssbud", "hundred-challenge-ios", "maeuse-ios", "capelo", "expense-tracker"]

# Números de ordem no report.json de cada projeto. Conferidos com arquivo e contexto.
FONT_DECORATIVE_TEXT = {
    "hundred-challenge-ios": {1, 7, 22, 33, 38, 45, 62, 66, 76, 79, 88, 98, 117, 131},
    "maeuse-ios": {30, 31},
}
FONT_UNCERTAIN_TEXT = {"hundred-challenge-ios": {52, 95}, "capelo": {28}}
FONT_OTHER = {
    "rssbud": {1: "pertinente", 11: "falso positivo", 12: "pertinente", 15: "inconclusivo",
               21: "pertinente", 22: "pertinente", 46: "falso positivo", 48: "falso positivo", 61: "pertinente"},
    "hundred-challenge-ios": {28: "pertinente", 60: "pertinente", 93: "pertinente",
                              117: "falso positivo", 135: "falso positivo"},
    "maeuse-ios": {34: "pertinente", 55: "pertinente", 64: "pertinente"},
}

IMAGE_REDUNDANT = {
    "rssbud": {5, 8, 16, 23, 25, 27, 30, 33, 36, 38, 43, 45, 47, 49, 51, 53, 55, 57},
    "hundred-challenge-ios": {11, 18, 29, 69, 72, 84, 129, 134, 139},
    "maeuse-ios": {44, 45, 46, 48, 54, 60, 61, 65},
    "capelo": {19, 25, 32},
    "expense-tracker": {3, 4, 6},
}
IMAGE_PERTINENT = {
    "rssbud": {3, 17},
    "hundred-challenge-ios": {48},
    "maeuse-ios": {71, 73, 75, 77, 79},
}

COLOR_FALSE = {"hundred-challenge-ios": {74}, "capelo": {15}, "maeuse-ios": {72}}
COLOR_PERTINENT = {"maeuse-ios": {43, 83}}
GESTURE_FALSE = {"expense-tracker": {1, 2, 5}, "capelo": {14, 36}, "maeuse-ios": {9, 12}}
GESTURE_PERTINENT = {"capelo": {7}, "maeuse-ios": {25}}


def font_receiver(diagnostic):
    excerpt = diagnostic.get("sourceExcerpt") or ""
    before = [part["text"].strip() for part in diagnostic.get("sourceContext") or []
              if part["line"] < diagnostic["line"]]
    nearby = excerpt if re.search(r"\b(Text|Image|TextField|SecureField|Label)\s*\(", excerpt) else (before[-1] if before else "")
    for kind in ("Image", "TextField", "SecureField", "Text", "Label"):
        if re.search(r"\b" + kind + r"\s*\(", nearby):
            return kind
    return "outro"


def decision(project, ordinal, item):
    rule = item["ruleIdentifier"]
    if rule == "SAC003":
        kind = font_receiver(item)
        if ordinal in FONT_DECORATIVE_TEXT.get(project, set()):
            return "falso positivo", "Emoji ou símbolo decorativo com texto equivalente no mesmo componente; o tamanho fixo não limita texto informativo."
        if ordinal in FONT_UNCERTAIN_TEXT.get(project, set()):
            return "inconclusivo", "Símbolo/emoji em espaço visual restrito; falta confirmar função e comportamento com Dynamic Type."
        status = FONT_OTHER.get(project, {}).get(ordinal)
        if status is None:
            status = "falso positivo" if kind == "Image" else "pertinente" if kind in {"Text", "TextField", "SecureField", "Label"} else "inconclusivo"
        if status == "falso positivo":
            return status, "O modificador dimensiona Image/ícone, não uma fonte de texto; a justificativa de Dynamic Type da SAC003 não se aplica a esta ocorrência."
        if status == "pertinente":
            receiver = kind if kind != "outro" else "componente que contém texto no contexto inspecionado"
            return status, f"Fonte .system(size:) aplicada a {receiver}; texto pode não acompanhar Dynamic Type. Risco no código, sem afirmar truncamento em execução."
        return status, "O tipo ou a função do conteúdo não se resolve só pelo trecho; verificar componente e texto renderizado."
    if rule == "SAC001":
        return "pertinente", "Botão iconográfico sem nome de ação explícito no trecho; revisar anúncio real, pois SF Symbol pode fornecer nome automático insuficiente ou adequado."
    if rule == "SAC002":
        if ordinal in IMAGE_REDUNDANT.get(project, set()):
            return "falso positivo", "Imagem decorativa, invisível ou acompanhada por texto que transmite a mesma informação no contêiner inspecionado."
        if ordinal in IMAGE_PERTINENT.get(project, set()):
            return "pertinente", "Ícone sinaliza ação/estado no componente; descrição ou ocultação explícita merece revisão, mesmo que haja semântica herdada."
        return "inconclusivo", "A finalidade informativa ou decorativa da imagem não foi resolvida no código; requer inspeção da árvore acessível."
    if rule == "SAC004":
        return "inconclusivo", "Campo interativo tem largura explícita de 40 pt, mas altura, padding e região final de toque dependem do layout renderizado."
    if rule == "SAC005":
        if ordinal in COLOR_FALSE.get(project, set()):
            return "falso positivo", "A mudança é realce visual redundante/de pressão, ou o estado já aparece em texto/número; não é informação comunicada só por cor neste trecho."
        if ordinal in COLOR_PERTINENT.get(project, set()):
            return "pertinente", "Estado/atualização é destacado pela cor sem alternativa semântica explícita no componente; verificar anúncio e pista visual adicional."
        return "inconclusivo", "A cor varia, mas há outras pistas próximas; a equivalência do significado exige inspeção do fluxo."
    if rule == "SAC008":
        if ordinal in GESTURE_FALSE.get(project, set()):
            return "falso positivo", "Gesto atua como conveniência para foco, teclado ou fechar camada que tem botão equivalente; não é a única ação essencial."
        if ordinal in GESTURE_PERTINENT.get(project, set()):
            return "pertinente", "Gesto ativa função do componente sem papel/ação acessível equivalente no trecho; verificar navegação por VoiceOver."
        return "inconclusivo", "Não foi possível confirmar se o gesto é a única forma de executar a ação."
    if rule == "SAC009":
        return "pertinente", "Faixa de Dynamic Type limita explicitamente o tamanho em xxxLarge; não alcança as categorias de acessibilidade."
    return "inconclusivo", "Revisão pendente de contexto."


def main():
    rows = []
    for project in PROJECTS:
        data = json.loads((SOURCE / project / "report.json").read_text())
        for ordinal, item in enumerate(data["diagnostics"], 1):
            status, reason = decision(project, ordinal, item)
            assert status in {"pertinente", "falso positivo", "inconclusivo"}
            relative = item["filePath"].split(f"/ProjetosExternos/{project}/", 1)[-1]
            rows.append({"projeto": project, "id": f"{project}-{ordinal:03d}", "regra": item["ruleIdentifier"],
                         "arquivo": relative, "linha": item["line"], "coluna": item["column"],
                         "trecho": item.get("sourceExcerpt") or "", "classificacao_preliminar": status,
                         "justificativa": reason, "nivel_evidencia": "código", "validacao_humana": "pendente",
                         "barreira_em_execucao": "não verificada"})
    destination = OUTPUT / "revisao_preliminar.csv"
    with destination.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(len(rows), "avisos classificados em", destination)


if __name__ == "__main__":
    main()
