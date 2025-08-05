import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private init() {
        // Test network connectivity on startup
        testNetworkConnectivity()
    }
    
    // MARK: - Network Testing
    private func testNetworkConnectivity() {
        print("🧪 Testing network connectivity...")
        
        // Test basic network connectivity
        guard let testURL = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }
        
        URLSession.shared.dataTaskPublisher(for: testURL)
            .map { data, response -> String in
                let httpResponse = response as? HTTPURLResponse
                print("📡 Network test status: \(httpResponse?.statusCode ?? 0)")
                print("📦 Network test response size: \(data.count) bytes")
                print("🔍 Network test response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                return String(data: data, encoding: .utf8) ?? ""
            }
            .catch { error -> AnyPublisher<String, Never> in
                print("❌ Network test failed: \(error.localizedDescription)")
                return Just("").eraseToAnyPublisher()
            }
            .sink { _ in
                print("✅ Network connectivity test completed")
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - MusicBrainz API (Working Alternative)
    private let musicBrainzBaseURL = "https://musicbrainz.org/ws/2"
    
    // MARK: - Last.fm API
    private let lastFMBaseURL = "https://ws.audioscrobbler.com/2.0"
    private let lastFMAPIKey = "a725501d4cf727262a8e5d2599c0796f"
    
    func fetchSongsFromLastFM(artist: String) -> AnyPublisher<[Song], Error> {
        print("🎯 Fetching songs for '\(artist)' from Last.fm API")
        
        let searchURL = "\(lastFMBaseURL)/?method=artist.gettoptracks&artist=\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist)&api_key=\(lastFMAPIKey)&format=json&limit=10"
        
        guard let url = URL(string: searchURL) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                let httpResponse = response as? HTTPURLResponse
                print("📡 Last.fm API status: \(httpResponse?.statusCode ?? 0)")
                print("📦 Response size: \(data.count) bytes")
                return data
            }
            .tryMap { data -> LastFMResponse in
                do {
                    let response = try JSONDecoder().decode(LastFMResponse.self, from: data)
                    print("✅ Successfully decoded Last.fm response")
                    return response
                } catch {
                    print("❌ Failed to decode Last.fm response: \(error)")
                    throw APIError.decodingError(error)
                }
            }
            .map { lastFMResponse -> [Song] in
                return lastFMResponse.toptracks?.track?.compactMap { track in
                    let songID = "lastfm_\(track.name.replacingOccurrences(of: " ", with: "_"))"
                    let duration = Int.random(in: 180...420) // Random duration between 3-7 minutes
                    
                    return Song(
                        id: songID,
                        title: track.name,
                        artist: track.artist.name,
                        album: track.album?.name ?? "Unknown Album",
                        duration: TimeInterval(duration),
                        albumArtURL: track.album?.image?.first(where: { $0.size == "large" })?.text,
                        source: MusicSourceType.lastFM,
                        sourceID: track.name, localFilePath: nil
                    )
                } ?? []
            }
            .catch { error -> AnyPublisher<[Song], Error> in
                print("❌ Last.fm API error: \(error.localizedDescription)")
                // Fallback to enhanced mock data
                return Just(self.getLastFMMockSongs())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func searchSongsFromLastFM(query: String) -> AnyPublisher<[Song], Error> {
        print("🔍 Searching for '\(query)' in Last.fm API")
        
        let searchURL = "\(lastFMBaseURL)/?method=track.search&track=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&api_key=\(lastFMAPIKey)&format=json&limit=10"
        
        guard let url = URL(string: searchURL) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                let httpResponse = response as? HTTPURLResponse
                print("📡 Last.fm search status: \(httpResponse?.statusCode ?? 0)")
                return data
            }
            .tryMap { data -> LastFMSearchResponse in
                do {
                    let response = try JSONDecoder().decode(LastFMSearchResponse.self, from: data)
                    print("✅ Successfully decoded Last.fm search response")
                    return response
                } catch {
                    print("❌ Failed to decode Last.fm search: \(error)")
                    throw APIError.decodingError(error)
                }
            }
            .map { searchResponse -> [Song] in
                return searchResponse.results?.trackmatches?.track?.compactMap { track in
                    let songID = "lastfm_\(track.name.replacingOccurrences(of: " ", with: "_"))"
                    let duration = Int.random(in: 180...420)
                    
                    return Song(
                        id: songID,
                        title: track.name,
                        artist: track.artist,
                        album: track.album ?? "Unknown Album",
                        duration: TimeInterval(duration),
                        albumArtURL: track.image?.first(where: { $0.size == "large" })?.text,
                        source: MusicSourceType.lastFM,
                        sourceID: track.name, localFilePath: nil
                    )
                } ?? []
            }
            .catch { error -> AnyPublisher<[Song], Error> in
                print("❌ Last.fm search error: \(error.localizedDescription)")
                // Fallback to enhanced mock data search
                let allMockSongs = self.getLastFMMockSongs()
                let filteredSongs = allMockSongs.filter { song in
                    song.title.localizedCaseInsensitiveContains(query) ||
                    song.artist.localizedCaseInsensitiveContains(query) ||
                    song.album.localizedCaseInsensitiveContains(query)
                }
                return Just(filteredSongs)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func getLastFMMockSongs() -> [Song] {
        return [
            Song(id: "lastfm_1", title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/The_Weeknd_-_After_Hours.png", source: MusicSourceType.lastFM, sourceID: "lastfm_1", localFilePath: nil),
            Song(id: "lastfm_2", title: "Levitating", artist: "Dua Lipa", album: "Future Nostalgia", duration: 203, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/1c/Dua_Lipa_-_Future_Nostalgia.png", source: MusicSourceType.lastFM, sourceID: "lastfm_2", localFilePath: nil),
            Song(id: "lastfm_3", title: "Watermelon Sugar", artist: "Harry Styles", album: "Fine Line", duration: 174, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3f/Harry_Styles_-_Fine_Line.png", source: MusicSourceType.lastFM, sourceID: "lastfm_3", localFilePath: nil),
            Song(id: "lastfm_4", title: "Dance Monkey", artist: "Tones and I", album: "The Kids Are Coming", duration: 209, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/8/8a/Tones_and_I_-_The_Kids_Are_Coming.png", source: MusicSourceType.lastFM, sourceID: "lastfm_4", localFilePath: nil),
            Song(id: "lastfm_5", title: "Shape of You", artist: "Ed Sheeran", album: "÷", duration: 233, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/45/Ed_Sheeran_-_%C3%B7.png", source: MusicSourceType.lastFM, sourceID: "lastfm_5", localFilePath: nil)
        ]
    }
    
    func fetchSongsFromMusicBrainz(artist: String) -> AnyPublisher<[Song], Error> {
        print("🎯 Fetching songs for '\(artist)' from MusicBrainz API")
        
        // First, search for the artist
        let searchURL = "\(musicBrainzBaseURL)/artist/?query=artist:\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist)&fmt=json"
        
        guard let url = URL(string: searchURL) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                let httpResponse = response as? HTTPURLResponse
                print("📡 MusicBrainz artist search status: \(httpResponse?.statusCode ?? 0)")
                print("📦 Response size: \(data.count) bytes")
                return data
            }
            .tryMap { data -> MusicBrainzArtistResponse in
                do {
                    let response = try JSONDecoder().decode(MusicBrainzArtistResponse.self, from: data)
                    print("✅ Successfully decoded MusicBrainz artist response")
                    return response
                } catch {
                    print("❌ Failed to decode MusicBrainz response: \(error)")
                    throw APIError.decodingError(error)
                }
            }
            .flatMap { artistResponse -> AnyPublisher<[Song], Error> in
                // Get the first artist result
                guard let artist = artistResponse.artists.first else {
                    print("❌ No artist found for '\(artist)'")
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                // Now fetch releases for this artist
                return self.fetchReleasesForArtist(artistID: artist.id, artistName: artist.name)
            }
            .catch { error -> AnyPublisher<[Song], Error> in
                print("❌ MusicBrainz API error: \(error.localizedDescription)")
                // Fallback to enhanced mock data
                return Just(self.getEnhancedMockSongsForArtist(artist))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchReleasesForArtist(artistID: String, artistName: String) -> AnyPublisher<[Song], Error> {
        let releasesURL = "\(musicBrainzBaseURL)/release/?artist=\(artistID)&fmt=json&limit=20"
        
        guard let url = URL(string: releasesURL) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                let httpResponse = response as? HTTPURLResponse
                print("📡 MusicBrainz releases status: \(httpResponse?.statusCode ?? 0)")
                return data
            }
            .tryMap { data -> MusicBrainzReleaseResponse in
                do {
                    let response = try JSONDecoder().decode(MusicBrainzReleaseResponse.self, from: data)
                    print("✅ Successfully decoded MusicBrainz releases response")
                    return response
                } catch {
                    print("❌ Failed to decode MusicBrainz releases: \(error)")
                    throw APIError.decodingError(error)
                }
            }
            .map { releaseResponse -> [Song] in
                return releaseResponse.releases.compactMap { release in
                    // Create a song for each release
                    let songID = "mb_\(release.id)"
                    let duration = Int.random(in: 180...420) // Random duration between 3-7 minutes
                    
                    return Song(
                        id: songID,
                        title: release.title,
                        artist: artistName,
                        album: release.title,
                        duration: TimeInterval(duration),
                        albumArtURL: nil, // MusicBrainz doesn't provide album art URLs
                        source: MusicSourceType.local,
                        sourceID: release.id, localFilePath: nil
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func searchSongsFromMusicBrainz(query: String) -> AnyPublisher<[Song], Error> {
        print("🔍 Searching for '\(query)' in MusicBrainz API")
        
        // Search for releases
        let searchURL = "\(musicBrainzBaseURL)/release/?query=release:\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&fmt=json&limit=20"
        
        guard let url = URL(string: searchURL) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                let httpResponse = response as? HTTPURLResponse
                print("📡 MusicBrainz search status: \(httpResponse?.statusCode ?? 0)")
                return data
            }
            .tryMap { data -> MusicBrainzReleaseResponse in
                do {
                    let response = try JSONDecoder().decode(MusicBrainzReleaseResponse.self, from: data)
                    print("✅ Successfully decoded MusicBrainz search response")
                    return response
                } catch {
                    print("❌ Failed to decode MusicBrainz search: \(error)")
                    throw APIError.decodingError(error)
                }
            }
            .map { releaseResponse -> [Song] in
                return releaseResponse.releases.compactMap { release in
                    let songID = "mb_\(release.id)"
                    let duration = Int.random(in: 180...420)
                    
                    return Song(
                        id: songID,
                        title: release.title,
                        artist: release.artistCredit?.first?.name ?? "Unknown Artist",
                        album: release.title,
                        duration: TimeInterval(duration),
                        albumArtURL: nil,
                        source: MusicSourceType.local,
                        sourceID: release.id, localFilePath: nil
                    )
                }
            }
            .catch { error -> AnyPublisher<[Song], Error> in
                print("❌ MusicBrainz search error: \(error.localizedDescription)")
                // Fallback to enhanced mock data search
                let allMockSongs = self.getAllMockSongs()
                let filteredSongs = allMockSongs.filter { song in
                    song.title.localizedCaseInsensitiveContains(query) ||
                    song.artist.localizedCaseInsensitiveContains(query) ||
                    song.album.localizedCaseInsensitiveContains(query)
                }
                return Just(filteredSongs)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Legacy API Methods (Now using MusicBrainz)
    func fetchSongsFromAudioDB(artist: String) -> AnyPublisher<[Song], Error> {
        // Use MusicBrainz instead of TheAudioDB
        return fetchSongsFromMusicBrainz(artist: artist)
    }
    
    func searchSongsFromAudioDB(query: String) -> AnyPublisher<[Song], Error> {
        // Use MusicBrainz instead of TheAudioDB
        return searchSongsFromMusicBrainz(query: query)
    }
    
    func fetchSongsFromDiscogs(artist: String) -> AnyPublisher<[Song], Error> {
        // Use MusicBrainz instead of Discogs
        return fetchSongsFromMusicBrainz(artist: artist)
    }
    
    func searchSongsFromDiscogs(query: String) -> AnyPublisher<[Song], Error> {
        // Use MusicBrainz instead of Discogs
        return searchSongsFromMusicBrainz(query: query)
    }
    
    // MARK: - Enhanced Mock Data (Fallback)
    private func getEnhancedMockSongsForArtist(_ artist: String) -> [Song] {
        switch artist.lowercased() {
        case "queen":
            return [
                Song(id: "queen_1", title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 354, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/Queen_A_Night_At_The_Opera.png", source: MusicSourceType.local, sourceID: "queen_1", localFilePath: nil),
                Song(id: "queen_2", title: "We Will Rock You", artist: "Queen", album: "News of the World", duration: 122, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/e/ea/Queen_News_Of_The_World.png", source: MusicSourceType.local, sourceID: "queen_2", localFilePath: nil),
                Song(id: "queen_3", title: "Another One Bites the Dust", artist: "Queen", album: "The Game", duration: 213, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/16/Queen_The_Game.png", source: MusicSourceType.local, sourceID: "queen_3", localFilePath: nil),
                Song(id: "queen_4", title: "Somebody to Love", artist: "Queen", album: "A Day at the Races", duration: 297, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/8/8a/Queen_A_Day_At_The_Races.png", source: MusicSourceType.local, sourceID: "queen_4", localFilePath: nil),
                Song(id: "queen_5", title: "Don't Stop Me Now", artist: "Queen", album: "Jazz", duration: 209, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/1c/Queen_Jazz.png", source: MusicSourceType.local, sourceID: "queen_5", localFilePath: nil),
                Song(id: "queen_6", title: "Killer Queen", artist: "Queen", album: "Sheer Heart Attack", duration: 181, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/2d/Queen_Sheer_Heart_Attack.png", source: MusicSourceType.local, sourceID: "queen_6", localFilePath: nil),
                Song(id: "queen_7", title: "Radio Ga Ga", artist: "Queen", album: "The Works", duration: 343, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/1c/Queen_The_Works.png", source: MusicSourceType.local, sourceID: "queen_7", localFilePath: nil),
                Song(id: "queen_8", title: "I Want to Break Free", artist: "Queen", album: "The Works", duration: 258, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/1/1c/Queen_The_Works.png", source: MusicSourceType.local, sourceID: "queen_8", localFilePath: nil)
            ]
        case "pink floyd":
            return [
                Song(id: "pf_1", title: "Comfortably Numb", artist: "Pink Floyd", album: "The Wall", duration: 382, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/Pink_Floyd_-_The_Wall.png", source: MusicSourceType.local, sourceID: "pf_1", localFilePath: nil),
                Song(id: "pf_2", title: "Wish You Were Here", artist: "Pink Floyd", album: "Wish You Were Here", duration: 334, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/2c/Pink_Floyd_-_Wish_You_Were_Here.png", source: MusicSourceType.local, sourceID: "pf_2", localFilePath: nil),
                Song(id: "pf_3", title: "Time", artist: "Pink Floyd", album: "The Dark Side of the Moon", duration: 421, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3b/Dark_Side_of_the_Moon.png", source: MusicSourceType.local, sourceID: "pf_3", localFilePath: nil),
                Song(id: "pf_4", title: "Money", artist: "Pink Floyd", album: "The Dark Side of the Moon", duration: 382, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3b/Dark_Side_of_the_Moon.png", source: MusicSourceType.local, sourceID: "pf_4", localFilePath: nil),
                Song(id: "pf_5", title: "Another Brick in the Wall", artist: "Pink Floyd", album: "The Wall", duration: 356, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/Pink_Floyd_-_The_Wall.png", source: MusicSourceType.local, sourceID: "pf_5", localFilePath: nil),
                Song(id: "pf_6", title: "Shine On You Crazy Diamond", artist: "Pink Floyd", album: "Wish You Were Here", duration: 1043, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/2c/Pink_Floyd_-_Wish_You_Were_Here.png", source: MusicSourceType.local, sourceID: "pf_6", localFilePath: nil),
                Song(id: "pf_7", title: "Echoes", artist: "Pink Floyd", album: "Meddle", duration: 1383, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3c/Pink_Floyd_-_Meddle.png", source: MusicSourceType.local, sourceID: "pf_7", localFilePath: nil),
                Song(id: "pf_8", title: "Learning to Fly", artist: "Pink Floyd", album: "A Momentary Lapse of Reason", duration: 284, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/8/87/Pink_Floyd_-_A_Momentary_Lapse_of_Reason.png", source: MusicSourceType.local, sourceID: "pf_8", localFilePath: nil)
            ]
        case "the beatles":
            return [
                Song(id: "beatles_1", title: "Hey Jude", artist: "The Beatles", album: "The Beatles 1967-1970", duration: 431, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/TheBeatles1967-1970.jpg", source: MusicSourceType.local, sourceID: "beatles_1", localFilePath: nil),
                Song(id: "beatles_2", title: "Let It Be", artist: "The Beatles", album: "Let It Be", duration: 243, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/LetItBe.jpg", source: MusicSourceType.local, sourceID: "beatles_2", localFilePath: nil),
                Song(id: "beatles_3", title: "Yesterday", artist: "The Beatles", album: "Help!", duration: 125, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/Help%21.jpg", source: MusicSourceType.local, sourceID: "beatles_3", localFilePath: nil),
                Song(id: "beatles_4", title: "A Day in the Life", artist: "The Beatles", album: "Sgt. Pepper's Lonely Hearts Club Band", duration: 334, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/SgtPepper.jpg", source: MusicSourceType.local, sourceID: "beatles_4", localFilePath: nil),
                Song(id: "beatles_5", title: "Come Together", artist: "The Beatles", album: "Abbey Road", duration: 259, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/AbbeyRoad.jpg", source: MusicSourceType.local, sourceID: "beatles_5", localFilePath: nil),
                Song(id: "beatles_6", title: "Eleanor Rigby", artist: "The Beatles", album: "Revolver", duration: 128, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3c/Revolver.jpg", source: MusicSourceType.local, sourceID: "beatles_6", localFilePath: nil),
                Song(id: "beatles_7", title: "Strawberry Fields Forever", artist: "The Beatles", album: "Magical Mystery Tour", duration: 251, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/e/e8/MagicalMysteryTour.jpg", source: MusicSourceType.local, sourceID: "beatles_7", localFilePath: nil),
                Song(id: "beatles_8", title: "While My Guitar Gently Weeps", artist: "The Beatles", album: "The Beatles", duration: 285, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/0/02/TheBeatles68.jpg", source: MusicSourceType.local, sourceID: "beatles_8", localFilePath: nil)
            ]
        case "led zeppelin":
            return [
                Song(id: "zeppelin_1", title: "Stairway to Heaven", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 482, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg", source: MusicSourceType.local, sourceID: "zeppelin_1", localFilePath: nil),
                Song(id: "zeppelin_2", title: "Whole Lotta Love", artist: "Led Zeppelin", album: "Led Zeppelin II", duration: 333, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/6/69/Led_Zeppelin_-_Led_Zeppelin_II.jpg", source: MusicSourceType.local, sourceID: "zeppelin_2", localFilePath: nil),
                Song(id: "zeppelin_3", title: "Kashmir", artist: "Led Zeppelin", album: "Physical Graffiti", duration: 448, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/7/76/Led_Zeppelin_-_Physical_Graffiti.jpg", source: MusicSourceType.local, sourceID: "zeppelin_3", localFilePath: nil),
                Song(id: "zeppelin_4", title: "Black Dog", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 296, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg", source: MusicSourceType.local, sourceID: "zeppelin_4", localFilePath: nil),
                Song(id: "zeppelin_5", title: "Rock and Roll", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 220, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg", source: MusicSourceType.local, sourceID: "zeppelin_5", localFilePath: nil),
                Song(id: "zeppelin_6", title: "Dazed and Confused", artist: "Led Zeppelin", album: "Led Zeppelin", duration: 388, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/5f/Led_Zeppelin_-_Led_Zeppelin.jpg", source: MusicSourceType.local, sourceID: "zeppelin_6", localFilePath: nil),
                Song(id: "zeppelin_7", title: "Immigrant Song", artist: "Led Zeppelin", album: "Led Zeppelin III", duration: 146, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/33/Led_Zeppelin_-_Led_Zeppelin_III.jpg", source: MusicSourceType.local, sourceID: "zeppelin_7", localFilePath: nil),
                Song(id: "zeppelin_8", title: "Since I've Been Loving You", artist: "Led Zeppelin", album: "Led Zeppelin III", duration: 446, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/33/Led_Zeppelin_-_Led_Zeppelin_III.jpg", source: MusicSourceType.local, sourceID: "zeppelin_8", localFilePath: nil)
            ]
        default:
            return [
                Song(id: "default_1", title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 354, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/4d/Queen_A_Night_At_The_Opera.png", source: MusicSourceType.local, sourceID: "default_1", localFilePath: nil),
                Song(id: "default_2", title: "Comfortably Numb", artist: "Pink Floyd", album: "The Wall", duration: 382, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/Pink_Floyd_-_The_Wall.png", source: MusicSourceType.local, sourceID: "default_2", localFilePath: nil),
                Song(id: "default_3", title: "Hey Jude", artist: "The Beatles", album: "The Beatles 1967-1970", duration: 431, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/5/51/TheBeatles1967-1970.jpg", source: MusicSourceType.local, sourceID: "default_3", localFilePath: nil),
                Song(id: "default_4", title: "Stairway to Heaven", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 482, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg", source: MusicSourceType.local, sourceID: "default_4", localFilePath: nil),
                Song(id: "default_5", title: "Imagine", artist: "John Lennon", album: "Imagine", duration: 183, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/6/69/ImagineCover.jpg", source: MusicSourceType.local, sourceID: "default_5", localFilePath: nil),
                Song(id: "default_6", title: "Hotel California", artist: "Eagles", album: "Hotel California", duration: 391, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/4/49/HotelCalifornia.jpg", source: MusicSourceType.local, sourceID: "default_6", localFilePath: nil),
                Song(id: "default_7", title: "Wish You Were Here", artist: "Pink Floyd", album: "Wish You Were Here", duration: 334, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/2/2c/Pink_Floyd_-_Wish_You_Were_Here.png", source: MusicSourceType.local, sourceID: "default_7", localFilePath: nil),
                Song(id: "default_8", title: "Time", artist: "Pink Floyd", album: "The Dark Side of the Moon", duration: 421, albumArtURL: "https://upload.wikimedia.org/wikipedia/en/3/3b/Dark_Side_of_the_Moon.png", source: MusicSourceType.local, sourceID: "default_8", localFilePath: nil)
            ]
        }
    }
    
    private func getAllMockSongs() -> [Song] {
        var allSongs: [Song] = []
        
        // Add songs from all artists
        allSongs.append(contentsOf: getEnhancedMockSongsForArtist("queen"))
        allSongs.append(contentsOf: getEnhancedMockSongsForArtist("pink floyd"))
        allSongs.append(contentsOf: getEnhancedMockSongsForArtist("the beatles"))
        allSongs.append(contentsOf: getEnhancedMockSongsForArtist("led zeppelin"))
        
        return allSongs
    }
}

// MARK: - API Models
struct MusicBrainzArtistResponse: Codable {
    let artists: [MusicBrainzArtist]
}

struct MusicBrainzArtist: Codable {
    let id: String
    let name: String
    let type: String?
}

struct MusicBrainzReleaseResponse: Codable {
    let releases: [MusicBrainzRelease]
}

struct MusicBrainzRelease: Codable {
    let id: String
    let title: String
    let artistCredit: [MusicBrainzArtistCredit]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
    }
}

struct MusicBrainzArtistCredit: Codable {
    let name: String
}

// Legacy models (kept for compatibility)
struct AudioDBResponse: Codable {
    let tracks: [AudioDBTrack]?
}

struct AudioDBTrack: Codable {
    let idTrack: String?
    let strTrack: String?
    let strArtist: String?
    let strAlbum: String?
    let intDuration: Int?
    let strTrackThumb: String?
}

struct DiscogsResponse: Codable {
    let results: [DiscogsRelease]
}

struct DiscogsRelease: Codable {
    let id: Int
    let title: String
    let artist: String
    let year: Int?
    let thumb: String?
}

// MARK: - Last.fm API Models
struct LastFMResponse: Codable {
    let toptracks: LastFMTopTracks?
}

struct LastFMTopTracks: Codable {
    let track: [LastFMTrack]?
}

struct LastFMTrack: Codable {
    let name: String
    let artist: LastFMArtist
    let album: LastFMAlbum?
    let playcount: String?
    let listeners: String?
}

struct LastFMArtist: Codable {
    let name: String
    let mbid: String?
    let url: String?
}

struct LastFMAlbum: Codable {
    let name: String
    let image: [LastFMImage]?
}

struct LastFMImage: Codable {
    let size: String
    let text: String
}

struct LastFMSearchResponse: Codable {
    let results: LastFMSearchResults?
}

struct LastFMSearchResults: Codable {
    let trackmatches: LastFMTrackMatches?
}

struct LastFMTrackMatches: Codable {
    let track: [LastFMSearchTrack]?
}

struct LastFMSearchTrack: Codable {
    let name: String
    let artist: String
    let album: String?
    let image: [LastFMImage]?
    let listeners: String?
    let mbid: String?
    let url: String?
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
