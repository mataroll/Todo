import SwiftUI

struct MoneyView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("כסף")
                .font(.largeTitle.bold())
            Text("בקרוב")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
