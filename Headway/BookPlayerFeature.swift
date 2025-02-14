import ComposableArchitecture
import Foundation

@Reducer
struct BookPlayerFeature {
    @ObservableState
    struct State: Equatable {
        var book: Book?
        var isLoading = false

        var selectedChapterIndex = 0
        var isPlaying = false
        var playbackProgress = 0.0
        var playbackSpeed = 1.0
        var duration: TimeInterval = 0

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case loadBook
        case bookLoaded(TaskResult<Book>)

        case playPauseTapped
        case fastForward
        case rewind
        case changeSpeed(Double)
        case selectPreviousChapter
        case selectNexChapter
        case seek(Double)
        case updateProgress(TimeInterval)
        case chapterFinished

        case playerErrored(String)

        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case dismiss
            case error(message: String)
        }
    }

    private enum CancelID { case progress }

    @Dependency(\.playerClient) var playerClient
    @Dependency(\.parserClient) var parserClient
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadBook:
                state.isLoading = true
                return .run { send in
                    do {
                        let book = try await self.parserClient
                            .loadBook(BookResource.happyPrince.rawValue)
                        await send(.bookLoaded(.success(book)))
                    } catch {
                        await send(.bookLoaded(.failure(error)))
                    }
                }

            case let .bookLoaded(.success(book)):
                state.book = book
                state.duration = book.chapters[safe: state.selectedChapterIndex]?.duration ?? 0
                state.isLoading = false
                return .none

            case let .bookLoaded(.failure(error)):
                state.isLoading = false
                state.alert = Self.makeAlert(message: error.localizedDescription)
                return .none

            case .playPauseTapped:
                guard let book = state.book else { return .none }
                if state.isPlaying {
                    state.isPlaying = false
                    return .merge(
                        .cancel(id: CancelID.progress),
                        runPlayerTask { try await self.playerClient.pause() }
                    )
                } else {
                    state.isPlaying = true
                    let speed = state.playbackSpeed
                    if state.playbackProgress > 0 {
                        return .merge(
                            runPlayerTask { try await self.playerClient.resume(speed) },
                            startProgressLoop()
                        )
                    } else {
                        guard let chapter = book.chapters[safe: state.selectedChapterIndex]
                        else { return .none }
                        return .merge(
                            playChapter(chapter, speed: speed),
                            startProgressLoop()
                        )
                    }
                }

            case .fastForward:
                if state.duration > 0 {
                    let currentTime = state.playbackProgress * state.duration
                    let newTime = min(currentTime + 10, state.duration)
                    state.playbackProgress = newTime / state.duration
                }
                return runPlayerTask { try await self.playerClient.fastForward(10) }

            case .rewind:
                if state.duration > 0 {
                    let currentTime = state.playbackProgress * state.duration
                    let newTime = max(currentTime - 5, 0)
                    state.playbackProgress = newTime / state.duration
                }
                return runPlayerTask { try await self.playerClient.rewind(5) }

            case let .changeSpeed(speed):
                state.playbackSpeed = speed
                return runPlayerTask { try await self.playerClient.changeSpeed(speed) }

            case .selectPreviousChapter:
                guard let book = state.book else { return .none }
                let newIndex = max(0, state.selectedChapterIndex - 1)
                return updateChapter(state: &state, newIndex: newIndex, in: book)

            case .selectNexChapter:
                guard let book = state.book else { return .none }
                let newIndex = min(state.selectedChapterIndex + 1, book.chapters.count - 1)
                return updateChapter(state: &state, newIndex: newIndex, in: book)

            case let .seek(progress):
                state.playbackProgress = progress
                return runPlayerTask { try await self.playerClient.seek(progress) }

            case let .updateProgress(currentTime):
                guard state.duration > 0 else { return .none }
                let newProgress = currentTime / state.duration
                if newProgress >= (1.0 - 0.01) {
                    return .send(.chapterFinished)
                } else {
                    state.playbackProgress = newProgress
                    return .none
                }

            case .chapterFinished:
                guard let book = state.book, !book.chapters.isEmpty else { return .none }
                let nextIndex = (state.selectedChapterIndex + 1) % book.chapters.count
                return updateChapter(state: &state, newIndex: nextIndex, in: book)

            case let .playerErrored(message):
                state.alert = Self.makeAlert(message: message)
                return .none

            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private static func makeAlert(message: String) -> AlertState<Action.Alert> {
        AlertState {
            TextState("Something went wrong!")
        } actions: {
            ButtonState(role: .cancel, action: .dismiss) {
                TextState("OK")
            }
        } message: {
            TextState(message)
        }
    }
}

private extension BookPlayerFeature {
    func runPlayerTask(_ task: @Sendable @escaping () async throws -> Void) -> Effect<Action> {
        .run { send in
            do {
                try await task()
            } catch {
                await send(.playerErrored(error.localizedDescription))
            }
        }
    }

    func startProgressLoop() -> Effect<Action> {
        .run { send in
            while !Task.isCancelled {
                try await self.clock.sleep(for: .seconds(0.5))
                let currentTime = try await self.playerClient.currentTime()
                await send(.updateProgress(currentTime))
            }
        }
        .cancellable(id: CancelID.progress, cancelInFlight: true)
    }

    func playChapter(_ chapter: Chapter, speed: Double) -> Effect<Action> {
        runPlayerTask { try await self.playerClient.play(chapter.audioFileName, speed) }
    }

    func updateChapter(state: inout State, newIndex: Int, in book: Book) -> Effect<Action> {
        guard let chapter = book.chapters[safe: newIndex] else { return .none }
        state.selectedChapterIndex = newIndex
        state.duration = chapter.duration
        state.playbackProgress = 0.0
        if state.isPlaying {
            return playChapter(chapter, speed: state.playbackSpeed)
        }
        return .none
    }
}
