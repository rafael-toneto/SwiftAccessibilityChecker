import SwiftUI

struct ContentView: View {
    @State private var hasMilk = true
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Uma compra pequena para o café da manhã.")
                    Text("Versão com problemas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Minha lista") {
                    if hasMilk {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Leite")
                                    .font(.headline)
                                Text("Caixa de 1 litro")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // SAC001: só o desenho não explica a ação ao leitor de tela.
                            Button(role: .destructive) {
                                hasMilk = false
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Text("Sua lista está vazia.")
                            .foregroundStyle(.secondary)
                        Button("Adicionar leite") {
                            quantity = 1
                            hasMilk = true
                        }
                    }
                }

                if hasMilk {
                    Section {
                        // SAC006: o valor acessível foi declarado, mas ficou vazio.
                        Text("Unidades: \(quantity)")
                            .accessibilityLabel("Quantidade de leite")
                            .accessibilityValue("")

                        HStack(spacing: 20) {
                            Button {
                                quantity = max(1, quantity - 1)
                            } label: {
                                Text("−")
                                    .font(.title2)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Diminuir quantidade de leite")
                            .disabled(quantity == 1)

                            // SAC004: a área explícita de 28 × 28 pt dificulta o toque.
                            Button {
                                quantity += 1
                            } label: {
                                Text("+")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 28, height: 28)
                            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .accessibilityLabel("Aumentar quantidade de leite")
                        }
                        .foregroundStyle(.tint)
                    } header: {
                        Text("Quantidade")
                    } footer: {
                        Text("Use − e + para ajustar as unidades. Toque na lixeira para remover o leite.")
                    }
                }
            }
            .navigationTitle("Lista de compras")
            .tint(.blue)
        }
    }
}
