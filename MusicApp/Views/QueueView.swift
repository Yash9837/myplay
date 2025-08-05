import SwiftUI

struct QueueView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Queue Info Header
                queueInfoHeader
                
                // Queue List
                queueListContent
            }
            .background(Color.black)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clearQueue()
                    }
                    .disabled(viewModel.queue.isEmpty)
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Queue Info Header
    private var queueInfoHeader: some View {
        VStack(spacing: 12) {
            // Queue Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.queueCount) songs")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let currentSong = viewModel.currentSong {
                        Text("Now Playing: \(currentSong.displayTitle)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Playback Mode Indicators
                HStack(spacing: 16) {
                    if viewModel.shuffleMode {
                        Image(systemName: "shuffle.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    if viewModel.repeatMode != .none {
                        Image(systemName: viewModel.repeatMode.iconName)
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress Bar
            if let currentSong = viewModel.currentSong {
                VStack(spacing: 4) {
                    ProgressView(value: viewModel.progress.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.green)
                    
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
    
    // MARK: - Queue List Content
    private var queueListContent: some View {
        Group {
            if viewModel.queue.isEmpty {
                emptyQueueView
            } else {
                queueListView
            }
        }
    }
    
    // MARK: - Empty Queue View
    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Queue is Empty")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Add songs to start listening")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .background(Color.black)
    }
    
    // MARK: - Queue List View
    private var queueListView: some View {
        List {
            ForEach(Array(viewModel.queue.enumerated()), id: \.element.id) { index, song in
                QueueRowView(
                    song: song,
                    index: index,
                    isCurrentSong: index == viewModel.currentQueueIndex,
                    viewModel: viewModel
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove(perform: moveSongs)
            .onDelete(perform: deleteSongs)
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(.active))
        .background(Color.black)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Move Songs
    private func moveSongs(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        viewModel.moveSongInQueue(from: sourceIndex, to: destination)
    }
    
    // MARK: - Delete Songs
    private func deleteSongs(offsets: IndexSet) {
        for index in offsets {
            viewModel.removeFromQueue(at: index)
        }
    }
}

// MARK: - Queue Row View
struct QueueRowView: View {
    let song: Song
    let index: Int
    let isCurrentSong: Bool
    @ObservedObject var viewModel: MusicPlayerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Song Number
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isCurrentSong ? .green : .gray)
                .frame(width: 30, alignment: .leading)
            
            // Album Art
            albumArtView
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(isCurrentSong ? .green : .white)
                
                Text(song.displayArtist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(song.album)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(song.formattedDuration)
                .font(.caption)
                .foregroundColor(.gray)
            
            // Play Button
            Button(action: {
                viewModel.playSong(at: index)
            }) {
                Image(systemName: isCurrentSong ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isCurrentSong ? .green : .white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentSong ? Color.green.opacity(0.2) : Color(red: 0.1, green: 0.1, blue: 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentSong ? Color.green : Color.clear, lineWidth: 2)
        )
    }
    
    private var albumArtView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            if let albumArtURL = song.albumArtURL, !albumArtURL.isEmpty {
                AsyncImage(url: URL(string: albumArtURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Preview
struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView(viewModel: MusicPlayerViewModel())
    }
}
