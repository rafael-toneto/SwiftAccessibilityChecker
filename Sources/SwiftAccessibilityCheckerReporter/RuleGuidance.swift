import SwiftAccessibilityCheckerCore

/// Human guidance stays separate from the stable machine-readable diagnostics.
public struct RuleGuidance: Sendable {
    public let title: String
    public let problem: String
    public let impact: String
    public let fix: String
    public let before: String
    public let after: String
    public let verification: String
    public let caveat: String

    public static func forDiagnostic(_ diagnostic: Diagnostic) -> RuleGuidance {
        switch diagnostic.ruleIdentifier {
        case "SAC001":
            RuleGuidance(
                title: "Botão sem nome acessível claro",
                problem: "O botão contém apenas uma imagem ou conteúdo vazio, sem um nome acessível explícito reconhecido pela regra.",
                impact: "Quem usa VoiceOver pode encontrar o botão sem entender qual ação ele executa.",
                fix: "Dê ao botão um nome curto que descreva a ação, usando um título significativo ou accessibilityLabel. Localize o texto e preserve o nome visível quando houver um.",
                before: """
                Button(action: salvar) {
                    Image(systemName: "square.and.arrow.down")
                }
                """,
                after: """
                Button(action: salvar) {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel("Salvar")
                """,
                verification: "Ative o VoiceOver, navegue até o botão e confirme que ele anuncia a ação e o papel de botão. Ative-o e confira o resultado.",
                caveat: "Um nome pode vir de um componente ou recurso que a análise não resolve. Confirme a leitura real antes de adicionar um rótulo; evite repetir a palavra ‘botão’."
            )
        case "SAC002":
            RuleGuidance(
                title: "Imagem sem descrição ou intenção definida",
                problem: "A imagem não tem um tratamento de acessibilidade explícito reconhecido pela regra.",
                impact: "Uma imagem informativa pode perder seu significado; uma imagem decorativa pode gerar anúncios desnecessários no VoiceOver.",
                fix: "Se a imagem transmite informação, descreva seu significado com accessibilityLabel. Se ela for apenas decorativa, use Image(decorative:) ou accessibilityHidden(true). Em um botão, descreva a ação no controle.",
                before: "Image(\"entrega-concluida\")",
                after: """
                // Imagem informativa:
                Image("entrega-concluida")
                    .accessibilityLabel("Entrega concluída")

                // Alternativa para uma imagem apenas decorativa:
                Image(decorative: "fundo-abstrato")
                """,
                verification: "Com VoiceOver, confirme que a informação aparece uma única vez e que imagens decorativas não recebem foco desnecessário.",
                caveat: "Considere o texto vizinho e a semântica do elemento pai. Não esconda imagens que sejam a única forma de comunicar informação ou uma ação."
            )
        case "SAC003":
            RuleGuidance(
                title: "Texto com tamanho fixo",
                problem: "Uma fonte usa um tamanho numérico fixo que pode não acompanhar o Dynamic Type.",
                impact: "Pessoas que precisam ampliar o texto podem continuar vendo uma fonte pequena ou encontrar conteúdo cortado.",
                fix: "Prefira estilos semânticos como .body, .headline e .title. Para tipografia personalizada, adote uma fonte relativa a um estilo de texto ou uma medida escalável e permita que o layout cresça.",
                before: "Text(\"Resumo do pedido\")\n    .font(.system(size: 16))",
                after: "Text(\"Resumo do pedido\")\n    .font(.body)",
                verification: "Aumente o tamanho de texto até as maiores categorias de acessibilidade. Confira leitura, quebras de linha, conteúdo completo e acesso a todos os controles.",
                caveat: "O valor pode já vir de @ScaledMetric ou de outro mecanismo de escala. A regra não calcula o tamanho final nem avalia o layout em execução."
            )
        case "SAC004":
            RuleGuidance(
                title: "Área de toque possivelmente pequena",
                problem: "Um frame explícito limita uma dimensão do controle a menos de 44 pontos.",
                impact: "Pessoas com menor precisão motora podem errar o toque ou acionar o controle vizinho.",
                fix: "Amplie a área realmente acionável do controle. Para interfaces de toque no iOS, use 44 × 44 pt como referência Apple, mantendo espaço entre controles. Aumente o frame do conteúdo do botão e confira o efeito do estilo e dos modificadores.",
                before: """
                Button(action: adicionar) {
                    Image(systemName: "plus")
                }
                .frame(width: 24, height: 24)
                """,
                after: """
                Button(action: adicionar) {
                    Image(systemName: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Adicionar item")
                """,
                verification: "Inspecione a região acionável no Accessibility Inspector e toque perto das bordas em um dispositivo. Confirme que a área ampliada não sobrepõe outro controle.",
                caveat: "A regra lê o frame e não mede a área final: padding, estilo e layout podem alterá-la. Os 44 × 44 pt da Apple não equivalem ao mínimo WCAG 2.5.8: 24 × 24 CSS px, com exceções. Considere também as recomendações da plataforma de destino."
            )
        case "SAC005":
            RuleGuidance(
                title: "Estado possivelmente indicado apenas por cor",
                problem: "Uma cor muda conforme o estado, sem uma alternativa reconhecida neste trecho.",
                impact: "Pessoas com daltonismo ou baixa visão podem não distinguir estados como sucesso, erro ou seleção.",
                fix: "Acrescente texto visível, forma ou símbolo que também mude com o estado. Exponha o significado para o VoiceOver. Um accessibilityValue isolado não cria uma alternativa visual à cor.",
                before: "Circle()\n    .fill(concluido ? Color.green : Color.red)",
                after: """
                Label {
                    Text(concluido ? "Concluído" : "Pendente")
                } icon: {
                    Image(systemName: concluido ? "checkmark.circle" : "clock")
                }
                .foregroundStyle(concluido ? Color.green : Color.red)
                """,
                verification: "Confira os estados sem depender da cor, por exemplo em escala de cinza. Com VoiceOver, verifique se o estado atual é compreensível.",
                caveat: "Uma legenda ou descrição em outro elemento pode já resolver o problema. Este aviso não mede contraste nem confirma que a cor seja o único indicador."
            )
        case "SAC006":
            emptyMetadataGuidance(diagnostic)
        case "SAC007":
            RuleGuidance(
                title: "Controle oculto para tecnologias assistivas",
                problem: "O controle, ou um contêiner que o contém, usa accessibilityHidden(true).",
                impact: "A ação pode desaparecer da navegação por VoiceOver e ficar indisponível para parte das pessoas.",
                fix: "Remova accessibilityHidden(true) do controle quando a ação precisar estar disponível. Se ele duplicar uma ação, confirme que existe um equivalente acessível, com o mesmo resultado e no contexto adequado.",
                before: "Button(\"Continuar\", action: continuar)\n    .accessibilityHidden(true)",
                after: "Button(\"Continuar\", action: continuar)",
                verification: "Navegue pela tela com VoiceOver e execute a ação. Confirme que ela pode ser encontrada e concluída sem depender do controle oculto.",
                caveat: "Ocultar um controle duplicado pode ser intencional se o elemento pai ou outro controle oferece a mesma ação de forma acessível. Verifique isso no app."
            )
        case "SAC008":
            RuleGuidance(
                title: "Ação depende de um gesto personalizado",
                problem: "Foi encontrado um gesto de toque ou pressão prolongada sem uma ação acessível equivalente reconhecida pela regra.",
                impact: "A ação pode não ser descoberta ou executada com VoiceOver, Controle Assistivo ou teclado.",
                fix: "Para uma ação simples, prefira Button ou outro controle padrão. Se o gesto precisar permanecer, exponha uma ação equivalente com accessibilityAction ou accessibilityRepresentation e valide sua operação.",
                before: "Text(\"Abrir detalhes\")\n    .onTapGesture { abrirDetalhes() }",
                after: "Button(\"Abrir detalhes\", action: abrirDetalhes)",
                verification: "Localize e execute a ação usando VoiceOver e os métodos de entrada suportados pelo app. Gestos com múltiplos toques ou pressão prolongada também precisam de uma alternativa operável.",
                caveat: "Adicionar apenas um nome ou a característica .isButton não garante que a ação funcione com todas as tecnologias assistivas. A equivalência precisa ser testada em execução."
            )
        case "SAC009":
            RuleGuidance(
                title: "Ampliação de texto limitada",
                problem: "dynamicTypeSize fixa uma categoria ou limita as maiores categorias de acessibilidade.",
                impact: "O app pode ignorar o tamanho de texto de que a pessoa precisa para ler o conteúdo.",
                fix: "Remova a restrição e adapte o layout aos tamanhos maiores. Quando houver uma faixa necessária, preserve as categorias de acessibilidade, inclusive .accessibility5, e valide todo o conteúdo.",
                before: "Text(\"Detalhes da entrega\")\n    .font(.body)\n    .dynamicTypeSize(.small ... .large)",
                after: "Text(\"Detalhes da entrega\")\n    .font(.body)",
                verification: "Altere o Dynamic Type nas configurações do dispositivo ou do simulador até o maior tamanho. Confira se textos e controles crescem sem cortes, sobreposição ou perda de ações.",
                caveat: "Uma restrição usada apenas em Preview ou testes pode ser intencional. Confira o uso em produção e as restrições herdadas de elementos pais."
            )
        default:
            RuleGuidance(
                title: diagnostic.title,
                problem: diagnostic.description,
                impact: diagnostic.rationale,
                fix: diagnostic.suggestion,
                before: "",
                after: "",
                verification: "Revise o trecho e valide o comportamento no app com as tecnologias assistivas pertinentes.",
                caveat: "Este achado é uma indicação para revisão. Consulte as referências da regra e o contexto do componente."
            )
        }
    }

