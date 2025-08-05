//
//  ContentView.swift
//  MusicApp
//
//  Created by user@69 on 04/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()
    @State private var showingQueue = false
    @State private var showingNowPlaying = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Main Tab View
            TabView {
                // Library Tab
                SongListView(viewModel: viewModel, showingNowPlaying: $showingNowPlaying)
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Library")
                    }
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle")
                        Text("Profile")
                    }
            }
            .accentColor(.green) // Spotify green accent
            
            // Mini Player (overlay at bottom with proper spacing)
            if viewModel.currentSong != nil {
                VStack {
                    Spacer()
                    miniPlayerView
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .sheet(isPresented: $showingQueue) {
            QueueView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingNowPlaying) {
            NowPlayingView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Mini Player
    private var miniPlayerView: some View {
        VStack(spacing: 0) {
            // Progress Bar
            if viewModel.currentSong != nil {
                ProgressView(value: viewModel.progress.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.green)
                    .frame(height: 2)
            }
            
            // Mini Player Content
            HStack(spacing: 12) {
                // Album Art
                if let currentSong = viewModel.currentSong {
                    albumArtView(for: currentSong)
                }
                
                // Song Info
                VStack(alignment: .leading, spacing: 2) {
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Text(currentSong.displayArtist)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 16) {
                    // Previous Button
                    Button(action: {
                        viewModel.previousSong()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.hasPreviousSong ? .white : .gray)
                    }
                    .disabled(!viewModel.hasPreviousSong)
                    
                    // Play/Pause Button
                    Button(action: {
                        viewModel.playPause()
                    }) {
                        Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .disabled(viewModel.playbackState == .loading)
                    
                    // Next Button
                    Button(action: {
                        viewModel.nextSong()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.hasNextSong ? .white : .gray)
                    }
                    .disabled(!viewModel.hasNextSong)
                    
                    // Queue Button
                    Button(action: {
                        showingQueue = true
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1)) // Dark background
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .padding(.bottom, 49) // Add padding to avoid TabBar overlap
        .onTapGesture {
            // Show Now Playing when mini player is tapped
            if viewModel.currentSong != nil {
                showingNowPlaying = true
            }
        }
    }
    
    // MARK: - Album Art View
    private func albumArtView(for song: Song) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            if let albumArtURL = song.albumArtURL, !albumArtURL.isEmpty {
                AsyncImage(url: URL(string: albumArtURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
