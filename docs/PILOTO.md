# Piloto com um time de desenvolvimento

Objetivo: confirmar se os avisos ajudam o time a localizar, entender e corrigir riscos
de acessibilidade em um projeto SwiftUI real. Reserve uma primeira rodada para um
target e um fluxo conhecido. O checker cobre nove padrões estáticos; o checklist
manual ao final cobre aspectos que dependem do aplicativo em execução.

## 1. Preparar e gerar a primeira revisão

Use macOS 13 ou posterior, Xcode completo e uma toolchain compatível com Swift 6.2.
A primeira compilação precisa resolver o SwiftSyntax e pode levar alguns minutos.
Registre a versão de Xcode, a saída de `swift --version` e o commit do checker usado,
para que outra pessoa possa repetir a análise.

No terminal, ajuste os três caminhos do comando:

```bash
swift run --package-path "/caminho/SwiftAccessibilityChecker" \
  swift-accessibility-checker \
  --report-directory "/caminho/Relatorios/MeuApp" \
  "/caminho/MeuApp/Sources"
open "/caminho/Relatorios/MeuApp/report.html"
```

Se uma pasta mistura targets, passe os arquivos Swift do target explicitamente no
lugar da pasta. A CLI analisa os arquivos encontrados; ela não lê o projeto Xcode
para descobrir quais pertencem a um target. Para essa seleção pelo Xcode, siga
[a instalação do plugin](../README.md#instalação-local-em-um-projeto-xcode).

O mesmo comando pode ser executado novamente após cada ajuste; os cinco arquivos
do relatório são atualizados. Guarde a primeira execução em outra pasta se quiser
comparar o antes e o depois. Um retorno diferente de zero indica um erro de execução
ou de leitura, não a quantidade de avisos: confira o terminal e a seção de análise
incompleta antes de interpretar os resultados.

## 2. Revisar os avisos

1. Confira os arquivos analisados e a data. Uma pasta vazia ou uma análise parcial
   não representa o projeto inteiro.
2. Comece pela prioridade **Alta**, depois **Média** e **Baixa**. Use a busca e os
   filtros do HTML para localizar uma regra ou arquivo.
3. Para cada aviso, leia o problema, o impacto e o trecho. Abra o arquivo e vá até
   a linha e coluna informadas. O Issue Navigator do Xcode também permite ir ao código.
4. Adapte a sugestão e o exemplo ao comportamento da tela. Se o contexto já resolver
   o problema, registre a justificativa; remover o aviso não deve prejudicar a interface.
5. Faça a validação manual indicada no aviso e rode o checker novamente. Registre
   se o ajuste resolveu o problema e se a orientação foi suficiente.

O HTML abre offline e pode ser compartilhado sozinho. Markdown e texto são úteis
para tarefas do time; JSON e `warnings.txt` atendem integrações existentes. Esses
arquivos podem conter caminhos locais e trechos de código. Para feedback externo,
prefira o modelo abaixo com nomes fictícios, sem anexar o relatório do projeto inteiro.

## 3. Checklist de validação manual

Marque **feito**, **pendente** ou **não se aplica**, com o resultado do teste. Zero
avisos estáticos não substitui estas verificações.

| Verificação | O que observar no fluxo escolhido |
| --- | --- |
| VoiceOver | Todos os controles têm nomes claros; estado e valor são anunciados; foco segue uma ordem compreensível; todas as ações podem ser concluídas. |
| Dynamic Type | Nos maiores tamanhos de acessibilidade, textos continuam legíveis e completos; conteúdo não se sobrepõe e controles continuam disponíveis. |
| Cor e contraste | Estados têm texto, forma ou símbolo além da cor; textos, ícones e estados têm contraste suficiente nos temas usados pelo app. Use ferramentas para medir. |
| Toque e outras entradas | Áreas acionáveis e espaçamento permitem tocar sem acionar o vizinho; teste teclado, Controle Assistivo e Controle por Voz nas plataformas suportadas. |
| Mudanças de contexto | Mensagens, carregamento, erros, abertura e fechamento de telas deixam o foco e os anúncios compreensíveis. |
| Movimento e mídia | Teste Reduzir Movimento; confira legendas, transcrições e alternativas relevantes quando houver áudio, vídeo ou animações. |
| Inspector e uso real | Execute o Accessibility Inspector e revise os fluxos com pessoas que usam tecnologias assistivas quando possível. |

## 4. Feedback que permite reproduzir o caso

Copie este modelo para o canal de feedback combinado com o responsável pelo piloto.
Não é necessário compartilhar o repositório ou código privado. Um exemplo pequeno,
com textos e dados fictícios, costuma ser suficiente para investigar um aviso.

```text
Versão/commit do checker:
Xcode e Swift:
Plataforma e versão do sistema:
Execução: CLI ou plugin; comando sem caminhos privados, se aplicável
Regra: SAC___
Localização: nome fictício do arquivo + linha/coluna (ex.: TelaExemplo.swift:24:9)
Tipo: aviso correto / possível falso positivo / problema não detectado / texto confuso / falha de execução
O que a interface faz e quem pode ser afetado:
O que eu esperava que a ferramenta informasse:
O que ela informou ou deixou de informar:
Passos para reproduzir com dados fictícios:
Trecho mínimo de SwiftUI, se puder compartilhar:
Validação manual feita e resultado:
O que faltou na explicação para conseguir ajustar o código:
```

No fechamento da rodada, registre quantos avisos foram revisados, quantos levaram a
ajustes, quantos dependiam de outro contexto e quanto tempo foi necessário para
entender a primeira ocorrência. Inclua os problemas manuais que o checker não detectou.
Isso ajuda a decidir quais orientações e regras precisam melhorar antes de ampliar o piloto.
