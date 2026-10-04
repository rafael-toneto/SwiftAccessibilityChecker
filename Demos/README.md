# Aplicativos para demonstrar o SwiftAccessibilityChecker

Três protótipos de iPhone, com uma tela principal cada, preparados para uma demonstração prática do TCC. Cada app possui uma versão **ComProblemas** e uma **Corrigido**, em targets separados. Os exemplos são funcionais, usam dados fictícios e mantêm seu estado apenas durante a sessão: não acessam a internet nem salvam dados.

Comece por **[Demo.xcworkspace](Demo.xcworkspace)**. Ele reúne os três projetos e seus seis schemes no mesmo workspace, facilitando a troca de exemplos e o reaproveitamento da configuração de pacotes. O **[ROTEIRO.md](ROTEIRO.md)** traz a fala sugerida e as ações para uma conversa de 10–15 minutos.

## O que demonstrar

| App | Funcionalidades | Regras exercitadas | Com problemas / corrigido |
| --- | --- | --- | ---: |
| **ListaCompras** | Ajustar unidades de leite, remover e adicionar o item. | `SAC001`: botão só com ícone; `SAC004`: área pequena; `SAC006`: valor acessível vazio. | **3 / 0** |
| **LeituraFacil** | Ler um boletim fictício e marcar uma leitura como salva. | `SAC002`: imagem sem descrição; `SAC003`: fonte fixa; `SAC009`: limite de tamanho de texto. | **3 / 0** |
| **MinhaRotina** | Alternar o estado de um hábito, mostrar um lembrete na tela e abrir uma dica. | `SAC005`: estado só por cor; `SAC007`: controle oculto da acessibilidade; `SAC008`: ação apenas por gesto. | **3 / 0** |

As contagens esperadas, verificadas pela CLI real, são **nove avisos nas versões com problemas**, cobrindo as nove regras, e **zero avisos SAC nas versões corrigidas**. Comece pelo **[painel de relatórios](Reports/index.html)**: ele compara as seis versões e abre o relatório de cada uma. O [resumo em Markdown](Reports/RESUMO.md) traz as mesmas contagens. O histórico da validação dos builds e do simulador está em [Reports/VALIDACAO.md](Reports/VALIDACAO.md).

Zero avisos significa que esses arquivos não acionaram as regras implementadas. A análise não certifica acessibilidade nem substitui a verificação da interface com tecnologias assistivas.

## Preparar antes da reunião

É necessário ter o Xcode completo, uma toolchain que aceite o package Swift 6.2, Python 3 e um runtime de iOS instalado. Os apps têm iOS 17 como versão mínima. Se faltar um runtime, instale-o em **Xcode > Settings > Components**.

A primeira compilação pode precisar de internet para baixar as dependências do checker, incluindo SwiftSyntax, e pode demorar. Faça a preparação com antecedência:

```bash
cd "/caminho/SwiftAccessibilityChecker/Demos"
./scripts/analisar.sh
open Reports/index.html
./scripts/preparar.sh
./scripts/executar.sh ListaCompras ComProblemas
open Demo.xcworkspace
```

- `analisar.sh` compila a ferramenta, analisa uma única vez os arquivos de cada target, grava os cinco formatos de relatório e confere as contagens e regras esperadas. Ao terminar, imprime o caminho do painel HTML.
- `preparar.sh` compila os seis schemes para simulador e grava os logs em `Reports/build-*.log`. Os produtos ficam em `.DerivedData` nesta pasta.
- `executar.sh` instala e executa a versão escolhida no simulador exclusivo **SAC Demo**, criado automaticamente se necessário. Ele preserva os outros simuladores. Nesta instalação do Xcode 27, abre o **DeviceHub**: selecione **SAC Demo** para visualizar o iPhone. Em instalações com o app Simulator, abre essa janela.

Os scripts já tentam usar `/Applications/Xcode.app/Contents/Developer` quando o Xcode não está selecionado nas ferramentas de linha de comando. Não alteram o `xcode-select` global. Se o seu Xcode estiver em outro local, defina `DEVELOPER_DIR` para a pasta `Contents/Developer` dessa instalação antes de executar os scripts.

## Ler e compartilhar os relatórios

Abra `Reports/index.html` no navegador. Cada cartão mostra a versão analisada, as
prioridades, as regras encontradas e o link para o relatório. Dentro dele, cada aviso
explica o problema em português, mostra arquivo/linha/coluna e trecho do código, sugere
um ajuste com exemplo e indica como testar. Use os filtros do relatório para organizar
a revisão. As versões sem avisos continuam mostrando o escopo e os testes manuais.

Cada execução atualiza uma pasta por versão:

```text
Reports/
  index.html
  RESUMO.md
  ListaCompras-ComProblemas/
    report.html       # Leitura no navegador, offline
    report.md         # Revisões e tarefas do time
    report.txt        # Texto legível em qualquer editor
    report.json       # Dados para integrações
    warnings.txt      # Formato clicável no Xcode
  ListaCompras-Corrigido/
  LeituraFacil-ComProblemas/
  LeituraFacil-Corrigido/
  MinhaRotina-ComProblemas/
  MinhaRotina-Corrigido/
```

