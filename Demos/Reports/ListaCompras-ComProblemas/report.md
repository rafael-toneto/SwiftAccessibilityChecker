# Relatório de acessibilidade

Swift Accessibility Checker · Gerado em 2026-10-04T21:13:33Z

## Resumo

**3 achado(s) para revisar** em **1 arquivo(s)**. Arquivos Swift analisados: **2**.

Alta: 2 · Média: 1 · Baixa: 0.

> Esta análise estática identifica padrões de risco no código SwiftUI; não executa o app nem certifica conformidade com todas as diretrizes Apple ou WCAG. Os achados precisam de revisão no contexto da interface. A ausência de avisos não garante acessibilidade.

### Escopo da execução

Caminhos de entrada:

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/ListaCompras/ComProblemas/ContentView.swift
```

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/ListaCompras/Shared/App.swift
```

## Por onde começar

Revise os itens de prioridade **alta** primeiro. A prioridade estima o possível impacto; ela não é um nível de conformidade WCAG. Confirme o contexto, aplique a correção e valide no app. Mais de uma regra pode apontar para o mesmo componente.

| Prioridade | Regra | O que revisar | Ocorrências |
| --- | --- | --- | ---: |
| Alta | SAC001 | Botão sem nome acessível claro | 1 |
| Alta | SAC006 | Metadado de acessibilidade vazio | 1 |
| Média | SAC004 | Área de toque possivelmente pequena | 1 |

### Arquivos com achados

| Arquivo | Ocorrências |
| --- | ---: |
| ComProblemas/ContentView\.swift | 3 |

## Ajustes no código

As ocorrências estão ordenadas por prioridade, arquivo e posição. Os exemplos são **ilustrativos**: adapte nomes, estados, localização e layout ao projeto. O trecho encontrado é mostrado separadamente.

### 1. Botão sem nome acessível claro

**Prioridade Alta** · SAC001 · ComProblemas/ContentView\.swift · linha **31**, coluna **29**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/ListaCompras/ComProblemas/ContentView.swift:31:29
```

**O que foi encontrado:** O botão contém apenas uma imagem ou conteúdo vazio, sem um nome acessível explícito reconhecido pela regra\.

**Impacto para quem usa o app:** Quem usa VoiceOver pode encontrar o botão sem entender qual ação ele executa\.

**Como ajustar:** Dê ao botão um nome curto que descreva a ação, usando um título significativo ou accessibilityLabel\. Localize o texto e preserve o nome visível quando houver um\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  29 | 
  30 |                             // SAC001: só o desenho não explica a ação ao leitor de tela.
> 31 |                             Button(role: .destructive) {
  32 |                                 hasMilk = false
  33 |                             } label: {
```

**Antes — exemplo ilustrativo:**

```swift
Button(action: salvar) {
    Image(systemName: "square.and.arrow.down")
}
```

**Depois — exemplo ilustrativo:**

```swift
Button(action: salvar) {
    Image(systemName: "square.and.arrow.down")
}
.accessibilityLabel("Salvar")
```

**Como validar:** Ative o VoiceOver, navegue até o botão e confirme que ele anuncia a ação e o papel de botão\. Ative\-o e confira o resultado\.

**Antes de concluir:** Um nome pode vir de um componente ou recurso que a análise não resolve\. Confirme a leitura real antes de adicionar um rótulo; evite repetir a palavra ‘botão’\.

**Referências:**

