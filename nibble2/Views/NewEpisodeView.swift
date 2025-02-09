import SwiftUI

struct NewEpisodeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Text("New episode form coming soon")
            }
            .navigationTitle("New Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NewEpisodeView()
} 