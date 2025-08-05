import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentSong = viewModel.currentSong {
                    expandedNowPlayingView(for: currentSong)
                } else {
                    collapsedNowPlayingView
                }
            }
            .background(Color.black)
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentSong != nil)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Show queue or other options
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Expanded Now Playing View
    private func expandedNowPlayingView(for song: Song) -> some View {
        VStack(spacing: 20) {
            // Album Art
            albumArtView(for: song)
            
            // Song Info
            songInfoView(for: song)
            
            // Progress Bar
            progressView
            
            // Playback Controls
            playbackControlsView
            
            // Additional Controls
            additionalControlsView
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Album Art
    private func albumArtView(for song: Song) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 280, height: 280)
            
            if let albumArtURL = song.albumArtURL, !albumArtURL.isEmpty {
                AsyncImage(url: URL(string: albumArtURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }
        }
        .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Song Info
    private func songInfoView(for song: Song) -> some View {
        VStack(spacing: 8) {
            Text(song.displayTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.white)
            
            Text(song.displayArtist)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(song.album)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 8) {
            // Progress Slider
            Slider(
                value: Binding(
                    get: { viewModel.progress.progress },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...1
            )
            .accentColor(.green)
            
            // Time Labels
            HStack {
                Text(viewModel.progress.formattedCurrentTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(viewModel.progress.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Playback Controls
    private var playbackControlsView: some View {
        HStack(spacing: 40) {
            // Previous Button
            Button(action: {
                viewModel.previousSong()
            }) {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(viewModel.hasPreviousSong ? .white : .gray)
            }
            .disabled(!viewModel.hasPreviousSong)
            
            // Play/Pause Button
            Button(action: {
                viewModel.playPause()
            }) {
                Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            .disabled(viewModel.playbackState == .loading)
            
            // Next Button
            Button(action: {
                viewModel.nextSong()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(viewModel.hasNextSong ? .white : .gray)
            }
            .disabled(!viewModel.hasNextSong)
        }
    }
    
    // MARK: - Additional Controls
    private var additionalControlsView: some View {
        HStack(spacing: 40) {
            // Shuffle Button
            Button(action: {
                viewModel.toggleShuffle()
            }) {
                Image(systemName: viewModel.shuffleMode ? "shuffle.circle.fill" : "shuffle")
                    .font(.title2)
                    .foregroundColor(viewModel.shuffleMode ? .green : .white)
            }
            
            // Repeat Button
            Button(action: {
                viewModel.toggleRepeatMode()
            }) {
                Image(systemName: viewModel.repeatMode.iconName)
                    .font(.title2)
                    .foregroundColor(viewModel.repeatMode != .none ? .green : .white)
            }
            
            // Queue Button
            Button(action: {
                // Show queue view
            }) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Collapsed Now Playing View
    private var collapsedNowPlayingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No song playing")
                .font(.title3)
                .foregroundColor(.white)
            
            Text("Select a song to start playing")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView(viewModel: MusicPlayerViewModel())
    }
}
