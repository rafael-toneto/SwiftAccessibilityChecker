# Roteiro para demonstrar o TCC — 10 a 15 minutos

Este roteiro acompanha os três aplicativos desta pasta. Eles são pequenos exemplos de uso cotidiano; as falhas foram inseridas de propósito para exercitar as nove regras implementadas no SwiftAccessibilityChecker.

Abra `Demo.xcworkspace` para ter os três projetos disponíveis na mesma janela do Xcode. Cada projeto tem dois schemes: `Nome-ComProblemas` e `Nome-Corrigido`. Um **scheme** é a opção escolhida ao lado do botão de executar. Neste conjunto, cada scheme compila um target com seu próprio `ContentView.swift`. Assim, a versão corrigida é analisada separadamente da versão problemática.

## Antes da reunião

1. Siga o `README.md` desta pasta para preparar e verificar o ambiente. Compile uma vez cada versão e abra os aplicativos no simulador que pretende usar. A primeira preparação do checker pode demorar.
2. Deixe o Xcode aberto em `Demo.xcworkspace`, com o scheme `ListaCompras-ComProblemas` selecionado e o simulador **SAC Demo** como destino. Os scripts do README preparam esse simulador.
3. Deixe este roteiro e os relatórios da verificação à mão. Confira os resultados atuais; não dependa de baixar pacotes durante a reunião.
4. Ensaie a troca entre os dois schemes. Ao executar um novo scheme, confira o nome da versão na tela antes de comparar.

Não é necessário ativar o VoiceOver para mostrar que a análise estática funciona. Caso queira demonstrá-lo também, ensaie antes a navegação com o leitor de tela. O roteiro abaixo não pressupõe que essa validação tenha sido feita.

## 1. Apresentar a ideia — 1 minuto

Sugestão de fala:

> “Estou desenvolvendo uma ferramenta que lê o código de uma interface de iPhone e procura alguns padrões que podem dificultar o uso por pessoas com deficiência. Ela já identifica nove situações, mostra onde aparecem e sugere uma revisão. Preparei três aplicativos pequenos para visualizar esses casos.”

> “O aplicativo mostra o efeito para a pessoa usuária. O checker trabalha no código, antes de precisar usar todas as telas manualmente.”

Exemplo simples para contextualizar:

> “Um botão pode funcionar quando eu o vejo e toco nele, mas ainda precisar de uma descrição clara para quem usa um leitor de tela. Também pode ser pequeno demais para quem tem dificuldade de precisão no toque.”

## 2. Mostrar a ferramenta funcionando — 2 minutos

1. No projeto **ListaCompras**, escolha `ListaCompras-ComProblemas` e execute com **⌘R**.
2. Use a tela por alguns segundos para mostrar que é um aplicativo funcional.
3. Volte ao Xcode e abra o **Issue Navigator** com **⌘5**. Localize os avisos com identificadores `SAC001`, `SAC004` e `SAC006`.
4. Clique em um aviso para abrir a linha correspondente. Se os avisos não reaparecerem em uma compilação incremental, faça **Product > Clean Build Folder** (**⇧⌘K**) e compile novamente. Os comandos do README também permitem executar uma análise explícita.
5. Explique os elementos de um aviso: mensagem, arquivo e linha, código da regra e severidade. Todos aparecem como *warning*: a ferramenta permite continuar compilando o aplicativo.

Sugestão de fala:

> “Aqui não há uma mensagem escrita manualmente por mim dentro do aplicativo. A ferramenta leu este arquivo e gerou o aviso. Ao clicar, o Xcode me leva ao ponto que merece revisão.”

> “Esse identificador, como SAC001, permite acompanhar a mesma regra em outros arquivos e comparar os resultados depois da correção.”

## 3. Lista de compras — 2 a 3 minutos

**Situação cotidiana:** fazer uma pequena lista e acionar seus controles.

