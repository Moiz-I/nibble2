import SwiftUI
import AVKit
import AVFoundation
import MediaPlayer

class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var playbackRate: Double = 1.0
    @Published var isSeeking = false
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private let seekDuration: Double = 15
    
    init() {
        setupAudioSession()
        loadAudio()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play/Pause
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Skip forward/backward
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: seekDuration)]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.seekForward()
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: seekDuration)]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.seekBackward()
            return .success
        }
        
        // Seeking
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
        
        // Update Now Playing info
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Sample Episode"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func loadAudio() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") else {
            print("Could not find audio file")
            return
        }
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        Task {
            do {
                let duration = try await asset.load(.duration)
                DispatchQueue.main.async {
                    self.duration = duration.seconds
                    self.updateNowPlayingInfo()
                }
            } catch {
                print("Error loading duration: \(error)")
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        setupTimeObserver()
    }
    
    @objc private func playerItemDidReachEnd() {
        isPlaying = false
        currentTime = 0
        player?.seek(to: .zero)
        updateNowPlayingInfo()
    }
    
    private func setupTimeObserver() {
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            self.currentTime = time.seconds
            self.updateNowPlayingInfo()
        }
    }
    
    func play() {
        isPlaying = true
        player?.play()
        updateNowPlayingInfo()
    }
    
    func pause() {
        isPlaying = false
        player?.pause()
        updateNowPlayingInfo()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seekForward() {
        seek(to: currentTime + seekDuration)
    }
    
    func seekBackward() {
        seek(to: currentTime - seekDuration)
    }
    
    func seek(to time: Double) {
        let boundedTime = max(0, min(time, duration))
        let cmTime = CMTime(seconds: boundedTime, preferredTimescale: 600)
        
        self.currentTime = boundedTime
        
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let self = self, finished else { return }
            self.updateNowPlayingInfo()
        }
    }
    
    func startSeeking() {
        isSeeking = true
    }
    
    func endSeeking() {
        isSeeking = false
        seek(to: currentTime)
    }
    
    func setPlaybackRate(_ rate: Double) {
        playbackRate = rate
        player?.rate = Float(rate)
        updateNowPlayingInfo()
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

struct AudioPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AudioPlayerViewModel()
    
    private let playbackRates = [1.0, 1.5, 2.0]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Album art placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 40)
                
                // Title
                Text("Sample Episode")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Playback progress
                VStack(spacing: 8) {
                    Slider(
                        value: $viewModel.currentTime,
                        in: 0...max(1, viewModel.duration)
                    ) { isDragging in
                        if isDragging {
                            viewModel.startSeeking()
                        } else {
                            viewModel.endSeeking()
                        }
                    }
                    
                    HStack {
                        Text(formatTime(viewModel.currentTime))
                        Spacer()
                        Text(formatTime(viewModel.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Playback controls
                HStack(spacing: 40) {
                    Button(action: viewModel.seekBackward) {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    }
                    
                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                    
                    Button(action: viewModel.seekForward) {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                }
                
                // Playback speed
                Picker("Playback Speed", selection: .init(
                    get: { viewModel.playbackRate },
                    set: { viewModel.setPlaybackRate($0) }
                )) {
                    ForEach(playbackRates, id: \.self) { rate in
                        Text("\(String(format: "%.1fx", rate))")
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds / 60)
        let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioPlayerView()
} 
