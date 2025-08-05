import SwiftUI

struct SongListView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Binding var showingNowPlaying: Bool
    @State private var showingSourcePicker = false
    @State private var layoutMode: LayoutMode = .list
    
    enum LayoutMode: String, CaseIterable {
        case list = "list"
        case grid = "grid"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBarView
                
                // Song List
                songListContent
            }
            .background(Color.black)
            .navigationTitle("Music Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sourceSelectionButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Layout Toggle
                        Button(action: {
                            layoutMode = layoutMode == .list ? .grid : .list
                        }) {
                            Image(systemName: layoutMode.icon)
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Button("Play All") {
                            viewModel.playAllSongs()
                            if viewModel.currentSong != nil {
                                showingNowPlaying = true
                            }
                        }
                        .disabled(viewModel.songs.isEmpty)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingSourcePicker) {
                SourcePickerView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Source Selection Button
    private var sourceSelectionButton: some View {
        Button(action: {
            showingSourcePicker = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.selectedSource.iconName)
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .medium))
                
                Text(viewModel.selectedSource.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search songs, artists, or albums", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Song List Content
    private var songListContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredSongs.isEmpty {
                emptyStateView
            } else {
                if layoutMode == .list {
                    songListView
                } else {
                    songGridView
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            
            Text("Loading songs...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(viewModel.searchText.isEmpty ? "No songs available" : "No songs found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(viewModel.searchText.isEmpty ? "Try changing the music source" : "Try a different search term")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Song List View
    private var songListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredSongs) { song in
                    SongRowView(song: song, viewModel: viewModel, showingNowPlaying: $showingNowPlaying)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.changeMusicSource(to: viewModel.selectedSource)
        }
    }
    
    // MARK: - Song Grid View
    private var songGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.filteredSongs) { song in
                    SongCardView(song: song, viewModel: viewModel, showingNowPlaying: $showingNowPlaying)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.changeMusicSource(to: viewModel.selectedSource)
        }
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: Song
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Binding var showingNowPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Album Art
            albumArtView
            
            // Song Info
            VStack(alignment: .leading, spacing: 6) {
                Text(song.displayTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Text(song.displayArtist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(song.album)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration and Play Button
            VStack(alignment: .trailing, spacing: 8) {
                Text(song.formattedDuration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Button(action: {
                    viewModel.playSong(song)
                    showingNowPlaying = true
                }) {
                    Image(systemName: viewModel.isCurrentSong(song) ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.isCurrentSong(song) ? .green : .white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.isCurrentSong(song) ? Color.green.opacity(0.2) : Color(red: 0.1, green: 0.1, blue: 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.isCurrentSong(song) ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
    
    private var albumArtView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 56, height: 56)
            
            if let albumArtURL = song.albumArtURL, !albumArtURL.isEmpty {
                AsyncImage(url: URL(string: albumArtURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Song Card View (Grid Layout)
struct SongCardView: View {
    let song: Song
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Binding var showingNowPlaying: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 140)
                
                if let albumArtURL = song.albumArtURL, !albumArtURL.isEmpty {
                    AsyncImage(url: URL(string: albumArtURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Play Button Overlay
                Button(action: {
                    viewModel.playSong(song)
                    showingNowPlaying = true
                }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: viewModel.isCurrentSong(song) ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .opacity(viewModel.isCurrentSong(song) ? 1 : 0.8)
            }
            
            // Song Info
            VStack(spacing: 4) {
                Text(song.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(song.displayArtist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(song.formattedDuration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.isCurrentSong(song) ? Color.green.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Source Picker View
struct SourcePickerView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(MusicSourceType.allCases, id: \.self) { sourceType in
                    Button(action: {
                        viewModel.changeMusicSource(to: sourceType)
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: sourceType.iconName)
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24)
                            
                            Text(sourceType.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if viewModel.selectedSource == sourceType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color(red:0.1, green:0.1, blue:0.1))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.black)
            .scrollContentBackground(.hidden)
            .navigationTitle("Select Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Preview
struct SongListView_Previews: PreviewProvider {
    static var previews: some View {
        SongListView(viewModel: MusicPlayerViewModel(), showingNowPlaying: .constant(false))
    }
}
