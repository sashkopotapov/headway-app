import ComposableArchitecture
import SwiftUI

@main
struct HeadwayApp: App {
    var body: some Scene {
        WindowGroup {
            BookPlayerView(
                store: Store(
                    initialState: BookPlayerFeature.State()
                ) { BookPlayerFeature() }
            )
        }
    }
}
