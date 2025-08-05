import Foundation
import SwiftUI

struct Song: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let albumArtURL: String?
    let source: MusicSourceType
    let sourceID: String
    let localFilePath: String? // Path to local audio file in bundle
    
    // Computed properties
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var displayTitle: String {
        return title.isEmpty ? "Unknown Track" : title
    }
    
    var displayArtist: String {
        return artist.isEmpty ? "Unknown Artist" : artist
    }
    
    // Equatable implementation
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
