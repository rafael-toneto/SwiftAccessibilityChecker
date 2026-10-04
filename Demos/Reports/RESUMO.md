# Resultados da análise estática

[Abrir o painel de relatórios](index.html). Gerados pela CLI real, em uma análise por target. Cada pasta contém HTML, Markdown, texto, JSON e warnings do Xcode.

| App | Versão | Avisos | Regras | Relatório |
| --- | --- | ---: | --- | --- |
| ListaCompras | ComProblemas | 3 | SAC001, SAC004, SAC006 | [Abrir](ListaCompras-ComProblemas/report.html) |
| ListaCompras | Corrigido | 0 | Nenhuma | [Abrir](ListaCompras-Corrigido/report.html) |
| LeituraFacil | ComProblemas | 3 | SAC002, SAC003, SAC009 | [Abrir](LeituraFacil-ComProblemas/report.html) |
| LeituraFacil | Corrigido | 0 | Nenhuma | [Abrir](LeituraFacil-Corrigido/report.html) |
| MinhaRotina | ComProblemas | 3 | SAC005, SAC007, SAC008 | [Abrir](MinhaRotina-ComProblemas/report.html) |
| MinhaRotina | Corrigido | 0 | Nenhuma | [Abrir](MinhaRotina-Corrigido/report.html) |

Zero avisos significa que os arquivos analisados não acionaram as nove regras implementadas. Não certifica acessibilidade: valide a interface em execução com VoiceOver, tamanhos de texto ampliados e Accessibility Inspector.
