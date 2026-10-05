# Swift Accessibility Checker

Ferramenta de análise estática para antecipar riscos de acessibilidade em código SwiftUI.
O checker percorre a árvore sintática com SwiftSyntax, aplica nove regras e gera warnings
clicáveis no Xcode e relatórios em português para orientar a revisão do time. O HTML
mostra o que ajustar, onde fica o trecho e como testar a correção. Os diagnósticos são indícios para
revisão: não certificam conformidade nem substituem Accessibility Inspector, testes com
tecnologias assistivas, especialistas ou pessoas usuárias.

As regras `SAC001` a `SAC005` correspondem ao conjunto inicial proposto na Tabela 6.1
do paper do projeto. As regras seguintes ampliam o mesmo recorte de Apple HIG e WCAG
com verificações objetivas que podem ser feitas no código-fonte.

## Regras

| ID | Regra | O que é sinalizado | Referência principal |
| --- | --- | --- | --- |
| `SAC001` | Missing Label | `Button` composto apenas por `Image`, ou inicializado com `systemImage` e título literal vazio, sem `accessibilityLabel` ativa | [Apple `accessibilityLabel`](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)), [WCAG 2.2 - 1.1.1 e 4.1.2](https://www.w3.org/TR/WCAG22/) |
| `SAC002` | Image Accessibility | `Image` sem label, representação acessível ou tratamento decorativo explícito | [Apple HIG - VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover), [WCAG 2.2 - 1.1.1](https://www.w3.org/TR/WCAG22/#non-text-content) |
| `SAC003` | Fixed Font Size | `.font(.system(size:))` ou `.font(Font.system(size:))`, com risco para Dynamic Type | [Apple HIG - Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [WCAG 2.2 - 1.4.4](https://www.w3.org/TR/WCAG22/#resize-text) |
| `SAC004` | Small Touch Target | controle com dimensão literal em `frame` abaixo do limiar de revisão de 44 pt | [Apple HIG - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [WCAG 2.2 - 2.5.5 e 2.5.8](https://www.w3.org/TR/WCAG22/#target-size-enhanced) |
| `SAC005` | Color Only Information | cor condicional em forma ou imagem sem indício de alternativa que também varie com o estado | [Apple HIG - Color](https://developer.apple.com/design/human-interface-guidelines/color), [WCAG 2.2 - 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color) |
| `SAC006` | Empty Accessibility Metadata | `accessibilityLabel`, `accessibilityValue` ou `accessibilityHint` literal vazio | [Apple - Accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility), [WCAG 2.2 - 4.1.2](https://www.w3.org/TR/WCAG22/#name-role-value) |
| `SAC007` | Hidden Interactive Control | controle SwiftUI padrão, diretamente ou em um contêiner, sob `.accessibilityHidden(true)` | [Apple `accessibilityHidden`](https://developer.apple.com/documentation/swiftui/view/accessibilityhidden(_:)), [WCAG 2.2 - 4.1.2](https://www.w3.org/TR/WCAG22/#name-role-value) |
| `SAC008` | Gesture Only Interaction | `onTapGesture` ou `onLongPressGesture` sem papel/ação acessível equivalente | [Apple - Accessible controls](https://developer.apple.com/documentation/swiftui/accessible-controls), [WCAG 2.2 - 2.1.1 e 4.1.2](https://www.w3.org/TR/WCAG22/) |
| `SAC009` | Restricted Dynamic Type | `dynamicTypeSize` fixo ou faixa que impede chegar ao maior tamanho de acessibilidade | [Apple `dynamicTypeSize`](https://developer.apple.com/documentation/swiftui/view/dynamictypesize(_:)-26aj0), [Apple HIG - Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [WCAG 2.2 - 1.4.4](https://www.w3.org/TR/WCAG22/#resize-text) |

`SAC004` usa 44 x 44 pt como limiar de revisão por ser o tamanho padrão recomendado
pela Apple no iOS/iPadOS e o alvo do critério WCAG 2.2 2.5.5 (nível AAA). Não é tratado
como uma afirmação de falha definitiva: padding, composição e layout em runtime podem
alterar a área final de toque. A regra só avalia dimensões numéricas explicitamente
limitadas por `width`, `height`, `maxWidth` ou `maxHeight`.

`SAC005` também é exploratória. Ela procura uma troca condicional de cor em formas e
imagens e aceita como indícios uma descrição acessível dinâmica, um overlay textual ou
iconográfico que também varie, ou a mudança do próprio símbolo. Uma descrição ou um
ícone constante não suprime o warning. A semântica visual completa depende da interface
renderizada e precisa de revisão humana.

## Requisitos

- Swift 6.2
- macOS 13 ou posterior

O package usa SwiftSyntax 602.0.0, correspondente à linha da toolchain Swift 6.2.

## Comece pelo relatório

No terminal, dentro da pasta deste package:

```bash
swift build
swift run swift-accessibility-checker --report-directory Relatorios Fixtures
open Relatorios/report.html
```

Para analisar um projeto real, substitua `Fixtures` pela pasta de fontes Swift do app
ou passe somente os arquivos do target. Evite incluir dependências, cópias de testes e
versões antigas do mesmo código. A execução não modifica os arquivos analisados.

`--report-directory` faz uma única análise e grava estes cinco arquivos:

| Arquivo | Quando usar |
| --- | --- |
| `report.html` | Revisão no navegador, com resumo, filtros e explicações dos avisos. Abre offline. |
| `report.md` | Anexar a uma tarefa, revisão de código ou documentação do time. |
| `report.txt` | Ler as explicações diretamente no terminal ou em qualquer editor. |
| `report.json` | Integrações, automações e comparação de resultados. |
| `warnings.txt` | Mensagens no formato reconhecido pelo Xcode. |

O HTML, Markdown e texto apresentam cada aviso em português: problema, impacto,
arquivo/linha/coluna, trecho encontrado, orientação de ajuste, exemplo ilustrativo e
validação manual. Os exemplos precisam ser adaptados ao contexto do aplicativo; não
são alterações automáticas no código. Comece pela prioridade alta e confirme os avisos
que dependem do layout ou do comportamento em execução.

## Outros modos de uso

```bash
# Ajuda e opções disponíveis
swift run swift-accessibility-checker --help

# Warnings clicáveis no Xcode (formato padrão)
swift run swift-accessibility-checker Fixtures/InaccessibleExample.swift

# Somente um formato, salvo em arquivo
swift run swift-accessibility-checker --format html --output Relatorios/revisao.html Fixtures
swift run swift-accessibility-checker --format markdown --output Relatorios/revisao.md Fixtures
swift run swift-accessibility-checker --format text Fixtures
swift run swift-accessibility-checker --format json --output Relatorios/revisao.json Fixtures

# Vários arquivos explícitos, como no Build Tool Plugin
swift run swift-accessibility-checker ViewA.swift ViewB.swift

# Testes da ferramenta
swift test

# Testes de aceitação da CLI, passando o executável compilado
python3 scripts/test_cli.py /caminho/para/swift-accessibility-checker
```

Warnings seguem o formato reconhecido pelo Xcode:

```text
<caminho>:<linha>:<coluna>: warning: <mensagem> [<regra>] [<severidade>]
```

Warnings não alteram o código de saída. Erros de uso, caminhos inválidos, falhas de
leitura ou de geração do relatório retornam um código diferente de zero. Quando parte
dos arquivos pode ser analisada, o relatório preserva os resultados e identifica os
arquivos que ficaram de fora. Não interprete um relatório parcial como uma análise
completa do projeto.

## Relatórios e severidade

O formato padrão é `xcode`, preservando a integração com o terminal e o Issue Navigator.
O formato `json` usa um esquema versionado (`1.1`) e inclui:

- entradas e arquivos efetivamente analisados;
- total de diagnósticos e contagens por regra e severidade;
- regra, título, descrição, severidade, arquivo, linha e coluna;
- trecho da linha sinalizada, justificativa, sugestão e referências normativas;
- contexto de linhas próximas ao aviso no campo opcional `sourceContext`;
- data da execução em ISO 8601.
- problemas de descoberta/leitura em `analysisIssues`, quando houver.

Os campos anteriores do JSON continuam disponíveis. Os textos dos diagnósticos nesse
formato preservam o contrato existente; a orientação em português é apresentada nos
formatos HTML, Markdown e texto.

As severidades representam o impacto esperado para priorização e avaliação acadêmica:

| Severidade | Interpretação |
| --- | --- |
| `high` | risco de tornar um controle ou informação indisponível para tecnologia assistiva |
| `medium` | risco relevante que depende parcialmente do contexto ou da interface renderizada |
| `low` | alerta exploratório ou boa prática que requer revisão humana |

Todas são apresentadas como `warning` no Xcode. A análise é estática e indicativa; por
isso, uma severidade alta não é convertida em erro de compilação nem certifica uma
violação definitiva.

Os relatórios para leitura humana priorizam os avisos de maior impacto. JSON e warnings
continuam ordenados por arquivo, linha, coluna e regra. Essa ordenação e as chaves JSON
ordenadas facilitam comparações entre execuções; a data muda a cada análise.

## Instalação local em um projeto Xcode

1. Abra o projeto consumidor no Xcode.
2. Use **File > Add Package Dependencies...**.
3. Escolha **Add Local...** e selecione a pasta deste package:

   ```text
   /caminho/para/SwiftAccessibilityChecker
   ```

4. Selecione o target do aplicativo e abra **Build Phases**.
5. Adicione uma fase **Run Build Tool Plug-ins**, caso ela ainda não exista.
6. Dentro dessa fase, pressione `+` e selecione
   **SwiftAccessibilityCheckerPlugin**.
7. Compile o target e autorize o plugin quando o Xcode solicitar confiança.

Não adicione `SwiftAccessibilityCheckerCore` ou
`SwiftAccessibilityCheckerAnalyzer` em **Frameworks, Libraries, and Embedded
Content**. Esses módulos são ferramentas internas executadas no Mac host e não devem
ser vinculados ao binário iOS. O manifesto não os expõe como produtos para evitar essa
associação acidental.

O plugin recebe somente os arquivos Swift pertencentes ao target em que foi
adicionado. Projetos com mais de um target precisam adicionar o plugin a cada target
que deve ser analisado.

Quando o build executa o checker, ele analisa os arquivos Swift do target e exibe
diagnósticos clicáveis no Issue Navigator:

```text
/path/ProfileView.swift:18:9: warning: Fixed font size may not support Dynamic Type [SAC003] [medium]
```

O plugin também gera os cinco formatos na pasta `SwiftAccessibilityReport` do seu
diretório de trabalho de build. No **Report Navigator** (**⌘9**), abra o log da fase
do checker e procure `SwiftAccessibilityChecker: relatório disponível em`. Copie o
caminho exibido e abra o `report.html` no navegador, por exemplo com `open "caminho"`.

Esses relatórios são intermediários privados do build: podem ser removidos ao limpar
os artefatos do Xcode. Para guardar uma revisão ou compartilhar com o time, copie os
arquivos desejados ou gere uma pasta própria pela CLI com `--report-directory`.
Os relatórios contêm caminhos e trechos do código; confira o conteúdo antes de
compartilhá-los fora do time.

O plugin não declara o HTML, JSON e demais relatórios como recursos do target, para
evitar que sejam incluídos no aplicativo distribuído. Algumas versões do Xcode podem
exibir um aviso de infraestrutura por essa fase não declarar arquivos de saída. Esse
aviso não é um diagnóstico `SAC`. Para uma análise explícita, use a CLI; no Xcode,
um **Product > Clean Build Folder** seguido de build também permite refazer a execução.

A primeira execução pode ser mais demorada porque o Xcode precisa compilar a ferramenta
de host e sua dependência de SwiftSyntax; as execuções seguintes reutilizam esse build.

## Limitações conhecidas

- A análise não resolve tipos, aliases, valores calculados ou extensões de componentes.
- Contraste real, ordem do VoiceOver, truncamento e dimensões finais exigem execução ou
  inspeção da interface renderizada e ficam fora deste núcleo estático.
- Metadados e dimensões dinâmicos são ignorados quando o valor não pode ser comprovado
  sintaticamente.
- Alguns warnings, sobretudo `SAC004`, `SAC005`, `SAC008` e `SAC009`, dependem do
  contexto e devem ser avaliados como alertas de revisão.

## Uso por outro Swift Package

Um package consumidor pode ativar o plugin em targets específicos:

```swift
let package = Package(
    dependencies: [
        .package(
            path: "../SwiftAccessibilityChecker"
        )
    ],
    targets: [
        .target(
            name: "MyTarget",
            plugins: [
                .plugin(
                    name: "SwiftAccessibilityCheckerPlugin",
                    package: "SwiftAccessibilityChecker"
                )
            ]
        )
    ]
)
```

Quando este repositório for publicado e versionado, o `path` pode ser substituído por
uma dependência `url` com uma versão ou tag.
