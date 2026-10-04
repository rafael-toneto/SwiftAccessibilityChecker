# Protocolo prévio da avaliação — 2026-10-04

Registrado antes da busca/seleção de projetos externos e antes de executar o checker neles. Versão inicial da ferramenta: estado local pré-publicação em `main` sobre `699fc36`, a ser identificado por commit após a verificação. Alterações no protocolo posteriores à observação de resultados deverão ser anotadas como emendas, sem substituir esta versão.

## Pergunta e três blocos de evidência

Em que medida o SwiftAccessibilityChecker identifica, em projetos SwiftUI independentes, os padrões de risco definidos pelas regras SAC001–SAC009, e quão úteis são seus diagnósticos para revisão por desenvolvedores? (1) Confirmar comportamento esperado nos seis targets controlados. (2) Descrever incidência, pertinência e omissões em apps externos. (3) Examinar localização, clareza, prioridade e orientação dos avisos; preparar validação humana posterior.

O objeto primário é **padrão no código**. Um aviso indica **risco potencial** sujeito ao contexto. Só registrar **barreira confirmada em execução** quando houver inspeção observável da interface, com dispositivo/simulador, configuração e ação documentados. Zero avisos não certifica acessibilidade.

## Escopo e amostragem fixados antes da execução

- Amostra intencional de aproximadamente cinco repositórios iOS públicos e independentes da ferramenta, com licença explícita, app funcional e uso substantivo de SwiftUI (ao menos 10 arquivos Swift do código do app com `import SwiftUI` ou views SwiftUI). Preferir domínios diferentes e projetos com commits públicos identificáveis. A viabilidade de build é registrada, mas não é requisito para análise estática.
- Busca em GitHub em 2026-10-04: consulta `SwiftUI iOS app language:Swift` por relevância e buscas complementares por domínio (`SwiftUI mastodon app`, `SwiftUI RSS app`, `SwiftUI habit app`, `SwiftUI finance app`, `SwiftUI utility app`). Examinar candidatos em ordem de retorno; registrar excluídos e motivo. Não consultar a contagem de avisos na seleção. Se menos de cinco cumprirem os critérios em tempo viável, usar todos os elegíveis e explicar.
- Excluir bibliotecas sem target de app, tutoriais/samples, forks sem desenvolvimento próprio evidente, repositórios sem licença, código indisponível ou cujo app seja predominantemente UIKit. Não excluir por ausência de avisos. Casos com zero avisos entram se elegíveis pelo mesmo processo.
- Não incorporar código externo ao repositório do checker. Clonar em pasta irmã `ProjetosExternos`, fixando o commit. Ler manifestos, scripts de build e dependências antes de executar qualquer comando do projeto. Não instalar scripts de terceiros para a análise; invocar apenas o binário do checker sobre os fontes selecionados.

## Unidade, procedimento e classificação

Unidade de execução: repositório/commit, arquivos `.swift` do target principal do app que contenham código SwiftUI. Excluir `Tests`, `UITests`, `Pods`, `.build`, `DerivedData`, dependências, gerados, previews de terceiros, exemplos e extensões fora do app. Guardar lista exata de arquivos e hashes ou commit. Unidade de revisão: diagnóstico (`projeto`, `regra`, `arquivo`, `linha`, `coluna`); ocorrências repetidas são linhas distintas. Ler a declaração, modificadores, contêiner e uso próximo do componente antes de classificar.

Para **todos** os avisos, classificar `pertinente` (padrão e risco plausível na interface do app), `falso positivo` (o padrão sinalizado é neutralizado ou não se aplica, com evidência no código), ou `inconclusivo` (necessita tipo, estado, layout ou execução não resolvidos). Registrar trecho, justificativa e nível de evidência. Um falso positivo aqui não é sinônimo de conformidade WCAG; um aviso pertinente não prova barreira. A primeira classificação é do agente, a confirmar por orientadora ou segundo avaliador humano.

Buscar omissões por inspeção dirigida, para cada regra, nos mesmos arquivos: `Button` iconográfico, `Image`, `.font`, `.frame`, cor condicional, modificadores de metadados, `.accessibilityHidden`, gestos e `.dynamicTypeSize`, inclusive casos em componentes auxiliares. Registrar candidatos não avisados, contexto e por que parecem cobertos pela definição da regra. Não chamar de falso negativo todo problema fora do escopo sintático da regra. Se a inspeção não for exaustiva, não calcular revocação.

## Métricas, relatórios e limites

Guardar comandos, ambiente, commit do checker, versão Swift/Xcode, saída JSON bruta, lista de arquivos, status e erros. Matriz projeto × regra: avisos, revisões pertinentes/falsas/inconclusivas e omissões observadas. Relatar contagens e proporções descritivas. Precisão apenas se todos os avisos do denominador forem revisados; usar `pertinentes/(pertinentes + falsos positivos)` e expor inconclusivos separadamente, deixando claro que mede pertinência preliminar, não barreiras confirmadas. Revocação somente com universo manual exaustivo e previamente delimitado; de outro modo, apenas omissões observadas.

Se possível, compilar ao menos casos viáveis e inspecionar fluxo específico com VoiceOver, Dynamic Type ou Accessibility Inspector. Registrar configuração, passos e observação, distinguindo captura visual de leitura por tecnologia assistiva. Falha de build não invalida a leitura do fonte, mas impede inferência sobre execução. Nenhuma experiência de participante será presumida.

Se a avaliação mostrar defeito da ferramenta, preservar relatórios iniciais imutáveis e anotar correção/commit; executar novamente em pasta separada. O mesmo corpus usado para ajustar a regra é apenas verificação de regressão, nunca validação independente da versão ajustada.