    private static func emptyMetadataGuidance(_ diagnostic: Diagnostic) -> RuleGuidance {
        let context = diagnostic.description + " " + (diagnostic.sourceExcerpt ?? "")
        let modifier: String
        if context.contains("hint") || context.contains("accessibilityHint") {
            modifier = "accessibilityHint"
        } else if context.contains("value") || context.contains("accessibilityValue") {
            modifier = "accessibilityValue"
        } else {
            modifier = "accessibilityLabel"
        }
        return RuleGuidance(
            title: "Metadado de acessibilidade vazio",
            problem: "\(modifier) recebeu um texto vazio ou composto apenas por espaços.",
            impact: "Um valor vazio pode apagar a informação que o controle já oferece às tecnologias assistivas ou deixar sua finalidade pouco clara.",
            fix: "Remova o modificador vazio para preservar a semântica padrão, ou forneça conteúdo significativo. Use label para o nome, value para o estado atual e hint apenas para explicar uma consequência que não esteja clara.",
            before: "Button(\"Salvar\", action: salvar)\n    .\(modifier)(\"\")",
            after: "Button(\"Salvar\", action: salvar)",
            verification: "Com VoiceOver, confira o nome, o estado e as instruções do elemento. Teste também mudanças de estado e os idiomas suportados.",
            caveat: "Nem todo controle precisa de hint ou value personalizado. Não preencha um campo apenas para eliminar o aviso; preserve uma leitura útil e sem repetições."
        )
    }
}
