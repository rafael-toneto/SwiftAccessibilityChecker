# Relatório de acessibilidade

Swift Accessibility Checker · Gerado em 2026-10-04T21:13:33Z

## Resumo

**3 achado(s) para revisar** em **1 arquivo(s)**. Arquivos Swift analisados: **2**.

Alta: 2 · Média: 0 · Baixa: 1.

> Esta análise estática identifica padrões de risco no código SwiftUI; não executa o app nem certifica conformidade com todas as diretrizes Apple ou WCAG. Os achados precisam de revisão no contexto da interface. A ausência de avisos não garante acessibilidade.

### Escopo da execução

Caminhos de entrada:

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/MinhaRotina/ComProblemas/ContentView.swift
```

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/MinhaRotina/Shared/App.swift
```

## Por onde começar

Revise os itens de prioridade **alta** primeiro. A prioridade estima o possível impacto; ela não é um nível de conformidade WCAG. Confirme o contexto, aplique a correção e valide no app. Mais de uma regra pode apontar para o mesmo componente.

| Prioridade | Regra | O que revisar | Ocorrências |
| --- | --- | --- | ---: |
| Alta | SAC007 | Controle oculto para tecnologias assistivas | 1 |
| Alta | SAC008 | Ação depende de um gesto personalizado | 1 |
| Baixa | SAC005 | Estado possivelmente indicado apenas por cor | 1 |

### Arquivos com achados

| Arquivo | Ocorrências |
| --- | ---: |
| ComProblemas/ContentView\.swift | 3 |

## Ajustes no código

As ocorrências estão ordenadas por prioridade, arquivo e posição. Os exemplos são **ilustrativos**: adapte nomes, estados, localização e layout ao projeto. O trecho encontrado é mostrado separadamente.

### 1. Controle oculto para tecnologias assistivas

**Prioridade Alta** · SAC007 · ComProblemas/ContentView\.swift · linha **46**, coluna **25**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/MinhaRotina/ComProblemas/ContentView.swift:46:25
```

**O que foi encontrado:** O controle, ou um contêiner que o contém, usa accessibilityHidden\(true\)\.

**Impacto para quem usa o app:** A ação pode desaparecer da navegação por VoiceOver e ficar indisponível para parte das pessoas\.

**Como ajustar:** Remova accessibilityHidden\(true\) do controle quando a ação precisar estar disponível\. Se ele duplicar uma ação, confirme que existe um equivalente acessível, com o mesmo resultado e no contexto adequado\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  44 |                     // SAC007: o controle aparece na tela, mas fica oculto do VoiceOver.
  45 |                     Toggle("Mostrar lembrete aqui", isOn: $reminderEnabled)
> 46 |                         .accessibilityHidden(true)
  47 | 
  48 |                     if reminderEnabled {
```

**Antes — exemplo ilustrativo:**

```swift
Button("Continuar", action: continuar)
    .accessibilityHidden(true)
```

**Depois — exemplo ilustrativo:**

```swift
Button("Continuar", action: continuar)
```

**Como validar:** Navegue pela tela com VoiceOver e execute a ação\. Confirme que ela pode ser encontrada e concluída sem depender do controle oculto\.

**Antes de concluir:** Ocultar um controle duplicado pode ser intencional se o elemento pai ou outro controle oferece a mesma ação de forma acessível\. Verifique isso no app\.

**Referências:**