- [Apple — accessibilityLabel](<https://developer.apple.com/documentation/swiftui/view/accessibilitylabel%28_:%29>)
- [WCAG 2\.2 — 1\.1\.1 Non\-text Content](<https://www.w3.org/TR/WCAG22/#non-text-content>)
- [WCAG 2\.2 — 4\.1\.2 Name, Role, Value](<https://www.w3.org/TR/WCAG22/#name-role-value>)

### 2. Metadado de acessibilidade vazio

**Prioridade Alta** · SAC006 · ComProblemas/ContentView\.swift · linha **54**, coluna **29**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/ListaCompras/ComProblemas/ContentView.swift:54:29
```

**O que foi encontrado:** accessibilityValue recebeu um texto vazio ou composto apenas por espaços\.

**Impacto para quem usa o app:** Um valor vazio pode apagar a informação que o controle já oferece às tecnologias assistivas ou deixar sua finalidade pouco clara\.

**Como ajustar:** Remova o modificador vazio para preservar a semântica padrão, ou forneça conteúdo significativo\. Use label para o nome, value para o estado atual e hint apenas para explicar uma consequência que não esteja clara\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  52 |                         Text("Unidades: \(quantity)")
  53 |                             .accessibilityLabel("Quantidade de leite")
> 54 |                             .accessibilityValue("")
  55 | 
  56 |                         HStack(spacing: 20) {
```

**Antes — exemplo ilustrativo:**

```swift
Button("Salvar", action: salvar)
    .accessibilityValue("")
```

**Depois — exemplo ilustrativo:**

```swift
Button("Salvar", action: salvar)
```

**Como validar:** Com VoiceOver, confira o nome, o estado e as instruções do elemento\. Teste também mudanças de estado e os idiomas suportados\.

**Antes de concluir:** Nem todo controle precisa de hint ou value personalizado\. Não preencha um campo apenas para eliminar o aviso; preserve uma leitura útil e sem repetições\.

**Referências:**

- [Apple — View accessibility](<https://developer.apple.com/documentation/swiftui/view-accessibility>)
- [WCAG 2\.2 — 4\.1\.2 Name, Role, Value](<https://www.w3.org/TR/WCAG22/#name-role-value>)

### 3. Área de toque possivelmente pequena

**Prioridade Média** · SAC004 · ComProblemas/ContentView\.swift · linha **77**, coluna **29**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/ListaCompras/ComProblemas/ContentView.swift:77:29
```

**O que foi encontrado:** Um frame explícito limita uma dimensão do controle a menos de 44 pontos\.

**Impacto para quem usa o app:** Pessoas com menor precisão motora podem errar o toque ou acionar o controle vizinho\.

**Como ajustar:** Amplie a área realmente acionável do controle\. Para interfaces de toque no iOS, use 44 × 44 pt como referência Apple, mantendo espaço entre controles\. Aumente o frame do conteúdo do botão e confira o efeito do estilo e dos modificadores\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  75 |                             }
  76 |                             .buttonStyle(.plain)
> 77 |                             .frame(width: 28, height: 28)
  78 |                             .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
  79 |                             .contentShape(Rectangle())
```

**Antes — exemplo ilustrativo:**

```swift
Button(action: adicionar) {
    Image(systemName: "plus")
}
.frame(width: 24, height: 24)
```

**Depois — exemplo ilustrativo:**

```swift
Button(action: adicionar) {
    Image(systemName: "plus")
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
}
.accessibilityLabel("Adicionar item")
```

**Como validar:** Inspecione a região acionável no Accessibility Inspector e toque perto das bordas em um dispositivo\. Confirme que a área ampliada não sobrepõe outro controle\.

**Antes de concluir:** A regra lê o frame e não mede a área final: padding, estilo e layout podem alterá\-la\. Os 44 × 44 pt da Apple não equivalem ao mínimo WCAG 2\.5\.8: 24 × 24 CSS px, com exceções\. Considere também as recomendações da plataforma de destino\.

**Referências:**

- [Apple — Accessibility](<https://developer.apple.com/design/human-interface-guidelines/accessibility>)
- [WCAG 2\.2 — 2\.5\.5 Target Size \(Enhanced\)](<https://www.w3.org/TR/WCAG22/#target-size-enhanced>)
- [WCAG 2\.2 — 2\.5\.8 Target Size \(Minimum\)](<https://www.w3.org/TR/WCAG22/#target-size-minimum>)

## Validação manual que complementa este relatório

- [ ] VoiceOver: percorra os fluxos principais e confira nomes, estados, ordem de foco, agrupamento e anúncios de mudanças.
- [ ] Dynamic Type: teste os maiores tamanhos de acessibilidade, textos longos e os idiomas suportados, sem cortes ou sobreposição.
- [ ] Contraste e cor: confira textos, ícones e estados nos temas claro e escuro; toda informação por cor também precisa de outro indicador.
- [ ] Interação: valide áreas de toque, teclado, Controle por Voz e Controle Assistivo nos dispositivos e plataformas suportados.
- [ ] Movimento e mídia: respeite Reduzir Movimento e revise legendas, transcrições e alternativas para conteúdo audiovisual quando houver.
- [ ] Validação: execute o Accessibility Inspector, registre os resultados e teste os fluxos com pessoas que usam tecnologias assistivas.

Depois dos ajustes, execute o checker novamente e registre a validação manual no PR. Para um possível falso positivo, registre a regra, o trecho e o comportamento observado; remova dados sensíveis antes de compartilhar.

