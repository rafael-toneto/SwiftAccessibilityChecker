# Resultados da avaliação, 2026-10-04

Leia com o [protocolo anterior à execução](PROTOCOLO.md), o [manifesto de amostra](AMOSTRA.md), os [relatórios JSON iniciais](resultados_iniciais/), a [matriz completa](matriz_por_regra.csv) e a [revisão de cada aviso](revisao_preliminar.csv). As classificações são uma **primeira leitura do agente**, pendente de conferência pela orientadora ou por outro avaliador humano. “Pertinente” significa risco plausível observado no código; **nenhuma** das contagens abaixo representa barreira confirmada por pessoa usuária.

## 1. Exemplos controlados

Os seis targets dos três apps próprios compilaram no Xcode 27.0. A análise separada de cada target deu **3 avisos** na versão com problemas e **0** na corrigida. As nove regras apareceram uma vez no conjunto problemático. Fontes, comandos, logs de validação e relatórios estão em [`Demos`](../../Demos/). Isso demonstra que os padrões sintáticos intencionais são reconhecidos; não mede generalização para projetos independentes. Zero aviso na versão corrigida indica somente que essas regras não foram acionadas nesses arquivos.

## 2. Projetos externos, versão inicial `6c6115e`

Foram analisados **112 arquivos Swift do app** em cinco commits fixados. Todos os cinco comandos terminaram com código zero e sem problema de leitura. O inventário de arquivos e hashes está em `amostra.json`. Matriz resumida (P = pertinente; FP = falso positivo; I = inconclusivo):

| Projeto | Arquivos | Avisos | P | FP | I | Após correção |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RSSBud | 25 | 63 | 26 | 36 | 1 | 46 |
| 100 Challenge | 15 | 142 | 92 | 45 | 5 | 121 |
| Mäuse | 25 | 83 | 56 | 26 | 1 | 70 |
| Capelo | 23 | 38 | 19 | 15 | 4 | 29 |
| Expense Tracker | 24 | 7 | 1 | 6 | 0 | 7 |
| **Total** | **112** | **333** | **194** | **128** | **11** | **273** |

| Regra | Avisos iniciais | P | FP | I |
| --- | ---: | ---: | ---: | ---: |
| SAC001 | 20 | 20 | 0 | 0 |
| SAC002 | 51 | 8 | 41 | 2 |
| SAC003 | 241 | 160 | 77 | 4 |
| SAC004 | 2 | 0 | 0 | 2 |
| SAC005 | 8 | 2 | 3 | 3 |
| SAC006 | 0 | 0 | 0 | 0 |
| SAC007 | 0 | 0 | 0 | 0 |
| SAC008 | 9 | 2 | 7 | 0 |
| SAC009 | 2 | 2 | 0 | 0 |

**Verificação de totais:** 194 + 128 + 11 = 333. Entre os 322 avisos com classificação preliminar conclusiva, **194/322 = 60,2%** foram considerados pertinentes. Esta é apenas a proporção interna da primeira revisão; não é precisão independente, taxa de barreiras nem estimativa da população de apps SwiftUI. As nove regras aparecem nos exemplos controlados. Na amostra externa, SAC006 e SAC007 não tiveram avisos; isso não prova ausência de problemas ou cobertura dessas regras.

Exemplos representativos, com identificadores da revisão:

- `rssbud-002` (SAC001): botão com símbolo e sem nome de ação explícito — risco plausível de anúncio pouco claro; o nome automático do símbolo ainda precisa ser verificado.
- `maeuse-ios-069` e `-070` (SAC009): `dynamicTypeSize(...xxxLarge)` limita explicitamente categorias maiores — padrão de restrição confirmado no código, sem afirmar texto cortado.
- `expense-tracker-001`, `-002` e `-005` (SAC008): gestos de foco/teclado, classificados como falsos positivos porque a função principal permanece disponível por controles de campo.
- `hundred-challenge-ios-057` e `-104` (SAC004): campo de emoji com `frame(width: 40)`; o código não determina toda a região interativa, logo inconclusivo.
- Ícones de `Image` com `.font(.system(size:))` geraram 60 falsos positivos da SAC003: tamanho visual de símbolo foi interpretado como texto fixo.

## 3. Omissões procuradas e pertinência dos relatórios

