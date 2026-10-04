# Como inserir esta avaliação no paper do TCC

Este texto é um guia de redação, não um resultado validado por especialista. Ele parte da [proposta original](/Users/rafaeltoneto/Downloads/TC2___Rafael_Toneto__2026_.pdf), que previa estudo de caso e métricas, e atualiza o desenho para cinco apps independentes. Antes da versão final do paper, submeter a [matriz de 333 decisões preliminares](revisao_preliminar.csv), os casos de omissão e o instrumento à orientadora ou a outro avaliador humano.

## 1. Pergunta e contribuição

**Pergunta de pesquisa:** “Em que medida o SwiftAccessibilityChecker identifica, em projetos SwiftUI independentes, os padrões de risco de acessibilidade definidos por suas regras, e quão úteis são seus diagnósticos para a revisão por desenvolvedores?”

Descrever a contribuição como **apoio à revisão durante o desenvolvimento**: a ferramenta localiza padrões sintáticos associados a risco potencial e oferece contexto e sugestão. Não escrever que certifica conformidade, encontra toda barreira ou testa a interface. Definir três níveis: (i) padrão encontrado no código, (ii) risco potencial interpretado no contexto, (iii) barreira confirmada em execução, esta última ausente dos resultados externos atuais.

## 2. Metodologia sugerida para a seção de avaliação

### 2.1 Desenho e cronologia

Indicar estudo de casos múltiplos, exploratório e descritivo. O [protocolo](PROTOCOLO.md) foi registrado no commit `b51b19f` antes da escolha dos projetos e antes dos resultados. O [manifesto](AMOSTRA.md) foi fixado em `3c2eb7c`. Os relatórios iniciais foram preservados antes da alteração da regra SAC003. Explicar que os próprios seis targets de demonstração são ensaio controlado, enquanto cinco repositórios externos testam a aplicabilidade fora dos exemplos construídos para a ferramenta.

### 2.2 Seleção da amostra

Relatar a busca no GitHub em 4 out. 2026, critérios de licença explícita, projeto público independente, target de app iOS e pelo menos dez arquivos Swift do app com SwiftUI, diversidade de domínio e recorte viável para revisão integral. A lista de candidatos excluídos, justificativas, URLs, licenças e SHAs está em [AMOSTRA.md](AMOSTRA.md). A amostra é **intencional**, não aleatória; não foi selecionada por número de avisos. Nenhum dos cinco elegíveis terminou com zero avisos. Isso deve ser dito, sem acrescentar artificialmente um projeto de zero avisos após conhecer os resultados.

### 2.3 Execução e unidades

Informar macOS 26.6.2, Xcode 27.0, Swift 6.4, versão inicial da ferramenta `6c6115e`; arquivos `.swift` do app somente, excluindo testes, dependências, gerados, extensões e caches. Unidade de execução: projeto/commit. Unidade de revisão: aviso identificado por projeto, regra, arquivo, linha e coluna. Os 112 caminhos e hashes, comandos, JSON brutos e erros estão no [registro de reprodução](REPRODUCAO.md). A primeira revisão leu o trecho e contexto de **cada um dos 333 avisos** e o classificou como pertinente, falso positivo ou inconclusivo, com justificativa. Foi feita pelo agente e **não é parecer humano independente**. A busca de omissões foi dirigida, sem universo completo para revocação.

### 2.4 Medidas e interpretação

Usar contagens por projeto e regra; para a leitura inicial, apresentar a proporção de pertinentes entre classificados conclusivos (194/322 = 60,2%) como **indicador exploratório interno**, não como precisão validada. Não calcular revocação. Distinguir casos sem aviso de ausência de barreira. Descrever utilidade pelos atributos do relatório (localização, trecho, contexto, prioridade, orientação) e pelo [instrumento preparado](INSTRUMENTO_UTILIDADE.md), sem alegar respostas de participantes.

## 3. Tabelas e figuras recomendadas

1. **Tabela A — Projetos e seleção:** nome/domínio, licença, SHA abreviado, arquivos SwiftUI, status de build. Usar dados de [AMOSTRA.md](AMOSTRA.md) e [RESULTADOS.md](RESULTADOS.md).
2. **Tabela B — Matriz projeto × regra:** nove colunas SAC001–SAC009 e cinco linhas, com contagens de [`matriz_por_regra.csv`](matriz_por_regra.csv). Uma segunda tabela ou nota pode trazer P/FP/I agregados por regra.
3. **Figura A — Fluxo de evidência:** fontes → diagnóstico sintático → revisão contextual → inspeção limitada em execução, marcando que apenas telas de Mäuse foram observadas e nenhuma barreira por tecnologia assistiva foi confirmada.
4. **Figura B — Par de exemplos:** `SAC009` pertinente em Mäuse e SAC003 em símbolo visual que motivou correção; mostrar trecho curto, aviso e decisão da revisão, com licença/crédito do repositório. Evitar reproduzir telas externas sem necessidade; se usar as capturas, identificar a tela e configuração do simulador.
5. **Tabela C — Antes/depois da correção:** 333 avisos iniciais, 273 após ajuste; 60 removidos, todos classificados previamente como falsos positivos. Identificar o mesmo corpus como teste de regressão.

