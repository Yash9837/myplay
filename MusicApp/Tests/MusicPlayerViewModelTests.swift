//import XCTest
//import Combine
//@testable import MusicApp
//
//class MusicPlayerViewModelTests: XCTestCase {
//    var viewModel: MusicPlayerViewModel!
//    var cancellables: Set<AnyCancellable>!
//    
//    override func setUp() {
//        super.setUp()
//        viewModel = MusicPlayerViewModel()
//        cancellables = Set<AnyCancellable>()
//    }
//    
//    override func tearDown() {
//        viewModel = nil
//        cancellables = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Initialization Tests
//    func testInitialState() {
//        XCTAssertEqual(viewModel.selectedSource, .local)
//        XCTAssertTrue(viewModel.songs.isEmpty)
//        XCTAssertTrue(viewModel.filteredSongs.isEmpty)
//        XCTAssertEqual(viewModel.searchText, "")
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertNil(viewModel.errorMessage)
//    }
//    
//    // MARK: - Music Source Tests
//    func testChangeMusicSource() {
//        let expectation = XCTestExpectation(description: "Source changed to Spotify")
//        
//        viewModel.$selectedSource
//            .dropFirst()
//            .sink { source in
//                XCTAssertEqual(source, .spotify)
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//        
//        viewModel.changeMusicSource(to: .spotify)
//        
//        wait(for: [expectation], timeout: 2.0)
//    }
//    
//    // MARK: - Search Tests
//    func testSearchFunctionality() {
//        // First load some songs
//        viewModel.changeMusicSource(to: .local)
//        
//        let expectation = XCTestExpectation(description: "Songs loaded")
//        
//        viewModel.$songs
//            .dropFirst()
//            .sink { songs in
//                XCTAssertFalse(songs.isEmpty)
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 2.0)
//        
//        // Test search
//        let searchExpectation = XCTestExpectation(description: "Search completed")
//        
//        viewModel.$filteredSongs
//            .dropFirst()
//            .sink { filteredSongs in
//                XCTAssertTrue(filteredSongs.count <= viewModel.songs.count)
//                searchExpectation.fulfill()
//            }
//            .store(in: &cancellables)
//        
//        viewModel.searchText = "Queen"
//        
//        wait(for: [searchExpectation], timeout: 2.0)
//    }
//    
//    // MARK: - Playback Control Tests
//    func testPlaySong() {
//        let mockSong = Song(
//            id: "test_1",
//            title: "Test Song",
//            artist: "Test Artist",
//            album: "Test Album",
//            duration: 180,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "test_1"
//        )
//        
//        viewModel.playSong(mockSong)
//        
//        XCTAssertEqual(viewModel.currentSong?.id, mockSong.id)
//        XCTAssertTrue(viewModel.queue.contains(mockSong))
//    }
//    
//    func testPlayPause() {
//        let mockSong = Song(
//            id: "test_2",
//            title: "Test Song 2",
//            artist: "Test Artist 2",
//            album: "Test Album 2",
//            duration: 200,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "test_2"
//        )
//        
//        // Test play
//        viewModel.playSong(mockSong)
//        XCTAssertEqual(viewModel.currentSong?.id, mockSong.id)
//        
//        // Test pause
//        viewModel.playPause()
//        XCTAssertEqual(viewModel.playbackState, .paused)
//        
//        // Test resume
//        viewModel.playPause()
//        XCTAssertEqual(viewModel.playbackState, .playing)
//    }
//    
//    // MARK: - Queue Management Tests
//    func testQueueManagement() {
//        let song1 = Song(
//            id: "queue_1",
//            title: "Queue Song 1",
//            artist: "Artist 1",
//            album: "Album 1",
//            duration: 180,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "queue_1"
//        )
//        
//        let song2 = Song(
//            id: "queue_2",
//            title: "Queue Song 2",
//            artist: "Artist 2",
//            album: "Album 2",
//            duration: 200,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "queue_2"
//        )
//        
//        // Test adding to queue
//        viewModel.addToQueue(song1)
//        viewModel.addToQueue(song2)
//        
//        XCTAssertEqual(viewModel.queue.count, 2)
//        XCTAssertTrue(viewModel.queue.contains(song1))
//        XCTAssertTrue(viewModel.queue.contains(song2))
//        
//        // Test removing from queue
//        viewModel.removeFromQueue(at: 0)
//        XCTAssertEqual(viewModel.queue.count, 1)
//        XCTAssertFalse(viewModel.queue.contains(song1))
//        XCTAssertTrue(viewModel.queue.contains(song2))
//        
//        // Test clearing queue
//        viewModel.clearQueue()
//        XCTAssertTrue(viewModel.queue.isEmpty)
//    }
//    
//    // MARK: - Utility Method Tests
//    func testIsCurrentSong() {
//        let mockSong = Song(
//            id: "current_test",
//            title: "Current Test Song",
//            artist: "Test Artist",
//            album: "Test Album",
//            duration: 180,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "current_test"
//        )
//        
//        XCTAssertFalse(viewModel.isCurrentSong(mockSong))
//        
//        viewModel.playSong(mockSong)
//        
//        XCTAssertTrue(viewModel.isCurrentSong(mockSong))
//    }
//    
//    func testIsSongInQueue() {
//        let mockSong = Song(
//            id: "queue_test",
//            title: "Queue Test Song",
//            artist: "Test Artist",
//            album: "Test Album",
//            duration: 180,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "queue_test"
//        )
//        
//        XCTAssertFalse(viewModel.isSongInQueue(mockSong))
//        
//        viewModel.addToQueue(mockSong)
//        
//        XCTAssertTrue(viewModel.isSongInQueue(mockSong))
//    }
//    
//    func testGetQueueIndex() {
//        let mockSong = Song(
//            id: "index_test",
//            title: "Index Test Song",
//            artist: "Test Artist",
//            album: "Test Album",
//            duration: 180,
//            albumArtURL: nil,
//            source: .local,
//            sourceID: "index_test"
//        )
//        
//        XCTAssertNil(viewModel.getQueueIndex(for: mockSong))
//        
//        viewModel.addToQueue(mockSong)
//        
//        XCTAssertEqual(viewModel.getQueueIndex(for: mockSong), 0)
//    }
//} 
