# Relatório de acessibilidade

Swift Accessibility Checker · Gerado em 2026-10-04T21:13:33Z

## Resumo

**3 achado(s) para revisar** em **1 arquivo(s)**. Arquivos Swift analisados: **2**.

Alta: 0 · Média: 3 · Baixa: 0.

> Esta análise estática identifica padrões de risco no código SwiftUI; não executa o app nem certifica conformidade com todas as diretrizes Apple ou WCAG. Os achados precisam de revisão no contexto da interface. A ausência de avisos não garante acessibilidade.

### Escopo da execução

Caminhos de entrada:

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/LeituraFacil/ComProblemas/ContentView.swift
```

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/LeituraFacil/Shared/App.swift
```

## Por onde começar

Revise os itens de prioridade **alta** primeiro. A prioridade estima o possível impacto; ela não é um nível de conformidade WCAG. Confirme o contexto, aplique a correção e valide no app. Mais de uma regra pode apontar para o mesmo componente.

| Prioridade | Regra | O que revisar | Ocorrências |
| --- | --- | --- | ---: |
| Média | SAC002 | Imagem sem descrição ou intenção definida | 1 |
| Média | SAC003 | Texto com tamanho fixo | 1 |
| Média | SAC009 | Ampliação de texto limitada | 1 |

### Arquivos com achados

| Arquivo | Ocorrências |
| --- | ---: |
| ComProblemas/ContentView\.swift | 3 |

## Ajustes no código

As ocorrências estão ordenadas por prioridade, arquivo e posição. Os exemplos são **ilustrativos**: adapte nomes, estados, localização e layout ao projeto. O trecho encontrado é mostrado separadamente.

### 1. Imagem sem descrição ou intenção definida

**Prioridade Média** · SAC002 · ComProblemas/ContentView\.swift · linha **15**, coluna **25**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/LeituraFacil/ComProblemas/ContentView.swift:15:25
```

**O que foi encontrado:** A imagem não tem um tratamento de acessibilidade explícito reconhecido pela regra\.

**Impacto para quem usa o app:** Uma imagem informativa pode perder seu significado; uma imagem decorativa pode gerar anúncios desnecessários no VoiceOver\.

**Como ajustar:** Se a imagem transmite informação, descreva seu significado com accessibilityLabel\. Se ela for apenas decorativa, use Image\(decorative:\) ou accessibilityHidden\(true\)\. Em um botão, descreva a ação no controle\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  13 |                     HStack(spacing: 16) {
  14 |                         // SAC002: a imagem informa o tempo, mas não tem descrição explícita.
> 15 |                         Image(systemName: "sun.max.fill")
  16 |                             .font(.largeTitle)
  17 |                             .foregroundStyle(.orange)
```

**Antes — exemplo ilustrativo:**

```swift
Image("entrega-concluida")
```

**Depois — exemplo ilustrativo:**

```swift
// Imagem informativa:
Image("entrega-concluida")
    .accessibilityLabel("Entrega concluída")

// Alternativa para uma imagem apenas decorativa:
Image(decorative: "fundo-abstrato")
```

**Como validar:** Com VoiceOver, confirme que a informação aparece uma única vez e que imagens decorativas não recebem foco desnecessário\.

**Antes de concluir:** Considere o texto vizinho e a semântica do elemento pai\. Não esconda imagens que sejam a única forma de comunicar informação ou uma ação\.

**Referências:**

