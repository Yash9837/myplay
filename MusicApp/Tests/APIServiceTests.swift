//import XCTest
//import Combine
//@testable import MusicApp
//
//class APIServiceTests: XCTestCase {
//    var apiService: APIService!
//    var cancellables: Set<AnyCancellable>!
//    
//    override func setUp() {
//        super.setUp()
//        apiService = APIService.shared
//        cancellables = Set<AnyCancellable>()
//    }
//    
//    override func tearDown() {
//        cancellables = nil
//        super.tearDown()
//    }
//    
//    // MARK: - TheAudioDB API Tests
//    func testFetchSongsFromAudioDB() {
//        let expectation = XCTestExpectation(description: "Fetch songs from TheAudioDB")
//        
//        apiService.fetchSongsFromAudioDB(artist: "Queen")
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        expectation.fulfill()
//                    case .failure(let error):
//                        XCTFail("API call failed: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { songs in
//                    XCTAssertFalse(songs.isEmpty, "Should return songs from API")
//                    print("Received \(songs.count) songs from TheAudioDB")
//                }
//            )
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    func testSearchSongsFromAudioDB() {
//        let expectation = XCTestExpectation(description: "Search songs from TheAudioDB")
//        
//        apiService.searchSongsFromAudioDB(query: "Bohemian")
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        expectation.fulfill()
//                    case .failure(let error):
//                        XCTFail("API call failed: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { songs in
//                    XCTAssertFalse(songs.isEmpty, "Should return search results")
//                    print("Found \(songs.count) songs matching 'Bohemian'")
//                }
//            )
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    // MARK: - Discogs API Tests
//    func testFetchSongsFromDiscogs() {
//        let expectation = XCTestExpectation(description: "Fetch songs from Discogs")
//        
//        apiService.fetchSongsFromDiscogs(artist: "Pink Floyd")
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        expectation.fulfill()
//                    case .failure(let error):
//                        // Discogs API might fail without proper token, which is expected
//                        print("Discogs API call failed (expected without token): \(error.localizedDescription)")
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { songs in
//                    XCTAssertFalse(songs.isEmpty, "Should return songs from API")
//                    print("Received \(songs.count) songs from Discogs")
//                }
//            )
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    func testSearchSongsFromDiscogs() {
//        let expectation = XCTestExpectation(description: "Search songs from Discogs")
//        
//        apiService.searchSongsFromDiscogs(query: "Dark Side")
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        expectation.fulfill()
//                    case .failure(let error):
//                        // Discogs API might fail without proper token, which is expected
//                        print("Discogs API call failed (expected without token): \(error.localizedDescription)")
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { songs in
//                    XCTAssertFalse(songs.isEmpty, "Should return search results")
//                    print("Found \(songs.count) songs matching 'Dark Side'")
//                }
//            )
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    // MARK: - Error Handling Tests
//    func testInvalidURL() {
//        let expectation = XCTestExpectation(description: "Handle invalid URL")
//        
//        // This should trigger an invalid URL error
//        apiService.fetchSongsFromAudioDB(artist: "")
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        XCTFail("Should not complete successfully with invalid URL")
//                    case .failure(let error):
//                        XCTAssertTrue(error is APIError, "Should return APIError")
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { _ in
//                    XCTFail("Should not receive value with invalid URL")
//                }
//            )
//            .store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 5.0)
//    }
//} 
