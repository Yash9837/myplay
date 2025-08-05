import Foundation
import Combine

class QueueManager: ObservableObject {
    static let shared = QueueManager()
    
    // MARK: - Published Properties
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = -1
    @Published var shuffleMode: Bool = false
    @Published var repeatMode: RepeatMode = .none
    
    // MARK: - Private Properties
    private var originalQueue: [Song] = []
    private var cancellables = Set<AnyCancellable>()
    
    enum RepeatMode: String, CaseIterable {
        case none = "none"
        case one = "one"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .none:
                return "No Repeat"
            case .one:
                return "Repeat One"
            case .all:
                return "Repeat All"
            }
        }
        
        var iconName: String {
            switch self {
            case .none:
                return "repeat"
            case .one:
                return "repeat.1"
            case .all:
                return "repeat"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Queue Management
    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        originalQueue = songs
        queue = shuffleMode ? songs.shuffled() : songs
        currentIndex = min(startIndex, songs.count - 1)
    }
    
    func addToQueue(_ song: Song) {
        queue.append(song)
        if originalQueue.isEmpty {
            originalQueue = queue
        }
    }
    
    func addToQueue(_ songs: [Song]) {
        queue.append(contentsOf: songs)
        if originalQueue.isEmpty {
            originalQueue = queue
        }
    }
    
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        
        let songToRemove = queue[index]
        queue.remove(at: index)
        
        // Update original queue if needed
        if let originalIndex = originalQueue.firstIndex(of: songToRemove) {
            originalQueue.remove(at: originalIndex)
        }
        
        // Adjust current index
        if index <= currentIndex && currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    func moveSong(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < queue.count,
              destinationIndex >= 0 && destinationIndex < queue.count else { return }
        
        let song = queue.remove(at: sourceIndex)
        queue.insert(song, at: destinationIndex)
        
        // Update original queue
        if let originalIndex = originalQueue.firstIndex(of: song) {
            originalQueue.remove(at: originalIndex)
            originalQueue.insert(song, at: destinationIndex)
        }
        
        // Adjust current index
        if sourceIndex == currentIndex {
            currentIndex = destinationIndex
        } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
            currentIndex -= 1
        } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
            currentIndex += 1
        }
    }
    
    func clearQueue() {
        queue.removeAll()
        originalQueue.removeAll()
        currentIndex = -1
    }
    
    // MARK: - Navigation
    func nextSong() -> Song? {
        guard !queue.isEmpty else { return nil }
        
        if repeatMode == .one {
            return currentSong
        }
        
        if currentIndex < queue.count - 1 {
            currentIndex += 1
            return currentSong
        } else if repeatMode == .all {
            currentIndex = 0
            return currentSong
        }
        
        return nil
    }
    
    func previousSong() -> Song? {
        guard !queue.isEmpty else { return nil }
        
        if repeatMode == .one {
            return currentSong
        }
        
        if currentIndex > 0 {
            currentIndex -= 1
            return currentSong
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
            return currentSong
        }
        
        return nil
    }
    
    func jumpToSong(at index: Int) -> Song? {
        guard index >= 0 && index < queue.count else { return nil }
        currentIndex = index
        return currentSong
    }
    
    // MARK: - Shuffle Management
    func toggleShuffle() {
        shuffleMode.toggle()
        if shuffleMode {
            // Create shuffled queue while preserving current song
            let currentSong = self.currentSong
            var shuffledQueue = originalQueue.shuffled()
            
            if let currentSong = currentSong,
               let currentIndex = shuffledQueue.firstIndex(of: currentSong) {
                // Move current song to the front
                shuffledQueue.remove(at: currentIndex)
                shuffledQueue.insert(currentSong, at: 0)
                self.currentIndex = 0
            }
            
            queue = shuffledQueue
        } else {
            // Restore original order
            queue = originalQueue
            if let currentSong = currentSong,
               let newIndex = originalQueue.firstIndex(of: currentSong) {
                currentIndex = newIndex
            }
        }
    }
    
    // MARK: - Repeat Management
    func toggleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
    }
    
    // MARK: - Computed Properties
    var currentSong: Song? {
        guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }
    
    var hasNextSong: Bool {
        if repeatMode == .one { return true }
        if repeatMode == .all { return !queue.isEmpty }
        return currentIndex < queue.count - 1
    }
    
    var hasPreviousSong: Bool {
        if repeatMode == .one { return true }
        if repeatMode == .all { return !queue.isEmpty }
        return currentIndex > 0
    }
    
    var queueCount: Int {
        return queue.count
    }
    
    var isQueueEmpty: Bool {
        return queue.isEmpty
    }
    
    // MARK: - Queue Information
    func getQueueInfo() -> (current: Int, total: Int, currentSong: Song?) {
        return (currentIndex + 1, queue.count, currentSong)
    }
    
    func getUpcomingSongs(limit: Int = 5) -> [Song] {
        let startIndex = currentIndex + 1
        let endIndex = min(startIndex + limit, queue.count)
        return Array(queue[startIndex..<endIndex])
    }
    
    func getPreviousSongs(limit: Int = 5) -> [Song] {
        let endIndex = currentIndex
        let startIndex = max(0, endIndex - limit)
        return Array(queue[startIndex..<endIndex])
    }
}

// MARK: - Queue Manager Extensions
extension QueueManager {
    func playNext() {
        if let nextSong = nextSong() {
            AudioPlayerService.shared.play(song: nextSong)
        }
    }
    
    func playPrevious() {
        if let previousSong = previousSong() {
            AudioPlayerService.shared.play(song: previousSong)
        }
    }
    
    func playSong(at index: Int) {
        if let song = jumpToSong(at: index) {
            AudioPlayerService.shared.play(song: song)
        }
    }
} 