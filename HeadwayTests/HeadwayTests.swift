import ComposableArchitecture
import Foundation
@testable import Headway
import Testing

struct HeadwayTests {
    @Test
    func loadBookSuccess() async {
        let sampleBook = self.sampleBook
        
        let store = await TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        } withDependencies: {
            $0.parserClient.loadBook = { _ in sampleBook }
        }
        
        await store.send(.loadBook) {
            $0.isLoading = true
        }
        
        await store.receive(.bookLoaded(.success(sampleBook)), timeout: 2) {
            $0.book = sampleBook
            $0.duration = sampleBook.chapters[0].duration
            $0.isLoading = false
        }
    }
    
    @Test
    func loadBookFailure() async {
        let error = NSError(domain: "testing", code: 999)
        let store = await TestStore(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        } withDependencies: {
            $0.parserClient.loadBook = { _ in throw error }
        }
        
        await store.send(.loadBook) {
            $0.isLoading = true
        }
        
        await store.receive(.bookLoaded(.failure(error))) {
            $0.isLoading = false
            $0.alert = AlertState {
                TextState("Something went wrong!")
            } actions: {
                ButtonState(role: .cancel, action: .dismiss) {
                    TextState("OK")
                }
            } message: {
                TextState(error.localizedDescription)
            }
        }
    }
    
    @Test
    func playPauseTappedStartsPlayWhenNotResuming() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.duration = sampleBook.chapters[0].duration
        
        let clock = TestClock()
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _, _ in }
            $0.playerClient.pause = {}
            $0.playerClient.currentTime = { 10 }
            $0.continuousClock = clock
        }
        
        await store.send(.playPauseTapped) {
            $0.isPlaying = true
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(.updateProgress(10)) {
            let progress = 10 / sampleBook.chapters[0].duration
            $0.playbackProgress = progress
        }
        
        await store.send(.playPauseTapped) {
            $0.isPlaying = false
        }
    }
    
    @Test
    func selectPreviousChapterNotPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 1
        state.duration = sampleBook.chapters[1].duration
        state.playbackProgress = 0.5
        state.isPlaying = false
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.selectPreviousChapter) {
            $0.selectedChapterIndex = 0
            $0.duration = sampleBook.chapters[0].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func selectPreviousChapterPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 1
        state.duration = sampleBook.chapters[1].duration
        state.playbackProgress = 0.5
        state.isPlaying = true
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _, _ in }
        }
        
        await store.send(.selectPreviousChapter) {
            $0.selectedChapterIndex = 0
            $0.duration = sampleBook.chapters[0].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func selectNextChapterNotPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 0
        state.duration = sampleBook.chapters[0].duration
        state.playbackProgress = 0.5
        state.isPlaying = false
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.selectNexChapter) {
            $0.selectedChapterIndex = 1
            $0.duration = sampleBook.chapters[1].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func selectNextChapterPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 0
        state.duration = sampleBook.chapters[0].duration
        state.playbackProgress = 0.5
        state.isPlaying = true
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _, _ in }
        }
        
        await store.send(.selectNexChapter) {
            $0.selectedChapterIndex = 1
            $0.duration = sampleBook.chapters[1].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func seekSuccess() async {
        var state = BookPlayerFeature.State()
        state.playbackProgress = 0.3
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.seek = { _ in }
        }
        
        await store.send(.seek(0.5)) {
            $0.playbackProgress = 0.5
        }
    }
    
    @Test
    func seekFailure() async {
        var state = BookPlayerFeature.State()
        state.playbackProgress = 0.3
        let error = NSError(domain: "testing", code: 999)
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.seek = { _ in
                throw error
            }
        }
        
        await store.send(.seek(0.5)) {
            $0.playbackProgress = 0.5
        }
        
        await store.receive(.playerErrored(error.localizedDescription)) {
            $0.alert = AlertState {
                TextState("Something went wrong!")
            } actions: {
                ButtonState(role: .cancel, action: .dismiss) {
                    TextState("OK")
                }
            } message: {
                TextState(error.localizedDescription)
            }
        }
    }
    
    @Test
    func updateProgressUpdatesState() async {
        var state = BookPlayerFeature.State()
        state.duration = 300
        state.playbackProgress = 0.0
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.updateProgress(150)) {
            $0.playbackProgress = 150 / 300.0
        }
    }
    
    @Test
    func updateProgressTriggersChapterFinished() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.duration = 300
        state.playbackProgress = 0.0
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.updateProgress(299))
        await store.receive(.chapterFinished) {
            $0.selectedChapterIndex = 1
            $0.duration = sampleBook.chapters[1].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func chapterFinishedNotPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 0
        state.duration = sampleBook.chapters[0].duration
        state.isPlaying = false
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.chapterFinished) {
            $0.selectedChapterIndex = 1
            $0.duration = sampleBook.chapters[1].duration
            $0.playbackProgress = 0.0
        }
    }
    
    @Test
    func chapterFinishedPlaying() async {
        var state = BookPlayerFeature.State()
        state.book = sampleBook
        state.selectedChapterIndex = 0
        state.duration = sampleBook.chapters[0].duration
        state.isPlaying = true
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        } withDependencies: {
            $0.playerClient.play = { _, _ in }
        }
        
        await store.send(.chapterFinished) {
            $0.selectedChapterIndex = 1
            $0.duration = sampleBook.chapters[1].duration
            $0.playbackProgress = 0.0
        }
    }
        
    @Test
    func alertDismissal() async {
        var state = BookPlayerFeature.State()
        state.alert = AlertState {
            TextState("Something went wrong!")
        } actions: {
            ButtonState(role: .cancel, action: .dismiss) {
                TextState("OK")
            }
        } message: {
            TextState("Error")
        }
        
        let store = await TestStore(initialState: state) {
            BookPlayerFeature()
        }
        
        await store.send(.alert(.presented(.dismiss))) {
            $0.alert = nil
        }
    }
    var sampleBook: Book {
        Book(
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald",
            publishedIn: 1925,
            chapters: [
                Chapter(
                    chapterNumber: 1,
                    title: "Chapter 1",
                    keyPoint: "The mysterious millionaire emerges.",
                    audioFileName: "gatsby_ch1.mp3",
                    duration: 300,
                    content: "In my younger and more vulnerable years..."
                ),
                Chapter(
                    chapterNumber: 2,
                    title: "Chapter 2",
                    keyPoint: "The valley of ashes reveals its secrets.",
                    audioFileName: "gatsby_ch2.mp3",
                    duration: 320,
                    content: "About half way between West Egg and New York..."
                ),
            ],
            coverFileName: "greatgatsby.jpg"
        )
    }
}
