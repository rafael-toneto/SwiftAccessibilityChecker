import SwiftUI

struct InaccessibleExample: View {
    @State private var isOnline = false
    @State private var notificationsEnabled = true

    var body: some View {
        VStack {
            Button(action: {}) {
                Image(systemName: "trash")
            }

            Image("sales-chart")

            Text("Profile")
                .font(.system(size: 16))

            Button("Close", action: {})
                .frame(width: 32, height: 32)

            Circle()
                .fill(isOnline ? Color.green : Color.red)

            Image(systemName: "person.crop.circle")
                .accessibilityLabel("")

            Toggle("Notifications", isOn: $notificationsEnabled)
                .accessibilityHidden(true)

            Text("Open details")
                .onTapGesture {}

            Text("Account summary")
                .dynamicTypeSize(.large)
        }
    }
}
