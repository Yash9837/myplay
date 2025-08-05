import Foundation
import Combine
import AVFoundation

// MARK: - Music Source Protocol
protocol MusicSource {
    var sourceType: MusicSourceType { get }
    var displayName: String { get }
    
    func fetchSongs() -> AnyPublisher<[Song], Error>
    func searchSongs(query: String) -> AnyPublisher<[Song], Error>
    func getSongDetails(id: String) -> AnyPublisher<Song, Error>
}

// MARK: - Music Source Types
enum MusicSourceType: String, CaseIterable, Codable {
    case local = "local"
    case audioDB = "audiodb"
    case lastFM = "last_fm"
    
    var displayName: String {
        switch self {
        case .local:
            return "Local Music"
        case .audioDB:
            return "AudioDB"
        case .lastFM:
            return "Last.fm"
        }
    }
    
    var iconName: String {
        switch self {
        case .local:
            return "music.note.list"
        case .audioDB:
            return "music.note"
        case .lastFM:
            return "waveform"
        }
    }
}

// MARK: - Music Source Factory
class MusicSourceFactory {
    static func createSource(for type: MusicSourceType) -> MusicSource {
        switch type {
        case .local:
            return LocalMusicSource()
        case .audioDB:
            return AudioDBMusicSource()
        case .lastFM:
            return LastFMSource()
        }
    }
}

// MARK: - Local Music Source (Real MP3 Files)
class LocalMusicSource: MusicSource {
    let sourceType: MusicSourceType = .local
    let displayName: String = "Local Music"
    
    func fetchSongs() -> AnyPublisher<[Song], Error> {
        // Scan for MP3 files in the app bundle
        let songs = getLocalSongs()
        
        // Print duration information for debugging
        print("📊 Local Songs Duration Report:")
        for song in songs {
            print("   🎵 \(song.title): \(song.formattedDuration) (\(song.duration) seconds)")
        }
        
        return Just(songs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        let allSongs = getLocalSongs()
        let filteredSongs = allSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query) ||
            song.album.localizedCaseInsensitiveContains(query)
        }
        return Just(filteredSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getSongDetails(id: String) -> AnyPublisher<Song, Error> {
        let songs = getLocalSongs()
        if let song = songs.first(where: { $0.id == id }) {
            return Just(song)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: NSError(domain: "LocalMusicSource", code: 404, userInfo: [NSLocalizedDescriptionKey: "Song not found"]))
                .eraseToAnyPublisher()
        }
    }
    