- [Apple — VoiceOver](<https://developer.apple.com/design/human-interface-guidelines/voiceover>)
- [WCAG 2\.2 — 1\.1\.1 Non\-text Content](<https://www.w3.org/TR/WCAG22/#non-text-content>)

### 2. Texto com tamanho fixo

**Prioridade Média** · SAC003 · ComProblemas/ContentView\.swift · linha **36**, coluna **25**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/LeituraFacil/ComProblemas/ContentView.swift:36:25
```

**O que foi encontrado:** Uma fonte usa um tamanho numérico fixo que pode não acompanhar o Dynamic Type\.

**Impacto para quem usa o app:** Pessoas que precisam ampliar o texto podem continuar vendo uma fonte pequena ou encontrar conteúdo cortado\.

**Como ajustar:** Prefira estilos semânticos como \.body, \.headline e \.title\. Para tipografia personalizada, adote uma fonte relativa a um estilo de texto ou uma medida escalável e permita que o layout cresça\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  34 |                     // SAC003: tamanho em pontos pode não acompanhar a preferência do iPhone.
  35 |                     Text("Um passeio ao ar livre")
> 36 |                         .font(.system(size: 18))
  37 |                         .fontWeight(.semibold)
  38 | 
```

**Antes — exemplo ilustrativo:**

```swift
Text("Resumo do pedido")
    .font(.system(size: 16))
```

**Depois — exemplo ilustrativo:**

```swift
Text("Resumo do pedido")
    .font(.body)
```

**Como validar:** Aumente o tamanho de texto até as maiores categorias de acessibilidade\. Confira leitura, quebras de linha, conteúdo completo e acesso a todos os controles\.

**Antes de concluir:** O valor pode já vir de @ScaledMetric ou de outro mecanismo de escala\. A regra não calcula o tamanho final nem avalia o layout em execução\.

**Referências:**

- [Apple — Typography](<https://developer.apple.com/design/human-interface-guidelines/typography>)
- [WCAG 2\.2 — 1\.4\.4 Resize Text](<https://www.w3.org/TR/WCAG22/#resize-text>)

### 3. Ampliação de texto limitada

**Prioridade Média** · SAC009 · ComProblemas/ContentView\.swift · linha **46**, coluna **25**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/LeituraFacil/ComProblemas/ContentView.swift:46:25
```

**O que foi encontrado:** dynamicTypeSize fixa uma categoria ou limita as maiores categorias de acessibilidade\.

**Impacto para quem usa o app:** O app pode ignorar o tamanho de texto de que a pessoa precisa para ler o conteúdo\.

**Como ajustar:** Remova a restrição e adapte o layout aos tamanhos maiores\. Quando houver uma faixa necessária, preserve as categorias de acessibilidade, inclusive \.accessibility5, e valide todo o conteúdo\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  44 |                     Text("Antes de sair, leve água e escolha um horário confortável para você.")
  45 |                         .font(.body)
> 46 |                         .dynamicTypeSize(.large)
  47 |                         .fixedSize(horizontal: false, vertical: true)
  48 |                 }
```

**Antes — exemplo ilustrativo:**

```swift
Text("Detalhes da entrega")
    .font(.body)
    .dynamicTypeSize(.small ... .large)
```

**Depois — exemplo ilustrativo:**

```swift
Text("Detalhes da entrega")
    .font(.body)
```

**Como validar:** Altere o Dynamic Type nas configurações do dispositivo ou do simulador até o maior tamanho\. Confira se textos e controles crescem sem cortes, sobreposição ou perda de ações\.

**Antes de concluir:** Uma restrição usada apenas em Preview ou testes pode ser intencional\. Confira o uso em produção e as restrições herdadas de elementos pais\.

**Referências:**

- [Apple — dynamicTypeSize](<https://developer.apple.com/documentation/swiftui/view/dynamictypesize%28_:%29>)
- [Apple — Typography](<https://developer.apple.com/design/human-interface-guidelines/typography>)
- [WCAG 2\.2 — 1\.4\.4 Resize Text](<https://www.w3.org/TR/WCAG22/#resize-text>)

## Validação manual que complementa este relatório

- [ ] VoiceOver: percorra os fluxos principais e confira nomes, estados, ordem de foco, agrupamento e anúncios de mudanças.
- [ ] Dynamic Type: teste os maiores tamanhos de acessibilidade, textos longos e os idiomas suportados, sem cortes ou sobreposição.
- [ ] Contraste e cor: confira textos, ícones e estados nos temas claro e escuro; toda informação por cor também precisa de outro indicador.
- [ ] Interação: valide áreas de toque, teclado, Controle por Voz e Controle Assistivo nos dispositivos e plataformas suportados.
- [ ] Movimento e mídia: respeite Reduzir Movimento e revise legendas, transcrições e alternativas para conteúdo audiovisual quando houver.
- [ ] Validação: execute o Accessibility Inspector, registre os resultados e teste os fluxos com pessoas que usam tecnologias assistivas.

Depois dos ajustes, execute o checker novamente e registre a validação manual no PR. Para um possível falso positivo, registre a regra, o trecho e o comportamento observado; remova dados sensíveis antes de compartilhar.