| Regra | O que explicar sem termos técnicos | O que comparar no código |
| --- | --- | --- |
| `SAC001` | Um botão mostrado só por um desenho precisa comunicar claramente sua ação. | Botão com apenas imagem; na correção, uma descrição acessível significativa ou um título compreensível. |
| `SAC004` | Uma área muito pequena exige precisão para tocar. | Dimensão explícita abaixo de 44 pontos; na correção, dimensão adequada. |
| `SAC006` | Não adianta reservar um campo para a descrição e deixá-lo vazio. | Metadado de acessibilidade vazio; na correção, texto útil ou remoção do modificador vazio. |

1. Na versão com problemas, toque no **+** para aumentar as unidades e compare sua área com a do **−**. Mostre os três avisos no Xcode.
2. Mostre o valor vazio ao lado de `accessibilityValue("")`. Explique que o número de unidades muda na tela, mas esse campo destinado à tecnologia assistiva foi deixado vazio.
3. Toque na lixeira para remover o leite e em **Adicionar leite** para recuperar o estado inicial.
4. Abra o `ContentView.swift` da versão corrigida e mostre a descrição **“Remover leite da lista”**. Não precisa ler toda a tela de código.
5. Selecione `ListaCompras-Corrigido`, compile e execute. Compare a interface e a análise dessa versão.

Sugestão de fala:

> “A tarefa continua sendo a mesma. As mudanças deixam mais clara a ação do botão e facilitam sua utilização. Algumas melhorias aparecem visualmente; outras são informações que a interface fornece às tecnologias assistivas.”

Cuidados na explicação: um símbolo do sistema pode receber uma descrição automática. Não afirme que todo botão sem descrição explícita será necessariamente mudo; o aviso sinaliza que a intenção da ação merece revisão. O limite de 44 pontos é um critério de revisão do checker, e a área efetiva de toque também depende do layout.

## 4. Leitura fácil — 2 a 3 minutos

**Situação cotidiana:** ler uma informação na tela e precisar de letras maiores.

No mesmo workspace, selecione o scheme `LeituraFacil-ComProblemas`.

| Regra | O que explicar sem termos técnicos | O que comparar no código |
| --- | --- | --- |
| `SAC002` | Uma imagem que transmite informação precisa de uma descrição; uma imagem só decorativa pode ser ignorada pelo leitor de tela. | Imagem sem tratamento; na correção, descrição útil ou indicação explícita de decoração. |
| `SAC003` | Uma letra com tamanho fixo pode não acompanhar a preferência da pessoa por letras maiores. | `.font(.system(size: ...))`; na correção, um estilo de texto que acompanha Dynamic Type, como `.body`. |
| `SAC009` | Mesmo com uma fonte adequada, o aplicativo pode impedir os maiores tamanhos de texto. | Restrição em `.dynamicTypeSize(...)`; na correção, remoção da limitação. |

1. Mostre o símbolo do sol e o texto **“Um passeio ao ar livre”** na versão com problemas. O clima é fictício; esse aplicativo não consulta uma previsão real.
2. Mostre os avisos das três regras no Xcode.
3. Compare com `LeituraFacil-Corrigido`.
4. Aumente o tamanho de texto no **SAC Demo** com `./scripts/tamanho_texto.sh grande`, executado da pasta `Demos` como descrito no README. Observe o título, o parágrafo intermediário e o trecho **“Antes de sair...”**: a versão com problemas mistura um título de tamanho fixo, um parágrafo que acompanha a preferência e um parágrafo com limite explícito. Compare novamente com a versão corrigida e role a tela quando necessário. Ao terminar, restaure com `./scripts/tamanho_texto.sh normal`.
5. Toque em **Salvar leitura** para mostrar uma funcionalidade simples. O estado fica somente na sessão atual; não é um app de armazenamento de artigos.

Sugestão de fala:

> “Dynamic Type é a preferência de tamanho de letra do iPhone. Aqui há dois problemas diferentes: definir uma fonte fixa e limitar o tamanho máximo permitido. A ferramenta identifica os dois padrões no código.”

> “A imagem também precisa de uma intenção clara: se informa algo, devemos descrevê-la; se só enfeita a tela, podemos evitar uma leitura desnecessária.”

