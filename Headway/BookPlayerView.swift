import ComposableArchitecture
import SwiftUI

struct BookPlayerView: View {
    @Bindable var store: StoreOf<BookPlayerFeature>

    var body: some View {
        NavigationView {
            if store.isLoading {
                ProgressView("Loading Book…")
            } else if let book = store.book {
                VStack(spacing: 48) {
                    playerImage(for: book)

                    keyPointView(for: book)
                        .padding(.horizontal)

                    progressView

                    controlButtons

                    Spacer()
                }
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground))
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear { store.send(.loadBook) }
    }

    private func playerImage(for book: Book) -> some View {
        Image(resource: book.coverFileName)?
            .resizable()
            .scaledToFit()
            .frame(width: 220)
            .cornerRadius(10)
    }

    private func keyPointView(for book: Book) -> some View {
        VStack(spacing: 8) {
            Text("KEY POINT \(store.selectedChapterIndex + 1) OF \(book.chapters.count)")
                .font(.footnote)
                .foregroundColor(.gray)

            Text(book.chapters[store.selectedChapterIndex].keyPoint)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.primary)
    }

    private var progressView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Text(formatTime(store.playbackProgress * store.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 44)

                Slider(
                    value: $store.playbackProgress.sending(\.seek),
                    in: 0 ... 1
                )
                .accentColor(.blue)

                Text(formatTime(store.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 44)
            }

            Button(action: {
                let newSpeed = store.playbackSpeed == 1.0 ? 1.5 : 1.0
                store.send(.changeSpeed(newSpeed))
            }) {
                Text("\(String(format: "%.1f", store.playbackSpeed))x speed")
                    .font(.footnote)
                    .foregroundStyle(Color.primary)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
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
        .foregroundStyle(Color.primary)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Image {
    init?(resource name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: ""),
           let uiImage = UIImage(contentsOfFile: path)
        {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "book.pages")
        }
    }
}

#Preview {
    BookPlayerView(
        store: Store(initialState: BookPlayerFeature.State()) {
            BookPlayerFeature()
        }
    )
}
