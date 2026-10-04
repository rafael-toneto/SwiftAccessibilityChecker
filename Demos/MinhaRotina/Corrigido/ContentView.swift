import SwiftUI

struct ContentView: View {
    @State private var habitCompleted = false
    @State private var reminderEnabled = false
    @State private var showingTip = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Versão corrigida")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        // SAC005 corrigido: símbolo, rótulo e texto também informam o estado.
                        Circle()
                            .fill(habitCompleted ? Color.green : Color.orange)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: habitCompleted ? "checkmark" : "minus")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .accessibilityHidden(true)
                            }
                            .accessibilityLabel(habitCompleted ? "Hábito concluído" : "Hábito pendente")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Beber um copo de água")
                                .font(.headline)
                            Text(habitCompleted ? "Concluído por hoje" : "Ainda não concluído")
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
                    // SAC007 corrigido: o Toggle nativo permanece disponível ao VoiceOver.
                    Toggle("Mostrar lembrete aqui", isOn: $reminderEnabled)

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
                    // SAC008 corrigido: Button oferece a ação com semântica nativa.
                    Button("Abrir dica") {
                        showingTip = true
                    }
                    .padding(.vertical, 12)
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
