//
//  ProfileView.swift
//  MusicApp
//
//  Created by user@69 on 05/08/25.
//
import SwiftUI


// MARK: - Profile View
struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Yash Gupta")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Premium Member")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Your Stats")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(title: "Songs Played", value: "1,247", icon: "music.note")
                            StatCard(title: "Hours Listened", value: "89.5", icon: "clock")
                        }
                    }
                    
                    // Recent Activity
                    VStack(spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ActivityRow(title: "Added to Favorites", subtitle: "Bohemian Rhapsody - Queen", time: "2 hours ago")
                            ActivityRow(title: "Created Playlist", subtitle: "Workout Mix", time: "1 day ago")
                            ActivityRow(title: "Listened to", subtitle: "Blinding Lights - The Weeknd", time: "3 days ago")
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color.black)
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}
