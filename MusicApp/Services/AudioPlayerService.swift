//AVFoundation.AVAudioSession.interruptionNotification
import Foundation
import AVFoundation
import Combine
import UIKit

class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()
    
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var playbackState: PlaybackState = .stopped
    @Published var progress: PlaybackProgress = PlaybackProgress(currentTime: 0, duration: 0)
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Audio Session
    private var audioSession: AVAudioSession {
        return AVAudioSession.sharedInstance()
    }
    
    private override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
            print("🎵 Audio session setup successful")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio session"
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: AVFoundation.AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playback Control
    func play(song: Song) {
        guard song != currentSong else {
            resume()
            return
        }
        
        currentSong = song
        playbackState = .loading
        
        // Load and play the audio file
        loadAndPlayAudio(for: song)
    }
    
    private func loadAndPlayAudio(for song: Song) {
        // Get the audio URL for this song
        guard let audioURL = getAudioURL(for: song) else {
            // No audio available for this song
            if song.source == .audioDB || song.source == .lastFM {
                handleError(NSError(domain: "AudioPlayerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Streaming not supported for \(song.source.displayName). This is a demo app."]))
            } else {
                handleError(NSError(domain: "AudioPlayerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio file not found for \(song.title)"]))
            }
            return
        }
        
        do {
            // Stop current player if any
            audioPlayer?.stop()
            audioPlayer = nil
            
            // Create new audio player
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 0.8 // Set volume to 80%
            audioPlayer?.prepareToPlay()
            
            // Start playback
            if audioPlayer?.play() == true {
                print("🎵 Audio playback started successfully for: \(song.title)")
                playbackState = .playing
                startProgressTimer()
            } else {
                print("❌ Failed to start audio playback for: \(song.title)")
                handleError(NSError(domain: "AudioPlayerService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"]))
            }
        } catch {
            handleError(error)
        }
    }
    
    private func getAudioURL(for song: Song) -> URL? {
        // Check if this is a local song with a file path
        if song.source == .local, let filePath = song.localFilePath {
            // Try to get the file from the app bundle
            if let bundleURL = Bundle.main.url(forResource: filePath.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") {
                print("🎵 Found local audio file: \(bundleURL)")
                return bundleURL
            }
            
            // Also try other audio formats
            let audioExtensions = ["m4a", "wav", "aac"]
            for ext in audioExtensions {
                if let bundleURL = Bundle.main.url(forResource: filePath.replacingOccurrences(of: ".mp3", with: ""), withExtension: ext) {
                    print("🎵 Found local audio file: \(bundleURL)")
                    return bundleURL
                }
            }
            
            print("⚠️ Local audio file not found: \(filePath)")
            return nil
        }
        
        // For remote sources (AudioDB, Last.fm), show a message that streaming is not supported
        if song.source == .audioDB || song.source == .lastFM {
            print("ℹ️ Streaming not supported for \(song.source.displayName). This is a demo app.")
            // Return nil to indicate no audio available
            return nil
        }
        
        // Fallback: try to find any sample audio file in the app bundle
        let audioExtensions = ["mp3", "m4a", "wav", "aac"]
        for ext in audioExtensions {
            if let sampleURL = Bundle.main.url(forResource: "sample_audio", withExtension: ext) {
                print("🎵 Using sample audio file: \(sampleURL)")
                return sampleURL
            }
        }
        
        // If no sample file exists, create a demo audio file
        print("🎵 Creating demo audio file for: \(song.title)")
        return createDemoAudioFile()
    }
    
    private func createDemoAudioFile() -> URL? {
        // Create a temporary audio file with a simple tone for demo purposes
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("demo_audio.wav")
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: tempURL.path) {
            return tempURL
        }
        
        // Create a simple tone WAV file
        let sampleRate: Int32 = 44100
        let duration: Int32 = 30 // 30 seconds
        let numSamples = sampleRate * duration
        let frequency: Double = 440.0 // A4 note
        
        // Create WAV file header
        var header = Data()
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(36 + numSamples * 2).littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        header.append("fmt ".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) })
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(numSamples * 2).littleEndian) { Data($0) })
        
        // Create tone audio data with some variation
        var audioData = Data()
        for i in 0..<numSamples {
            let time = Double(i) / Double(sampleRate)
            
            // Create a more interesting tone with harmonics
            let baseFreq = frequency
            let harmonic1 = sin(2.0 * Double.pi * baseFreq * time) * 0.2
            let harmonic2 = sin(2.0 * Double.pi * baseFreq * 2.0 * time) * 0.1
            let harmonic3 = sin(2.0 * Double.pi * baseFreq * 3.0 * time) * 0.05
            
            let amplitude = (harmonic1 + harmonic2 + harmonic3) * 0.5 // 50% volume
            let sample = Int16(amplitude * 32767.0) // Convert to 16-bit
            audioData.append(withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }
        
        // Write file
        do {
            try header.write(to: tempURL)
            let fileHandle = try FileHandle(forWritingTo: tempURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(audioData)
            fileHandle.closeFile()
            print("🎵 Demo audio file created successfully at: \(tempURL)")
            return tempURL
        } catch {
            print("❌ Failed to create demo audio file: \(error)")
            return nil
        }
    }
    
    func pause() {
        guard playbackState == .playing else { return }
        audioPlayer?.pause()
        playbackState = .paused
        stopProgressTimer()
    }
    
    func resume() {
        guard playbackState == .paused else { return }
        audioPlayer?.play()
        playbackState = .playing
        startProgressTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        playbackState = .stopped
        currentSong = nil
        progress = PlaybackProgress(currentTime: 0, duration: 0)
        stopProgressTimer()
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let duration = player.duration
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        progress = PlaybackProgress(currentTime: clampedTime, duration: duration)
    }
    
    // MARK: - Progress Timer
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer, playbackState == .playing else { return }
        
        let currentTime = player.currentTime
        let duration = player.duration
        
        // Use the real duration from the audio file, not the song's duration
        progress = PlaybackProgress(currentTime: currentTime, duration: duration)
        
        // Check if song finished
        if currentTime >= duration {
            stop()
        }
    }
    
    // MARK: - Interruption Handling
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, pause playback
            if playbackState == .playing {
                pause()
            }
        case .ended:
            // Interruption ended, check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        @unknown default:
            break
        }
    }
    
    private func handleAppWillResignActive() {
        // App is going to background, ensure audio continues
        do {
            try audioSession.setActive(true)
        } catch {
            print("Failed to keep audio session active: \(error)")
        }
    }
    
    private func handleAppDidBecomeActive() {
        // App became active again
        do {
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .error
            self?.errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
        if playbackState == .error {
            playbackState = .stopped
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.handleError(error ?? NSError(domain: "AudioPlayerService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Audio decode error"]))
        }
    }
}

// MARK: - Audio Player Extensions
extension AudioPlayerService {
    func getCurrentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    func getDuration() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func canPlay() -> Bool {
        return currentSong != nil && playbackState != .loading
    }
}
