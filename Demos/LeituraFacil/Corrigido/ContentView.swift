import SwiftUI

struct ContentView: View {
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Versão corrigida")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                            // SAC002 corrigido: transmite o significado da imagem.
                            .accessibilityLabel("Tempo ensolarado")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Previsão para hoje")
                                .font(.headline)
                            Text("24 °C · Manhã")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Boletim de exemplo")
                } footer: {
                    Text("Dados fictícios para esta demonstração.")
                }

                Section("Leitura do dia") {
                    Text("Um passeio ao ar livre")
                        // SAC003 corrigido: estilo semântico acompanha o Dynamic Type.
                        .font(.headline)

                    Text("Uma caminhada curta pode ser uma boa pausa no dia. Escolha um lugar tranquilo e aproveite o caminho no seu ritmo.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    // SAC009 corrigido: usa o tamanho escolhido no sistema, sem restrição local.
                    Text("Antes de sair, leve água e escolha um horário confortável para você.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    Button {
                        isSaved.toggle()
                    } label: {
                        Label(isSaved ? "Remover dos salvos" : "Salvar leitura", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)

                    Text(isSaved ? "Leitura salva nesta sessão." : "Você ainda não salvou esta leitura.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Leitura fácil")
            .tint(.indigo)
        }
    }
}
