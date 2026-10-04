#!/usr/bin/env python3
"""Gera relatórios das seis versões e confere os resultados usando a CLI real."""
from argparse import ArgumentParser
from html import escape
from pathlib import Path
from urllib.parse import quote
import json
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "ListaCompras": {"SAC001": 1, "SAC004": 1, "SAC006": 1},
    "LeituraFacil": {"SAC002": 1, "SAC003": 1, "SAC009": 1},
    "MinhaRotina": {"SAC005": 1, "SAC007": 1, "SAC008": 1},
}
BUNDLE_FILES = ("report.html", "report.md", "report.txt", "report.json", "warnings.txt")
LIMITATION = (
    "Zero avisos significa que os arquivos analisados não acionaram as nove regras "
    "implementadas. Não certifica acessibilidade: valide a interface em execução "
    "com VoiceOver, tamanhos de texto ampliados e Accessibility Inspector."
)


def report_link(result, filename):
    """Links relativos continuam funcionando quando a pasta Reports é movida."""
    return quote(f'{result["app"]}-{result["variant"]}/{filename}', safe="/")


def render_index(results):
    total = sum(item["report"]["summary"]["totalIssues"] for item in results)
    cards = []
    for result in results:
        report = result["report"]
        count = report["summary"]["totalIssues"]
        severity = report["summary"].get("bySeverity", {})
        rules = ", ".join(sorted(report["summary"]["byRule"]))
        status = f"{count} avisos para revisar" if count else "Nenhum aviso nestes arquivos"
        variants = {"ComProblemas": "Com problemas intencionais", "Corrigido": "Versão corrigida"}
        downloads = " · ".join(
            f'<a href="{escape(report_link(result, filename), quote=True)}">{label}</a>'
            for filename, label in [
                ("report.md", "Markdown"), ("report.txt", "Texto"),
                ("report.json", "JSON"), ("warnings.txt", "Warnings do Xcode"),
            ]
        )
        cards.append(f"""
        <article class="card">
          <div class="eyebrow">{escape(variants.get(result['variant'], result['variant']))}</div>
          <h2>{escape(result['app'])}</h2>
          <p class="status">{escape(status)}</p>
          <p class="meta">{len(report['analyzedFiles'])} arquivos analisados</p>
          <dl class="priorities" aria-label="Avisos por impacto esperado">
            <div><dt>Alta</dt><dd>{severity.get('high', 0)}</dd></div>
            <div><dt>Média</dt><dd>{severity.get('medium', 0)}</dd></div>
            <div><dt>Baixa</dt><dd>{severity.get('low', 0)}</dd></div>
          </dl>
          <p class="rules">Regras acionadas: {escape(rules or 'nenhuma')}</p>
          <a class="button" href="{escape(report_link(result, 'report.html'), quote=True)}"
             aria-label="Abrir relatório de {escape(result['app'], quote=True)} — {escape(result['variant'], quote=True)}">Abrir relatório →</a>
          <p class="downloads">Outros formatos: {downloads}</p>
          <p class="date">Gerado em {escape(report.get('generatedAt', 'data não informada'))}</p>
        </article>""")
    return f"""<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>Relatórios de acessibilidade · Aplicativos de demonstração</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; color: #182738; background: #f3f6fa; font: 1rem/1.65 system-ui, sans-serif; }}
    main {{ max-width: 1120px; margin: auto; padding: 42px 24px; }}
    .eyebrow {{ color: #41566f; font-size: .82rem; font-weight: 700; letter-spacing: .03em; }}
    h1 {{ max-width: 820px; margin: 10px 0 16px; font-size: clamp(2rem, 4vw, 3rem); line-height: 1.15; }}
    h2 {{ margin: 6px 0 14px; font-size: 1.5rem; }}
    .intro {{ max-width: 820px; font-size: 1.1rem; }}
    .guide {{ background: #e6eef8; border-left: 4px solid #26598b; padding: 16px 22px; margin: 28px 0; }}
    .guide p, .guide ol {{ margin: 8px 0; }}
    .overview {{ margin-bottom: 22px; }}
    .grid {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 20px; }}
    .card {{ background: white; border: 1px solid #c9d4e1; border-radius: 14px; padding: 26px; min-width: 0; }}
    .status {{ font-size: 1.2rem; font-weight: 700; margin: 0; }}
    .meta, .date {{ color: #45586c; font-size: .88rem; margin: 5px 0; }}
    .priorities {{ display: flex; flex-wrap: wrap; gap: 28px; margin: 18px 0; }}
    .priorities dt {{ color: #45586c; font-size: .86rem; }}
    .priorities dd {{ font-size: 1.45rem; font-weight: 700; margin: 0; }}
    .rules, .downloads {{ font-size: .9rem; overflow-wrap: anywhere; }}
    a {{ color: #15558b; text-underline-offset: 3px; }}
    a:focus-visible {{ outline: 3px solid #8a4100; outline-offset: 4px; }}
    .button {{ display: inline-block; background: #15558b; color: white; padding: 10px 16px; border-radius: 7px; font-weight: 650; text-decoration: none; }}
    .button:hover {{ background: #103e65; }}
    footer {{ border-top: 1px solid #c9d4e1; margin-top: 30px; padding-top: 18px; color: #45586c; font-size: .9rem; }}
    @media (max-width: 650px) {{ .grid {{ grid-template-columns: 1fr; }} main {{ padding: 28px 16px; }} .card {{ padding: 22px; }} }}
    @media print {{ body {{ background: white; }} main {{ padding: 0; }} .card {{ break-inside: avoid; }} .button {{ color: #15558b; background: white; border: 1px solid; }} }}
  </style>
</head>
<body><main>
  <header>
    <div class="eyebrow">SWIFT ACCESSIBILITY CHECKER · DEMONSTRAÇÃO</div>
    <h1>O que precisa de atenção em cada aplicativo</h1>
    <p class="intro">Compare as versões dos três aplicativos. Cada relatório mostra onde o aviso está no código, quem pode ser afetado e como revisar a implementação.</p>
  </header>
  <section class="guide" aria-labelledby="how-to">
    <h2 id="how-to">Como usar esta comparação</h2>
    <ol>
      <li>Abra a versão com problemas e comece pelos avisos de prioridade alta.</li>
      <li>Leia a localização, a explicação e a sugestão de ajuste de cada aviso.</li>
      <li>Compare com a versão corrigida e confira o comportamento no simulador.</li>
    </ol>
    <p>{escape(LIMITATION)}</p>
  </section>
  <p class="overview"><strong>{len(results)} versões analisadas · {total} avisos no total.</strong> As prioridades indicam impacto esperado e ajudam a organizar a revisão.</p>
  <section class="grid" aria-label="Relatórios por aplicativo e versão">{''.join(cards)}
  </section>
  <footer>
    <p>Esta página e os relatórios abrem localmente, sem servidor. Para compartilhar, mantenha toda a pasta <code>Reports</code>, incluindo as seis subpastas.</p>
    <p><a href="RESUMO.md">Resumo em Markdown</a> · Os arquivos podem conter caminhos e trechos do código analisado; confira o conteúdo antes de compartilhar fora do time.</p>
  </footer>
</main></body>
</html>
"""


