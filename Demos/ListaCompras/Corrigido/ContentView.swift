import SwiftUI

struct ContentView: View {
    @State private var hasMilk = true
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Uma compra pequena para o café da manhã.")
                    Text("Versão corrigida")
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

                            Button(role: .destructive) {
                                hasMilk = false
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.borderless)
                            // SAC001 corrigido: descreve a ação e o item afetado.
                            .accessibilityLabel("Remover leite da lista")
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
                        Text("Unidades: \(quantity)")
                            .accessibilityLabel("Quantidade de leite")
                            // SAC006 corrigido: o leitor de tela recebe o valor atual.
                            .accessibilityValue(quantity == 1 ? "1 unidade" : "\(quantity) unidades")

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

                            Button {
                                quantity += 1
                            } label: {
                                Text("+")
                                    .font(.title2)
                                    // SAC004 corrigido: o conteúdo do botão mede 48 × 48 pt.
                                    .frame(width: 48, height: 48)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
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
