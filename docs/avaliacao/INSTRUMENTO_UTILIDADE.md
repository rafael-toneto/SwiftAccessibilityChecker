# Instrumento para avaliar utilidade dos diagnósticos

**Estado:** pronto para aplicação, **nenhuma pessoa participante foi recrutada ou respondeu**. A planilha [`validacao_humana_modelo.csv`](validacao_humana_modelo.csv) contém os 333 avisos e colunas vazias para segunda leitura. Trabalhar em uma cópia, mantendo a revisão preliminar intacta. Não enviar convites ou dados em nome do pesquisador sem decisão dele.

## Participante e sessão sugerida

Perfil: pessoa desenvolvedora Swift/SwiftUI ou com experiência em acessibilidade móvel. Registrar perfil geral, anos de experiência, familiaridade com VoiceOver/Dynamic Type, data, versão do checker e se conhece o projeto. Sessão individual de aproximadamente 20–30 minutos, com 3–4 avisos escolhidos antes da sessão, cobrindo um caso pertinente, um falso positivo e um inconclusivo de regras distintas. Permitir abrir o arquivo fonte e o relatório HTML/Markdown, sem mostrar primeiro a classificação do agente. Não usar os demos como única tarefa de utilidade, pois foram construídos para o checker.

## Tarefa curta para cada aviso

1. Abra o aviso pelo relatório. Em até 3 minutos, localize o elemento e explique o risco em suas palavras.
2. Decida: `corrigir agora`, `investigar em execução`, `dispensar com justificativa` ou `não consigo decidir`. Anote que evidência falta.
3. Se couber, descreva uma mudança de código ou um teste de interface que faria em seguida. Evite pedir que a pessoa aceite uma sugestão do relatório sem crítica.
4. Registre o tempo aproximado para localizar, a decisão e trechos usados; não coletar gravação ou dados pessoais sem consentimento específico.

## Perguntas após cada tarefa

Usar escala de 1 (discordo totalmente) a 5 (concordo totalmente), com “não se aplica” disponível:

| Dimensão | Pergunta |
| --- | --- |
| Clareza | “Entendi qual padrão no código gerou este aviso.” |
| Localização | “Arquivo, linha, trecho e contexto foram suficientes para localizar o elemento.” |
| Pertinência | “Este aviso merece revisão no app avaliado.” |
| Prioridade | “A prioridade exibida ajuda a ordenar o trabalho neste caso.” |
| Orientação | “A sugestão de correção ou teste me ajuda a decidir o próximo passo.” |
| Confiança calibrada | “O relatório deixa claro o que ainda depende da interface em execução.” |

Perguntas abertas: “O que faltou para decidir?”; “O que no aviso pode induzir uma correção inadequada?”; “Como você reescreveria a sugestão?”; “Há outra ação de acessibilidade mais importante nesta tela?” Ao final, perguntar se a pessoa usaria o relatório antes, durante ou depois de testes com VoiceOver/Inspector e por quê.

## Roteiro para segunda avaliação técnica

Para cada linha da planilha, conferir o arquivo no SHA fixado, a declaração do componente, seus modificadores e o uso próximo. Registrar `pertinente`, `falso positivo` ou `inconclusivo` na coluna `decisao_humana`, justificar, assinalar concordância com a decisão preliminar e indicar se houve screenshot, Inspector, VoiceOver ou apenas código. Revisar também as duas candidatas de omissão SAC004 descritas em [`RESULTADOS.md`](RESULTADOS.md). Em divergências, preservar as duas decisões e uma terceira coluna de adjudicação em arquivo novo. Só calcular uma medida de concordância se houver dados suficientes e unidade/critério estáveis; não confundir concordância com validade clínica ou conformidade.

## Exemplo **preenchido pelo agente**, sem participante

Caso `expense-tracker-001`, SAC008: gesto usado para mover foco ao campo. **Decisão técnica preliminar:** falso positivo; o campo mantém interação própria e o gesto não é a única operação do fluxo. **Ação sugerida:** confirmar no app que navegação por teclado/tecnologia assistiva continua alcançando o campo; não trocar cegamente o gesto por `Button`. **Clareza:** 4/5 (o relatório nomeia “gesto somente”, mas a ação equivalente exige leitura do contexto). **Localização:** 5/5 (linha e trecho suficientes). **Prioridade:** 2/5 (a gravidade genérica superestima este caso). **Orientação:** 3/5 (útil para pedir teste, mas a correção sugerida precisa ressalvar gestos de conveniência). **Confiança calibrada:** 3/5 (relatório poderia explicitar melhor que não observou a interface). Estes valores são uma **simulação de preenchimento feita pelo agente**, não resposta de desenvolvedor nem resultado de estudo com participantes.

## Registro e análise quando houver respostas reais

Guardar respostas anonimizadas por tarefa, versão e ordem de apresentação. Relatar contagens/distribuições das escalas e exemplos de razões de aceitação ou rejeição; com amostra pequena, evitar significância inferencial. Separar interpretação de aviso, velocidade de localização e concordância técnica. Identificar explicitamente eventuais falhas de compreensão, sugestões que induzam erro e casos em que o relatório levou a pedir verificação em execução.
