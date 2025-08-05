import Foundation
import Combine
import SwiftUI

class MusicPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var songs: [Song] = []
    @Published var filteredSongs: [Song] = []
    @Published var selectedSource: MusicSourceType = .local
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let audioPlayerService = AudioPlayerService.shared
    private let queueManager = QueueManager.shared
    private var musicSource: MusicSource
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    // MARK: - Computed Properties
    var currentSong: Song? {
        return audioPlayerService.currentSong
    }
    
    var playbackState: PlaybackState {
        return audioPlayerService.playbackState
    }
    
    var progress: PlaybackProgress {
        return audioPlayerService.progress
    }
    
    @Published var queue: [Song] = []
    
    var currentQueueIndex: Int {
        return queueManager.currentIndex
    }
    
    var shuffleMode: Bool {
        return queueManager.shuffleMode
    }
    
    var repeatMode: QueueManager.RepeatMode {
        return queueManager.repeatMode
    }
    
    var hasNextSong: Bool {
        return queueManager.hasNextSong
    }
    
    var hasPreviousSong: Bool {
        return queueManager.hasPreviousSong
    }
    
    var queueCount: Int {
        return queue.count
    }
    
    // MARK: - Initialization
    init() {
        self.musicSource = MusicSourceFactory.createSource(for: .local)
        setupBindings()
        loadSongs()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind audio player service
        audioPlayerService.$currentSong
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        audioPlayerService.$playbackState
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        audioPlayerService.$progress
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        audioPlayerService.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        // Bind queue manager
        queueManager.$queue
            .sink { [weak self] queue in
                self?.queue = queue
            }
            .store(in: &cancellables)
        
        queueManager.$currentIndex
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        queueManager.$shuffleMode
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        queueManager.$repeatMode
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Bind search text
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterSongs(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Music Source Management
    func changeMusicSource(to sourceType: MusicSourceType) {
        selectedSource = sourceType
        musicSource = MusicSourceFactory.createSource(for: sourceType)
        loadSongs()
    }
    
    private func loadSongs() {
        isLoading = true
        errorMessage = nil
        
        musicSource.fetchSongs()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] songs in
                    self?.songs = songs
                    self?.filteredSongs = songs
                }
            )
            .store(in: &cancellables)
    }
    
    private func filterSongs(searchText: String) {
        if searchText.isEmpty {
            filteredSongs = songs
        } else {
            filteredSongs = songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText) ||
                song.album.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Playback Control
    func playSong(_ song: Song) {
        audioPlayerService.play(song: song)
        
        // Add to queue if not already there
        if !queue.contains(song) {
            queueManager.addToQueue(song)
        }
        
        // Set as current song in queue
        if let index = queue.firstIndex(of: song) {
            queueManager.jumpToSong(at: index)
        }
    }
    
    func playSong(at index: Int) {
        queueManager.playSong(at: index)
    }
    
    func playPause() {
        switch playbackState {
        case .playing:
            audioPlayerService.pause()
        case .paused, .stopped:
            if let currentSong = currentSong {
                audioPlayerService.resume()
            } else if let firstSong = queue.first {
                playSong(firstSong)
            }
        case .loading, .error:
            break
        }
    }
    
    func nextSong() {
        if let nextSong = queueManager.nextSong() {
            audioPlayerService.play(song: nextSong)
        }
    }
    
    func previousSong() {
        if let previousSong = queueManager.previousSong() {
            audioPlayerService.play(song: previousSong)
        }
    }
    
    func stop() {
        audioPlayerService.stop()
    }
    
    func seek(to progress: Double) {
        guard let song = currentSong else { return }
        let time = song.duration * progress
        audioPlayerService.seek(to: time)
    }
    
    // MARK: - Queue Management
    func addToQueue(_ song: Song) {
        queueManager.addToQueue(song)
    }
    
    func addToQueue(_ songs: [Song]) {
        queueManager.addToQueue(songs)
    }
    
    func removeFromQueue(at index: Int) {
        queueManager.removeFromQueue(at: index)
    }
    
    func moveSongInQueue(from sourceIndex: Int, to destinationIndex: Int) {
        queueManager.moveSong(from: sourceIndex, to: destinationIndex)
    }
    
    func clearQueue() {
        queueManager.clearQueue()
    }
    
    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        queueManager.setQueue(songs, startIndex: startIndex)
    }
    
    // MARK: - Playback Mode Control
    func toggleShuffle() {
        queueManager.toggleShuffle()
    }
    
    func toggleRepeatMode() {
        queueManager.toggleRepeatMode()
    }
    
    // MARK: - Error Handling
    func clearError() {
        audioPlayerService.clearError()
        errorMessage = nil
    }
    
    // MARK: - Queue Information
    func getQueueInfo() -> (current: Int, total: Int, currentSong: Song?) {
        return queueManager.getQueueInfo()
    }
    
    func getUpcomingSongs(limit: Int = 5) -> [Song] {
        return queueManager.getUpcomingSongs(limit: limit)
    }
    
    func getPreviousSongs(limit: Int = 5) -> [Song] {
        return queueManager.getPreviousSongs(limit: limit)
    }
    
    // MARK: - Search
    func searchSongs(query: String) {
        searchText = query
    }
    
    // MARK: - Utility Methods
    func isCurrentSong(_ song: Song) -> Bool {
        return currentSong?.id == song.id
    }
    
    func isSongInQueue(_ song: Song) -> Bool {
        return queue.contains(song)
    }
    
    func getQueueIndex(for song: Song) -> Int? {
        return queue.firstIndex(of: song)
    }
}

// MARK: - Music Player ViewModel Extensions
extension MusicPlayerViewModel {
    func playQueue() {
        guard !queue.isEmpty else { return }
        if let currentSong = currentSong {
            audioPlayerService.play(song: currentSong)
        } else {
            playSong(queue[0])
        }
    }
    
    func playAllSongs() {
        setQueue(songs)
        playQueue()
    }
    
    func playFilteredSongs() {
        setQueue(filteredSongs)
        playQueue()
    }
} 