O aviso é produzido pela análise do código. Aumentar o texto durante a execução ajuda a compreender o caso, mas não é o mecanismo que produz o diagnóstico.

## 5. Minha rotina — 2 a 3 minutos

**Situação cotidiana:** acompanhar um estado e acionar uma ação ou preferência.

No mesmo workspace, selecione o scheme `MinhaRotina-ComProblemas`.

| Regra | O que explicar sem termos técnicos | O que comparar no código |
| --- | --- | --- |
| `SAC005` | Se a única diferença entre dois estados é a cor, parte das pessoas pode não perceber a mudança. | Cor que varia com o estado; na correção, informação adicional que também varia. |
| `SAC007` | Um controle pode estar visível na tela e ao mesmo tempo ficar oculto das tecnologias assistivas. | `.accessibilityHidden(true)` em um controle ou no seu contêiner; na correção, o controle volta a ser exposto. |
| `SAC008` | Um texto que reage a um toque nem sempre comunica que pode ser acionado. | Gesto aplicado diretamente a uma visualização; na correção, botão padrão ou ação acessível equivalente. |

1. Toque em **Alterar estado** para mostrar a mudança de cor do círculo ao lado de **“Beber um copo de água”**.
2. Ative **Mostrar lembrete aqui**: uma mensagem aparece na própria tela. Esse protótipo não agenda notificações.
3. Toque em **Abrir dica**, feche o alerta com **Entendi** e mostre os avisos correspondentes no Xcode.
4. Execute `MinhaRotina-Corrigido` e compare o símbolo e o texto que agora acompanham a mudança de estado. Mostre também a substituição do gesto por `Button` no código.

Sugestão de fala:

> “A cor ajuda, mas a informação precisa continuar compreensível para quem não distingue essas cores. Na correção, o estado ganha outra forma de ser comunicado.”

> “Este outro caso mostra por que apenas olhar a tela não basta: um controle pode estar visível e funcionando, mas ter sido explicitamente escondido da acessibilidade.”

> “Usar um botão padrão também fornece ao sistema informações sobre a função daquele elemento.”

Não afirme que a ordem ou a leitura do VoiceOver foi validada apenas porque o warning desapareceu. Essa comparação exige uma verificação própria durante a execução.

## 6. Explicar o que já foi implementado — 1 a 2 minutos

Use esta sequência se a orientadora quiser entender a implementação. Não é necessário abrir todos os arquivos.

| Parte implementada | Explicação curta | Onde está no projeto do checker |
| --- | --- | --- |
| Descoberta dos arquivos | Recebe um arquivo ou uma pasta e encontra os arquivos Swift, ignorando pastas comuns de dependências e build. | `Sources/SwiftAccessibilityCheckerCore/SwiftFileDiscoverer.swift` |
| Leitura da estrutura do código | SwiftParser organiza o código em uma árvore; a análise visita essa estrutura para encontrar os padrões definidos. | `Sources/SwiftAccessibilityCheckerAnalyzer/SwiftSourceAnalyzer.swift` |
| Nove regras | Cada regra procura uma situação específica; o catálogo reúne as regras executadas. | `Sources/SwiftAccessibilityCheckerAnalyzer/AccessibilityRuleCatalog.swift` e os arquivos `...Rule.swift` |
| Diagnósticos | O resultado identifica regra, severidade, localização, trecho de código, justificativa, sugestão e referências. | `Sources/SwiftAccessibilityCheckerCore/Diagnostic.swift` e `Sources/SwiftAccessibilityCheckerAnalyzer/AccessibilityRuleDefinitions.swift` |
| Saída para Xcode | Formata os avisos para que possam ser exibidos e abertos no editor. | `Sources/SwiftAccessibilityCheckerReporter/XcodeReporter.swift` |
| Relatório JSON | Gera dados estruturados e contagens por regra e severidade, úteis para registrar resultados. | `Sources/SwiftAccessibilityCheckerReporter/JSONReporter.swift` e `Sources/SwiftAccessibilityCheckerCore/AnalysisResult.swift` |
| Linha de comando | Permite analisar arquivos e pastas fora do Xcode e salvar os relatórios. | `Sources/SwiftAccessibilityCheckerCLI/SwiftAccessibilityCheckerCommand.swift` |
| Plugin de build | Integra a execução da ferramenta ao build de um target Swift Package ou Xcode. | `Plugins/SwiftAccessibilityCheckerPlugin/plugin.swift` |
| Testes automatizados | Há casos que devem produzir aviso e casos que não devem, além de verificações dos relatórios e do catálogo de regras. | `Tests/SwiftAccessibilityCheckerTests/` |

