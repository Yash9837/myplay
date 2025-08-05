import Foundation

enum PlaybackState: String, CaseIterable {
    case stopped = "stopped"
    case playing = "playing"
    case paused = "paused"
    case loading = "loading"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .loading:
            return "Loading..."
        case .error:
            return "Error"
        }
    }
    
    var iconName: String {
        switch self {
        case .stopped:
            return "play.circle"
        case .playing:
            return "pause.circle"
        case .paused:
            return "play.circle"
        case .loading:
            return "clock"
        case .error:
            return "exclamationmark.circle"
        }
    }
}

struct PlaybackProgress {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let progress: Double
    
    init(currentTime: TimeInterval, duration: TimeInterval) {
        self.currentTime = currentTime
        self.duration = duration
        self.progress = duration > 0 ? currentTime / duration : 0
    }
    
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 