import SwiftUI

struct ContentView: View {
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Versão com problemas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        // SAC002: a imagem informa o tempo, mas não tem descrição explícita.
                        Image(systemName: "sun.max.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)

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
                    // SAC003: tamanho em pontos pode não acompanhar a preferência do iPhone.
                    Text("Um passeio ao ar livre")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)

                    Text("Uma caminhada curta pode ser uma boa pausa no dia. Escolha um lugar tranquilo e aproveite o caminho no seu ritmo.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    // SAC009: força o texto a ficar em .large mesmo com fonte maior no sistema.
                    Text("Antes de sair, leve água e escolha um horário confortável para você.")
                        .font(.body)
                        .dynamicTypeSize(.large)
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
