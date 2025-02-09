import SwiftUI

struct HomeView: View {
    @State private var showingNewEpisodeSheet = false
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationStack {
            List {
                EpisodeCard(
                    title: "Sample Episode",
                    description: "This is a sample episode description that demonstrates how the card will look with actual content.",
                    onPlayTap: { showingPlayer = true }
                )
            }
            .navigationTitle("Episodes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewEpisodeSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEpisodeSheet) {
                NewEpisodeView()
            }
            .fullScreenCover(isPresented: $showingPlayer) {
                AudioPlayerView()
            }
        }
    }
}

#Preview {
    HomeView()
} 