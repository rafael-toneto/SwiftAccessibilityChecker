# Reprodução da avaliação

Ponto de partida: macOS 26.6.2 arm64, Xcode 27.0 (`27A266a`), Swift 6.4, Python 3, 2026-10-04. A ferramenta usa SwiftSyntax 602.0.0. A versão inicial dos relatórios é o commit `6c6115e8fbeaad208084e89e65fc75570cec5885`; a correção posterior é `07c2b19`. As saídas arquivadas identificam comando, arquivo analisado, versão e eventuais erros; pequenas diferenças de ordenação/data podem ocorrer em reexecuções.

## Preparar os cinco checkouts irmãos

Na pasta `/Users/rafaeltoneto/Documents/TCC`, criar `ProjetosExternos` e clonar os URLs da tabela de [`AMOSTRA.md`](AMOSTRA.md), com estes nomes de pasta: `rssbud`, `hundred-challenge-ios`, `maeuse-ios`, `capelo`, `expense-tracker`. Posicionar cada clone exatamente no SHA da tabela com `git -C ProjetosExternos/NOME checkout --detach SHA`. Confirmar licença e `git rev-parse HEAD`. O runner confere novamente cada SHA e o SHA-256 dos 112 arquivos listados em [`amostra.json`](amostra.json) antes de analisar. Os arquivos externos **não entram no repositório do TCC**.

## Executar a versão ajustada

Na raiz `SwiftAccessibilityChecker`:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test --scratch-path /tmp/sac-build
swift build --scratch-path /tmp/sac-build --product swift-accessibility-checker
BIN_DIR=$(swift build --scratch-path /tmp/sac-build --show-bin-path)
python3 scripts/avaliar_externos.py "$BIN_DIR/swift-accessibility-checker" /tmp/sac-reexecucao-ajustada
python3 scripts/gerar_revisao_preliminar.py
python3 scripts/sintetizar_avaliacao.py
```

O runner chama **somente** o executável do checker, passando a lista fechada de arquivos do app; não executa scripts dos projetos clonados. Preserva por projeto `command.json`, `report.json`, `stdout.txt`, `stderr.txt`, além de `execucao.json`. `--format json --output` não modifica os arquivos analisados. As duas últimas linhas regeneram as decisões preliminares e a matriz a partir dos relatórios **iniciais arquivados**; classificações humanas futuras devem ser guardadas em cópia, sem sobrescrever o registro inicial.

## Repetir a versão inicial sem alterar o checkout principal

Criar um worktree temporário no mesmo nível dos clones (o código da ferramenta, não terceiros):

```bash
git worktree add --detach ../CheckerInicial 6c6115e8fbeaad208084e89e65fc75570cec5885
cd ../CheckerInicial
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift build --scratch-path /tmp/sac-build-inicial --product swift-accessibility-checker
BIN_DIR=$(swift build --scratch-path /tmp/sac-build-inicial --show-bin-path)
python3 scripts/avaliar_externos.py "$BIN_DIR/swift-accessibility-checker" /tmp/sac-reexecucao-inicial
```

Comparar contagens e localizações com [`resultados_iniciais`](resultados_iniciais/) e [`resultados_apos_ajuste`](resultados_apos_ajuste/). O runner verifica commit e hash antes de qualquer execução; falha explícita significa que a amostra mudou. Os JSON contêm caminhos absolutos desta máquina: a localização se compara pelo sufixo relativo do projeto, linha, coluna e regra.

## Exemplos controlados e interfaces

[`Demos/README.md`](../../Demos/README.md) descreve como preparar o simulador, compilar seis schemes e gerar seis relatórios. [`Reports/VALIDACAO.md`](../../Demos/Reports/VALIDACAO.md) registra a execução feita. Os builds externos foram feitos com `xcodebuild -project PROJETO.xcodeproj -scheme SCHEME -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /Users/rafaeltoneto/Documents/TCC/AvaliacaoBuild/NOME CODE_SIGNING_ALLOWED=NO build`; o comando completo e o resultado estão no início/fim de cada [log](evidencias/). Esses diretórios de DerivedData permanecem fora do Git. Para Mäuse, as capturas documentam a introdução e as Configurações em `large` e `accessibility-extra-extra-extra-large`, depois de relançar o app no simulador de iPhone 17 Pro (iOS 26.5). Inspeção por VoiceOver requer aparelho físico e não foi realizada.

Para refazer a comparação visual de Mäuse após o build, usar o mesmo simulador ou criar outro iPhone compatível. Com o simulador já iniciado, os comandos relevantes são:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID=D9DB7D76-3CCA-489B-B409-9E1506DF4746
xcrun simctl install "$UDID" /Users/rafaeltoneto/Documents/TCC/AvaliacaoBuild/maeuse-ios/Build/Products/Debug-iphonesimulator/Maeuse.app
xcrun simctl ui "$UDID" content_size large
xcrun simctl launch "$UDID" com.michaeldiestelberg.maeuse
xcrun simctl io "$UDID" screenshot /tmp/maeuse-large.png
xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
xcrun simctl terminate "$UDID" com.michaeldiestelberg.maeuse
xcrun simctl launch "$UDID" com.michaeldiestelberg.maeuse
xcrun simctl io "$UDID" screenshot /tmp/maeuse-max.png
xcrun simctl ui "$UDID" content_size large
```

Antes da captura, aguardar a tela de introdução concluir sua animação. Para reproduzir as capturas de Configurações, tocar em `Get Started`, tocar em `Settings`, capturar com `simctl io ... screenshot` em `large`, mudar para `accessibility-extra-extra-extra-large`, encerrar/abrir o app novamente, reabrir `Settings` e capturar. A navegação foi feita no Device Hub. Nele, a árvore acessível indicou `Settings` como botão e sua ativação abriu a folha. O Accessibility Inspector foi apontado para `Simulator > Mäuse`; as opções `Element Description`, `Contrast`, `Hit Region`, `Element Detection`, `Clipped Text`, `Traits` e `Dynamic Type` estavam ativas. Acionar `Run Audit` não exibiu resultado na interface nesta sessão; não interpretar a ausência de saída como aprovação. As capturas não medem regiões de toque nem substituem VoiceOver.

## Integridade e limites da repetição

Conferir que `matriz_por_regra.csv` tenha 45 linhas de dados e que o somatório seja 333 na versão inicial. O script de síntese verifica esse total contra os cinco JSON. Os relatórios posteriores devem totalizar 273. A revisão manual é uma interpretação do código, não um resultado produzido automaticamente pelo checker; para reproduzir sua **avaliação**, um segundo avaliador deve ler cada ocorrência em `revisao_preliminar.csv` e registrar concordância/discordância conforme o instrumento.