def render_summary(results):
    rows = []
    for result in results:
        summary = result["report"]["summary"]
        rules = ", ".join(sorted(summary["byRule"])) or "Nenhuma"
        rows.append(
            f'| {result["app"]} | {result["variant"]} | {summary["totalIssues"]} | '
            f'{rules} | [Abrir]({report_link(result, "report.html")}) |'
        )
    return (
        "# Resultados da análise estática\n\n"
        "[Abrir o painel de relatórios](index.html). Gerados pela CLI real, em uma análise por target. "
        "Cada pasta contém HTML, Markdown, texto, JSON e warnings do Xcode.\n\n"
        "| App | Versão | Avisos | Regras | Relatório |\n"
        "| --- | --- | ---: | --- | --- |\n" + "\n".join(rows) + "\n\n" + LIMITATION + "\n"
    )


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("checker", type=Path, help="caminho para o executável swift-accessibility-checker")
    args = parser.parse_args()
    reports = ROOT / "Reports"
    reports.mkdir(parents=True, exist_ok=True)
    results = []
    failures = []
    for app, rules in EXPECTED.items():
        for variant in ("ComProblemas", "Corrigido"):
            files = [ROOT / app / "Shared/App.swift", ROOT / app / variant / "ContentView.swift"]
            basename = f"{app}-{variant}"
            bundle = reports / basename
            # A mesma análise alimenta todos os formatos, mantendo posições e contagens consistentes.
            subprocess.run(
                [str(args.checker.resolve()), "--report-directory", str(bundle), *map(str, files)],
                check=True,
            )
            for filename in BUNDLE_FILES:
                if not (bundle / filename).is_file():
                    raise RuntimeError(f"{basename}: o checker não gerou {filename}")
            report = json.loads((bundle / "report.json").read_text(encoding="utf-8"))
            # Mantém os caminhos usados pelo roteiro e por consumidores anteriores.
            shutil.copyfile(bundle / "report.json", reports / f"{basename}.json")
            shutil.copyfile(bundle / "warnings.txt", reports / f"{basename}.txt")
            target_rules = rules if variant == "ComProblemas" else {}
            actual = report["summary"]["byRule"]
            if actual != target_rules:
                failures.append(f"{app}/{variant}: esperado {target_rules}, obtido {actual}")
            if set(report["analyzedFiles"]) != set(map(str, files)):
                failures.append(f"{app}/{variant}: conjunto de arquivos analisados inesperado")
            for diagnostic in report["diagnostics"]:
                if diagnostic["filePath"] != str(files[1]) or not diagnostic.get("sourceExcerpt"):
                    failures.append(f"{app}/{variant}: diagnóstico sem localização/trecho correto")
            results.append({"app": app, "variant": variant, "report": report})
            count = report["summary"]["totalIssues"]
            names = ", ".join(sorted(actual)) or "Nenhuma regra acionada"
            print(f"{app:14} {variant:12} {count} aviso(s) — {names}")

    (reports / "RESUMO.md").write_text(render_summary(results), encoding="utf-8")
    (reports / "index.html").write_text(render_index(results), encoding="utf-8")
    if failures:
        print("\nResultados diferentes dos esperados para a demonstração:", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("\nOK: nove regras cobertas; versões corrigidas e arquivos compartilhados sem avisos.")
    print(f"Painel de relatórios: {reports / 'index.html'}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Não foi possível gerar ou validar os relatórios: {error}", file=sys.stderr)
        sys.exit(1)