A busca dirigida no mesmo conjunto conferiu ocorrências de `.font(.system(size:))`, `.onTapGesture`, `.dynamicTypeSize`, `.accessibilityHidden(true)` e dimensões explícitas. Os dois limitadores de Dynamic Type e os gestos literais procurados receberam aviso. Quatro usos de `.accessibilityHidden(true)` em Mäuse ocultavam elementos decorativos, sem controle interativo evidente; não são omissões SAC007. A busca **não** formou um catálogo exaustivo de todos os casos cobertos por cada regra; por isso não há denominador para revocação.

Dois **candidatos de omissão SAC004** merecem inspeção em execução: `hundred-challenge-ios/Sources/Views/Screens/AuthView.swift:136–139` define um ícone de fechar com `frame(width: 28, height: 28)` dentro do rótulo de `Button`; `maeuse-ios/Maeuse/Views/MainExpenseView.swift:59–63` define o ícone de Configurações com `38 × 38 pt`, sob `StampedButtonStyle` que não adiciona padding. A implementação atual da SAC004 examina `frame` na cadeia do controle, não o filho do rótulo. São **padrões no código que a regra não destacou**, com risco possível pela recomendação Apple de 44 pt; área final de toque, exceções e barreira de uso não foram confirmadas. Uma correção automática dessa lacuna requer modelar composição de layout e estilo, para não criar novos falsos positivos.

Os relatórios contêm regra, gravidade, arquivo/linha/coluna, trecho, contexto, justificativa e orientação. Esses campos tornam casos como `maeuse-ios-069` localizáveis. A revisão também mostra limites de utilidade: avisos SAC002 em imagens decorativas e SAC008 em gestos de conveniência exigem tempo de triagem. Clareza, prioridade e qualidade da correção sugerida **ainda dependem da aplicação do [instrumento com humanos](INSTRUMENTO_UTILIDADE.md)**.

## Correção posterior, claramente separada

O defeito da SAC003 foi corrigido em `07c2b19`, após o arquivamento dos resultados iniciais. [Os relatórios posteriores](resultados_apos_ajuste/) mostram **273** avisos: saíram exatamente 60 ocorrências classificadas como falsas positivas, nenhuma das 194 pertinentes ou 11 inconclusivas. Os 136 testes automatizados passaram. O mesmo corpus orientou a correção; a redução é uma **verificação de regressão**, não evidência independente de desempenho da versão nova. Entre os 262 avisos remanescentes com classificação inicial conclusiva, 194/262 = 74,0% seriam pertinentes segundo a mesma leitura preliminar, mas esse quociente herda o viés do ajuste e não deve ser chamado de precisão validada.

## Execução das interfaces

Os builds completos, com logs em [`evidencias/`](evidencias/), tiveram estes resultados:

| App | Resultado |
| --- | --- |
| Mäuse | `BUILD SUCCEEDED` para simulador iOS genérico. Instalado/aberto em iPhone 17 Pro, iOS 26.5, simulador `D9DB7D76-3CCA-489B-B409-9E1506DF4746`. Capturas [tamanho padrão](evidencias/maeuse-loaded.png) e [tamanho de acessibilidade máximo](evidencias/maeuse-max-relaunch.png), após encerrar e reabrir o app. A tela inicial manteve visualmente a mesma dimensão de textos; não se observou corte ou função bloqueada nessa tela. O tamanho foi restaurado para `large`. É observação visual, **não** teste VoiceOver nem confirmação de barreira. |
| Capelo | `BUILD FAILED`: `Capelo/Game/API.swift:11` referencia `Secrets` ausente no checkout público. |
| Expense Tracker | `BUILD FAILED`: conflito de ligação estática/dinâmica no produto da dependência Realm, antes da execução do app. |
| RSSBud | Sem build: projeto tem fase `npm run build-inc`, dependências e App Group; comandos de terceiros não foram executados para esta análise. |
| 100 Challenge | Sem build: requer XcodeGen, não instalado, e fluxo de autenticação/backend. |

A tentativa de controle interativo do simulador pelo ambiente de interface foi impedida porque o Mac estava bloqueado. A documentação Apple informa que VoiceOver deve ser testado em aparelho físico. Portanto, **nenhum aviso externo recebeu confirmação por VoiceOver ou Accessibility Inspector**, e não se atribui barreira confirmada à amostra. A análise de código permanece válida dentro do recorte sintático.

## Limites imediatos

A amostra intencional é pequena, heterogênea e não probabilística; uma revisão por um único agente pode errar; não houve participante nem especialista independente; um build não equivale a testar todos os fluxos; e a ausência de avisos de uma regra em projeto externo não demonstra acessibilidade. As classificações devem ser confrontadas com o código e, quando necessário, com execução e avaliador humano antes de resultados definitivos no paper.
