import SwiftUI

struct EpisodeCard: View {
    let title: String
    let description: String
    let onPlayTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Button(action: onPlayTap) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    EpisodeCard(
        title: "Sample Episode",
        description: "This is a sample episode description.",
        onPlayTap: {}
    )
} 