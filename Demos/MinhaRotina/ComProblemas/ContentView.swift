import SwiftUI

struct ContentView: View {
    @State private var habitCompleted = false
    @State private var reminderEnabled = false
    @State private var showingTip = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Versão com problemas")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        // SAC005: o estado do hábito é comunicado apenas pela cor.
                        Circle()
                            .fill(habitCompleted ? Color.green : Color.orange)
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Beber um copo de água")
                                .font(.headline)
                            Text("Um pequeno cuidado com você.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Button("Alterar estado") {
                        habitCompleted.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 4)
                } header: {
                    Text("Hábito de hoje")
                } footer: {
                    Text("Marque seu hábito depois de beber água.")
                }

                Section {
                    // SAC007: o controle aparece na tela, mas fica oculto do VoiceOver.
                    Toggle("Mostrar lembrete aqui", isOn: $reminderEnabled)
                        .accessibilityHidden(true)

                    if reminderEnabled {
                        Text("Seu lembrete: reserve uma pausa para beber água.")
                            .font(.callout)
                    }
                } header: {
                    Text("Lembrete")
                } footer: {
                    Text("O lembrete aparece somente nesta tela enquanto o app está aberto.")
                }

                Section("Uma ajudinha") {
                    // SAC008: um texto recebe um gesto sem semântica de botão.
                    Text("Abrir dica")
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingTip = true
                        }
                }
            }
            .navigationTitle("Minha rotina")
            .alert("Uma pausa para você", isPresented: $showingTip) {
                Button("Entendi", role: .cancel) { }
            } message: {
                Text("Deixe um copo de água por perto. Vincular um hábito a uma pausa do dia pode ajudar a lembrá-lo.")
            }
        }
    }
}