- [Apple — accessibilityHidden](<https://developer.apple.com/documentation/swiftui/view/accessibilityhidden%28_:%29>)
- [WCAG 2\.2 — 4\.1\.2 Name, Role, Value](<https://www.w3.org/TR/WCAG22/#name-role-value>)

### 2. Ação depende de um gesto personalizado

**Prioridade Alta** · SAC008 · ComProblemas/ContentView\.swift · linha **65**, coluna **25**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/MinhaRotina/ComProblemas/ContentView.swift:65:25
```

**O que foi encontrado:** Foi encontrado um gesto de toque ou pressão prolongada sem uma ação acessível equivalente reconhecida pela regra\.

**Impacto para quem usa o app:** A ação pode não ser descoberta ou executada com VoiceOver, Controle Assistivo ou teclado\.

**Como ajustar:** Para uma ação simples, prefira Button ou outro controle padrão\. Se o gesto precisar permanecer, exponha uma ação equivalente com accessibilityAction ou accessibilityRepresentation e valide sua operação\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  63 |                         .padding(.vertical, 12)
  64 |                         .contentShape(Rectangle())
> 65 |                         .onTapGesture {
  66 |                             showingTip = true
  67 |                         }
```

**Antes — exemplo ilustrativo:**

```swift
Text("Abrir detalhes")
    .onTapGesture { abrirDetalhes() }
```

**Depois — exemplo ilustrativo:**

```swift
Button("Abrir detalhes", action: abrirDetalhes)
```

**Como validar:** Localize e execute a ação usando VoiceOver e os métodos de entrada suportados pelo app\. Gestos com múltiplos toques ou pressão prolongada também precisam de uma alternativa operável\.

**Antes de concluir:** Adicionar apenas um nome ou a característica \.isButton não garante que a ação funcione com todas as tecnologias assistivas\. A equivalência precisa ser testada em execução\.

**Referências:**

- [Apple — Accessible controls](<https://developer.apple.com/documentation/swiftui/accessible-controls>)
- [WCAG 2\.2 — 2\.1\.1 Keyboard](<https://www.w3.org/TR/WCAG22/#keyboard>)
- [WCAG 2\.2 — 4\.1\.2 Name, Role, Value](<https://www.w3.org/TR/WCAG22/#name-role-value>)

### 3. Estado possivelmente indicado apenas por cor

**Prioridade Baixa** · SAC005 · ComProblemas/ContentView\.swift · linha **19**, coluna **29**

**Localização original para abrir no editor:**

```
/Users/rafaeltoneto/Documents/TCC/SwiftAccessibilityChecker/Demos/MinhaRotina/ComProblemas/ContentView.swift:19:29
```

**O que foi encontrado:** Uma cor muda conforme o estado, sem uma alternativa reconhecida neste trecho\.

**Impacto para quem usa o app:** Pessoas com daltonismo ou baixa visão podem não distinguir estados como sucesso, erro ou seleção\.

**Como ajustar:** Acrescente texto visível, forma ou símbolo que também mude com o estado\. Exponha o significado para o VoiceOver\. Um accessibilityValue isolado não cria uma alternativa visual à cor\.

**Trecho encontrado (linha apontada marcada com >):**

```text
  17 |                         // SAC005: o estado do hábito é comunicado apenas pela cor.
  18 |                         Circle()
> 19 |                             .fill(habitCompleted ? Color.green : Color.orange)
  20 |                             .frame(width: 44, height: 44)
  21 | 
```

**Antes — exemplo ilustrativo:**

```swift
Circle()
    .fill(concluido ? Color.green : Color.red)
```

**Depois — exemplo ilustrativo:**

```swift
Label {
    Text(concluido ? "Concluído" : "Pendente")
} icon: {
    Image(systemName: concluido ? "checkmark.circle" : "clock")
}
.foregroundStyle(concluido ? Color.green : Color.red)
```

**Como validar:** Confira os estados sem depender da cor, por exemplo em escala de cinza\. Com VoiceOver, verifique se o estado atual é compreensível\.

**Antes de concluir:** Uma legenda ou descrição em outro elemento pode já resolver o problema\. Este aviso não mede contraste nem confirma que a cor seja o único indicador\.

**Referências:**

- [Apple — Color](<https://developer.apple.com/design/human-interface-guidelines/color>)
- [WCAG 2\.2 — 1\.4\.1 Use of Color](<https://www.w3.org/TR/WCAG22/#use-of-color>)

## Validação manual que complementa este relatório

- [ ] VoiceOver: percorra os fluxos principais e confira nomes, estados, ordem de foco, agrupamento e anúncios de mudanças.
- [ ] Dynamic Type: teste os maiores tamanhos de acessibilidade, textos longos e os idiomas suportados, sem cortes ou sobreposição.
- [ ] Contraste e cor: confira textos, ícones e estados nos temas claro e escuro; toda informação por cor também precisa de outro indicador.
- [ ] Interação: valide áreas de toque, teclado, Controle por Voz e Controle Assistivo nos dispositivos e plataformas suportados.
- [ ] Movimento e mídia: respeite Reduzir Movimento e revise legendas, transcrições e alternativas para conteúdo audiovisual quando houver.
- [ ] Validação: execute o Accessibility Inspector, registre os resultados e teste os fluxos com pessoas que usam tecnologias assistivas.

Depois dos ajustes, execute o checker novamente e registre a validação manual no PR. Para um possível falso positivo, registre a regra, o trecho e o comportamento observado; remova dados sensíveis antes de compartilhar.