Sugestão de fala:

> “Já estão implementados o leitor de código, as nove regras, a localização dos problemas e dois formatos de saída. O projeto também possui testes automatizados. Estes aplicativos complementam os testes com exemplos que podem ser usados e discutidos visualmente.”

Se mostrar um JSON, destaque só `summary.totalIssues`, `summary.byRule` e um diagnóstico com sua sugestão. Não precisa explicar a sintaxe inteira do arquivo.

As severidades ajudam a priorizar a revisão: `high` para possíveis barreiras de acesso a ações ou informação, `medium` para riscos relevantes que também dependem do contexto e `low` para um indício mais exploratório. Todas são warnings, e não notas finais de acessibilidade.

## 7. Delimitar o resultado e pedir feedback — 1 minuto

Sugestão de fala:

> “O resultado atual é uma ferramenta de apoio à revisão. Ela encontra padrões no código e antecipa possíveis problemas. Não avalia tudo: contraste real, ordem de navegação, leitura do VoiceOver e cortes de texto dependem da interface em execução. Zero avisos significa que essas regras não encontraram esses padrões, não que a acessibilidade esteja garantida.”

> “Separei versões com problemas e corrigidas para conseguirmos verificar se os diagnósticos aparecem nos exemplos previstos e desaparecem após as mudanças.”

Perguntas úteis para a orientadora:

- Os exemplos tornam compreensível o problema que cada regra procura?
- A mensagem e a sugestão de correção são suficientes para orientar uma pessoa desenvolvedora?
- Quais casos reais deveríamos usar na próxima etapa de avaliação?
- Como apresentar e avaliar falsos positivos, problemas não detectados e limites da análise estática no TCC?

## Se o tempo for curto

Em cinco minutos: explique a ideia, demonstre a **ListaCompras** antes/depois, mostre um relatório e conclua com os limites da análise. Cite os outros dois aplicativos como casos já preparados para explorar as regras de leitura, estado e interação.

## Respostas curtas para dúvidas prováveis

**“Por que o app compila mesmo com problemas?”**

Porque problemas de acessibilidade normalmente não são erros de sintaxe. O checker produz avisos de revisão; não bloqueia o build por esses diagnósticos.

**“A ferramenta conserta o código?”**

Não. Esta implementação identifica padrões e oferece sugestões. As versões corrigidas foram preparadas como exemplos da revisão feita por uma pessoa desenvolvedora.

**“A ferramenta analisou o aplicativo rodando?”**

Não. A análise é estática, feita nos arquivos Swift. Executar o aplicativo torna o exemplo compreensível e permite verificações complementares.

**“Por que trocar de versão em vez de mudar uma opção na tela?”**

Porque uma opção na tela muda a execução, mas os dois trechos de código continuariam no mesmo target. Os targets separados permitem comparar o conjunto de arquivos analisado em cada versão.

**“Esses casos provam que a ferramenta funciona em qualquer app?”**

Não. Eles demonstram comportamentos esperados em exemplos controlados. Avaliar aplicativos reais, falsos positivos e limitações é uma etapa complementar.

**“Por que uma regra pode deixar passar algum problema?”**

Porque ela reconhece padrões sintáticos específicos. A implementação não resolve todos os tipos, variáveis ou componentes personalizados, e alguns problemas só aparecem durante a execução.