    private func getLocalSongs() -> [Song] {
        // Define your local songs with metadata
        let localSongsData = [
            (id: "bring_me_back", title: "Bring Me Back", artist: "Unknown Artist", album: "Unknown Album", filename: "bring-me-back-283196.mp3", albumArtURL: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop"),
            (id: "bethlehem", title: "How Far Is It To Bethlehem", artist: "Traditional", album: "Christmas Carols", filename: "how-far-is-it-to-bethlehem-traditional-english-christmas-carol-178351.mp3", albumArtURL: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop"),
            (id: "hold_me_tight", title: "Hold Me Tight", artist: "Unknown Artist", album: "Unknown Album", filename: "hold-me-tight-278286.mp3", albumArtURL: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop"),
            (id: "coat_for_rain", title: "Coat For The Rain", artist: "Pandelion", album: "Unknown Album", filename: "coat-for-the-rain-pandelion-175095.mp3", albumArtURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop"),
            (id: "celtic_background", title: "Celtic Irish Scottish Background Music", artist: "Traditional", album: "Celtic Music", filename: "celtic-irish-scottish-tin-whistle-background-music-10455.mp3", albumArtURL: "https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop")
            
        ]
        
        var songs: [Song] = []
        
        for songData in localSongsData {
            // Get the real duration from the audio file
            let realDuration = getAudioDuration(for: songData.filename)
            
            let song = Song(
                id: songData.id,
                title: songData.title,
                artist: songData.artist,
                album: songData.album,
                duration: realDuration,
                albumArtURL: songData.albumArtURL,
                source: .local,
                sourceID: songData.id,
                localFilePath: songData.filename
            )
            songs.append(song)
        }
        
        return songs
    }
    
    // Helper function to get real audio duration
    private func getAudioDuration(for filename: String) -> TimeInterval {
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else {
            print("⚠️ Could not find audio file: \(filename)")
            return 180.0 // Fallback duration
        }
        
        do {
            let asset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration)
            print("🎵 \(filename): Real duration = \(duration) seconds")
            return duration
        } catch {
            print("❌ Error getting duration for \(filename): \(error)")
            return 180.0 // Fallback duration
        }
    }
}

// MARK: - AudioDB Music Source
class AudioDBMusicSource: MusicSource {
    let sourceType: MusicSourceType = .audioDB
    let displayName: String = "AudioDB"
    
    private let apiService = APIService.shared
    
    func fetchSongs() -> AnyPublisher<[Song], Error> {
        // Fetch popular tracks from AudioDB
        return apiService.fetchSongsFromAudioDB(artist: "Queen")
            .catch { error in
                // Fallback to mock data if API fails
                print("AudioDB API Error: \(error.localizedDescription)")
                return self.getMockSongs()
            }
            .eraseToAnyPublisher()
    }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        return apiService.searchSongsFromAudioDB(query: query)
            .catch { error in
                // Fallback to local search if API fails
                print("AudioDB Search Error: \(error.localizedDescription)")
                return self.getMockSongs()
                    .map { songs in
                        songs.filter { song in
                            song.title.localizedCaseInsensitiveContains(query) ||
                            song.artist.localizedCaseInsensitiveContains(query) ||
                            song.album.localizedCaseInsensitiveContains(query)
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getSongDetails(id: String) -> AnyPublisher<Song, Error> {
        return fetchSongs()
            .map { songs in
                songs.first { $0.id == id }
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private func getMockSongs() -> AnyPublisher<[Song], Error> {
        let mockSongs = [
            Song(id: "audiodb_1", title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 354, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/Queen_A_Night_At_The_Opera.png", source: .audioDB, sourceID: "audiodb_1", localFilePath: nil),
            Song(id: "audiodb_2", title: "We Will Rock You", artist: "Queen", album: "News of the World", duration: 122, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/e/ea/Queen_News_Of_The_World.png", source: .audioDB, sourceID: "audiodb_2", localFilePath: nil),
            Song(id: "audiodb_3", title: "Another One Bites the Dust", artist: "Queen", album: "The Game", duration: 213, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/16/Queen_The_Game.png", source: .audioDB, sourceID: "audiodb_3", localFilePath: nil)
        ]
        return Just(mockSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Last.fm Source
class LastFMSource: MusicSource {
    let sourceType: MusicSourceType = .lastFM
    let displayName: String = "Last.fm"
    
    private let apiService = APIService.shared
    
    func fetchSongs() -> AnyPublisher<[Song], Error> {
        // Fetch popular tracks from Last.fm
        return apiService.fetchSongsFromLastFM(artist: "The Weeknd")
            .catch { error in
                // Fallback to mock data if API fails
                print("Last.fm API Error: \(error.localizedDescription)")
                return self.getMockSongs()
            }
            .eraseToAnyPublisher()
    }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        return apiService.searchSongsFromLastFM(query: query)
            .catch { error in
                // Fallback to local search if API fails
                print("Last.fm Search Error: \(error.localizedDescription)")
                return self.getMockSongs()
                    .map { songs in
                        songs.filter { song in
                            song.title.localizedCaseInsensitiveContains(query) ||
                            song.artist.localizedCaseInsensitiveContains(query) ||
                            song.album.localizedCaseInsensitiveContains(query)
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getSongDetails(id: String) -> AnyPublisher<Song, Error> {
        return fetchSongs()
            .map { songs in
                songs.first { $0.id == id }
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private func getMockSongs() -> AnyPublisher<[Song], Error> {
        let mockSongs = [
            Song(id: "lastfm_1", title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/The_Weeknd_-_After_Hours.png", source: .lastFM, sourceID: "lastfm_1", localFilePath: nil),
            Song(id: "lastfm_2", title: "Levitating", artist: "Dua Lipa", album: "Future Nostalgia", duration: 203, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/1c/Dua_Lipa_-_Future_Nostalgia.png", source: .lastFM, sourceID: "lastfm_2", localFilePath: nil),
            Song(id: "lastfm_3", title: "Watermelon Sugar", artist: "Harry Styles", album: "Fine Line", duration: 174, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3f/Harry_Styles_-_Fine_Line.png", source: .lastFM, sourceID: "lastfm_3", localFilePath: nil),
            Song(id: "lastfm_4", title: "Dance Monkey", artist: "Tones and I", album: "The Kids Are Coming", duration: 209, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/8/8a/Tones_and_I_-_The_Kids_Are_Coming.png", source: .lastFM, sourceID: "lastfm_4", localFilePath: nil),
            Song(id: "lastfm_5", title: "Shape of You", artist: "Ed Sheeran", album: "÷", duration: 233, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/45/Ed_Sheeran_-_%C3%B7.png", source: .lastFM, sourceID: "lastfm_5", localFilePath: nil)
        ]
        return Just(mockSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
