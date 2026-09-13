import SwiftUI

struct AccessibleExample: View {
    @State private var isOnline = false
    @State private var notificationsEnabled = true

    var body: some View {
        VStack {
            Button(action: {}) {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Delete")

            Image("sales-chart")
                .accessibilityLabel("Sales increased by 12 percent")

            Image(decorative: "card-texture")

            Text("Profile")
                .font(.headline)

            Button("Close", action: {})
                .frame(width: 44, height: 44)

            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .overlay {
                    Image(systemName: isOnline ? "checkmark" : "xmark")
                        .accessibilityHidden(true)
                }
                .accessibilityLabel(isOnline ? "Online" : "Offline")

            Toggle("Notifications", isOn: $notificationsEnabled)

            Button("Open details", action: {})

            Text("Account summary")
        }
    }
}
