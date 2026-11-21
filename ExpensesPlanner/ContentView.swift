import SwiftUI

struct ContentView: View {
    static let title = "ExpensesPlanner"
    static let message = "Your expense planning workspace is ready."

    var body: some View {
        VStack(spacing: 12) {
            Text(Self.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityIdentifier("provisionalTitle")

            Text(Self.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("provisionalMessage")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
