import ComposableArchitecture
import SwiftUI

struct BookPlayerView: View {
    @Bindable var store: StoreOf<BookPlayerFeature>

    var body: some View {
        NavigationView {
            if store.isLoading {
                ProgressView("Loading Book…")
            } else if let book = store.book {
                VStack(alignment: .center, spacing: 32) {
                    playerImage(book: book)

                    keyPointView(
                        book: book,
                        selectedIndex: store.selectedChapterIndex
                    )
                    .padding(.horizontal)

                    progressView

                    speedButton

                    controlButtons

                    Spacer()
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.loadBook)
        }
    }

    private func playerImage(book: Book) -> some View {
        Image(resource: book.coverFileName)
            .resizable()
            .scaledToFit()
            .frame(width: 250)
            .cornerRadius(10)
    }

    private func keyPointView(book: Book, selectedIndex _: Int) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Text(
                "KEY POINT \(store.selectedChapterIndex + 1) OF \(book.chapters.count)"
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.gray)

            Text(book.chapters[store.selectedChapterIndex].keyPoint)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
        }
    }

    private var progressView: some View {
        HStack(alignment: .center) {
            Text(formatTime(store.playbackProgress * store.duration))
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 44)

            Slider(
                value: $store.playbackProgress.sending(\.seek),
                in: 0 ... 1
            )
            .accentColor(.blue)

            Text(formatTime(store.duration))
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 44)
        }
    }

    private var speedButton: some View {
        Button(action: {
            let newSpeed = store.playbackSpeed == 1.0 ? 1.5 : 1.0
            store.send(.changeSpeed(newSpeed))
        }) {
            Text("Speed x\(String(format: "%.1f", store.playbackSpeed))")
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }

    private var controlButtons: some View {
        HStack(alignment: .center, spacing: 32) {
            Button(action: { store.send(.selectPreviousChapter) }) {
                Image(systemName: "backward.end")
                    .font(.system(size: 24))
            }

            Button(action: { store.send(.rewind) }) {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 24))
            }

            Button(action: { store.send(.playPauseTapped) }) {
                Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
            }

            Button(action: { store.send(.fastForward) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 24))
            }

            Button(action: { store.send(.selectNexChapter) }) {
                Image(systemName: "forward.end")
                    .font(.system(size: 24))
            }
        }
    }

    /// Helper method to format a time interval (in seconds) as mm:ss.
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Image {
    init(resource name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: ""),
              let uiImage = UIImage(contentsOfFile: path)
        else {
            self.init(systemName: "book")
            return
        }
        self.init(uiImage: uiImage)
    }
}

#Preview {
    BookPlayerView(
        store: Store(
            initialState: BookPlayerFeature.State()
        ) { BookPlayerFeature() }
    )
}