Os arquivos `Reports/App-Versao.json` e `Reports/App-Versao.txt` também são mantidos
como cópias do JSON e dos warnings, preservando os caminhos usados anteriormente.
Para compartilhar a comparação, leve toda a pasta `Reports` com as seis subpastas;
os links são relativos e funcionam sem servidor. Para enviar apenas uma revisão,
o `report.html` daquele target funciona sozinho. Revise caminhos e trechos antes
de compartilhar relatórios de projetos privados.

Para aplicar a ferramenta em outro projeto e recolher feedback do time, use o
**[guia do piloto](../docs/PILOTO.md)**.

## Usar no Xcode

1. Abra `Demo.xcworkspace` e aguarde a resolução dos pacotes.
2. Ao lado do botão de executar, selecione **ListaCompras-ComProblemas** e o simulador **SAC Demo** como destino. Se ainda não existir, execute o comando de abertura acima.
3. Use **⌘R** para compilar e rodar. O Xcode pode usar um cache de build diferente dos scripts; faça também uma execução pelo Xcode antes da reunião. Caso o Xcode peça confiança no plugin local, permita sua execução para usar a integração.
4. Abra o **Issue Navigator** com **⌘5** e procure os avisos com códigos `SAC001` a `SAC009`. Clique em um aviso para ir à linha do código.
5. Troque para **ListaCompras-Corrigido** e execute novamente. Repita com **LeituraFacil-ComProblemas / LeituraFacil-Corrigido** e **MinhaRotina-ComProblemas / MinhaRotina-Corrigido**.

O **SwiftAccessibilityCheckerPlugin já está ligado aos dois targets de cada projeto**. A dependência é local, no caminho `../..` relativo à pasta de cada projeto. Preserve a estrutura de pastas e o checker acima de `Demos`; não é necessário adicionar o pacote manualmente.

Cada target inclui `Shared/App.swift` e somente seu `ComProblemas/ContentView.swift` ou `Corrigido/ContentView.swift`. Por isso a versão corrigida pode ser analisada de forma independente. Analisar a pasta inteira de um app pela CLI incluiria as duas versões e continuaria encontrando os problemas intencionais. Use `analisar.sh` para obter a comparação correta.

O plugin também gera os cinco formatos na sua pasta de trabalho de build,
`SwiftAccessibilityReport`. No **Report Navigator** (**⌘9**), abra o log da fase do
checker e procure `SwiftAccessibilityChecker: relatório disponível em`; o caminho
aponta para o `report.html`. Esses arquivos intermediários podem desaparecer ao
limpar o build. Para uma revisão durável da demonstração, use `analisar.sh`.

As contagens da tabela são **avisos SAC**. O Xcode pode exibir outros avisos mesmo no target corrigido: no Xcode 27 foi observado um aviso de infraestrutura porque a fase do plugin não declara arquivos de saída, além de mensagens de AppIntents. O plugin mantém os relatórios fora dos recursos distribuídos com o app; esse aviso de infraestrutura pode permanecer. Ele não é um diagnóstico das nove regras. Se os avisos SAC não reaparecerem em um build incremental, use **Product > Clean Build Folder** (**⇧⌘K**) e compile novamente, ou rode `analisar.sh` para uma análise explícita.

## Comandos durante o ensaio

Todos os exemplos abaixo partem desta pasta:

```bash
cd "/caminho/SwiftAccessibilityChecker/Demos"
```

Para abrir uma versão já compilada:

```bash
./scripts/executar.sh ListaCompras ComProblemas
./scripts/executar.sh ListaCompras Corrigido
./scripts/executar.sh LeituraFacil ComProblemas
./scripts/executar.sh LeituraFacil Corrigido
./scripts/executar.sh MinhaRotina ComProblemas
./scripts/executar.sh MinhaRotina Corrigido
```

Execute um comando por vez, conforme o exemplo que deseja mostrar. A sintaxe é `./scripts/executar.sh App Versao`; os nomes aceitos são exatamente os acima. Se alterar o código, rode `preparar.sh` novamente antes de abrir pelos scripts, pois `executar.sh` usa os produtos já compilados.

Para comparar os textos da **LeituraFacil**, amplie a preferência de texto do simulador, abra cada versão e depois restaure:

```bash
./scripts/tamanho_texto.sh grande
./scripts/executar.sh LeituraFacil ComProblemas
# Observe a tela e depois compare:
./scripts/executar.sh LeituraFacil Corrigido
./scripts/tamanho_texto.sh normal
```

`grande` seleciona o primeiro tamanho de acessibilidade, facilitando a comparação sem rolar tanto; `normal` seleciona o tamanho padrão `large`. Para explorar o maior tamanho disponível, use `./scripts/tamanho_texto.sh maximo` e role a tela. A alteração afeta somente o simulador **SAC Demo**. Observe o título **“Um passeio ao ar livre”**, o parágrafo do meio e o trecho **“Antes de sair...”**: na versão com problemas, cada um responde de forma diferente à preferência de texto.

O funcionamento visível desses apps ajuda a explicar os casos. O checker analisa o código Swift e produz avisos antes dessa interação; ele não observa a tela em execução e não corrige os arquivos automaticamente.

Para rodar em um iPhone físico, selecione sua equipe em **Signing & Capabilities** de cada target desejado e escolha o aparelho como destino. A validação deste conjunto foi feita no simulador.