## 4. Texto-base para resultados

> Nos três aplicativos controlados, os seis targets compilaram, e cada versão com problemas produziu três avisos, totalizando as nove regras uma vez; as versões corrigidas não produziram avisos. Nos cinco aplicativos externos, selecionados antes da execução da ferramenta, foram analisados 112 arquivos de app e registrados 333 avisos. A revisão preliminar do agente classificou 194 como riscos pertinentes ao contexto do código, 128 como falsos positivos e 11 como inconclusivos. A regra SAC003 concentrou 241 avisos e revelou confusão entre fonte fixa de texto e dimensionamento de símbolos. Uma correção posterior removeu 60 avisos classificados como falsos positivos, preservando relatórios e contagens originais. Esses dados caracterizam padrões e riscos no código; não medem barreiras confirmadas por usuários nem precisão validada por avaliador independente.

> A distribuição variou de 7 avisos em Expense Tracker a 142 em 100 Challenge. A diferença bruta não é ranking de acessibilidade, pois projetos diferem em tamanho, estilo de código e recursos. SAC006 e SAC007 não ocorreram na amostra externa, embora tenham sido exercitadas nos exemplos controlados. Dois possíveis casos SAC004 em rótulos de botão com 28 e 38 pt não foram destacados; a região efetiva de toque ainda precisa ser medida no app em execução.

## 5. Texto-base para discussão

> Os resultados sugerem que o checker pode reduzir o esforço inicial de localização de riscos em SwiftUI, sobretudo quando o padrão sintático é explícito, como uma faixa restrita de Dynamic Type. A triagem contextual continua necessária: imagens decorativas e gestos de conveniência geraram avisos sem ação corretiva. A falha inicial da SAC003 mostra como uma regra simples de sintaxe pode perder o tipo do elemento e produzir ruído; a correção melhorou a especificidade neste corpus, mas a mesma amostra usada para corrigi-la não pode validar sua generalização. A evidência favorece o uso da ferramenta como gatilho para revisão, combinado com inspeção da interface e tecnologia assistiva, em linha com a documentação Apple e estudos de avaliação complementar ([referências verificadas](REFERENCIAS.md)).

## 6. Ameaças à validade e lacunas a declarar

- **Construção:** “pertinente” é julgamento de risco no código; pode não virar barreira. Regras não fazem análise semântica completa, medição de contraste, layout ou árvore de acessibilidade.
- **Interna:** uma única revisão preliminar pelo agente, sem concordância entre avaliadores; decisões difíceis permaneceram inconclusivas. Alguns avisos têm contexto dependente de tipo/estado.
- **Externa:** cinco repositórios intencionais, com domínios e tamanhos diferentes; não representam a distribuição de apps iOS. Os demos foram construídos para as regras.
- **Conclusão:** nenhuma estimativa de revocação; a proporção de pertinência não deve receber intervalo de confiança populacional; o mesmo corpus serviu para ajustar SAC003.
- **Execução:** só Mäuse compilou; suas capturas cobrem introdução e Configurações, não fluxos completos. A árvore acessível do simulador mostrou rótulo e ativação de “Settings”, mas não mediu região de toque. O Accessibility Inspector não apresentou resultado de auditoria nesta sessão. Capelo falhou por `Secrets` ausente, Expense Tracker por integração Realm; RSSBud e 100 Challenge não foram compilados. VoiceOver exige aparelho físico conforme a Apple. Sem barreira externa confirmada.
- **Utilidade:** existe instrumento, mas nenhum desenvolvedor ou especialista o respondeu. A avaliação de clareza/prioridade/correção continua pendente.

## 7. Próxima validação com a orientadora

Pedir revisão independente de uma amostra **estratificada** de avisos (incluindo FP, pertinentes, inconclusivos e os dois candidatos de omissão), e decidir se a orientadora prefere uma segunda leitura de todos os 333. Registrar adjudicação, alterações e concordância separadamente; nunca substituir a primeira planilha. Se houver aparelho físico e permissão para testar, selecionar fluxos de interesse, anotar modelo/iOS, passos e observação por VoiceOver/Inspector. Aplicar o instrumento apenas mediante participação consentida; só então adicionar resultados de utilidade ao paper.

## 8. Fontes e coerência normativa

Usar as entradas e limites de [`REFERENCIAS.md`](REFERENCIAS.md) na lista bibliográfica final. A proposta cita WCAG 2.1; para a avaliação presente, declarar adoção de WCAG 2.2 e orientação informativa WCAG2Mobile 2025. Separar 44 pt (Apple) de 24/44 CSS px (WCAG 2.5.8 AA / 2.5.5 AAA). A regra SAC005 trata uso exclusivo de cor e não mede contraste. A ABNT NBR 17060:2022 pode ser citada como norma brasileira de apps móveis, sem atribuir cláusulas não consultadas.
