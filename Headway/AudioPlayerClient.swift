import AVFoundation
import ComposableArchitecture
import Foundation

enum AudioPlayerError: Error {
    case fileNotFound(String)
    case initializationError(Error)
    case noActivePlayer
}

struct AudioPlayerClient: Sendable {
    var play: @Sendable (String, Double) async throws -> Void
    var resume: @Sendable (Double) async throws -> Void
    var pause: @Sendable () async throws -> Void
    var fastForward: @Sendable (TimeInterval) async throws -> Void
    var rewind: @Sendable (TimeInterval) async throws -> Void
    var changeSpeed: @Sendable (Double) async throws -> Void
    var seek: @Sendable (Double) async throws -> Void
    var currentTime: @Sendable () async throws -> TimeInterval
}

extension AudioPlayerClient: DependencyKey {
    static var liveValue: Self {
        let audioPlayer = AudioPlayer()
        return Self(
            play: { fileName, speed in
                try await audioPlayer.play(fileName: fileName, speed: speed)
            },
            resume: { speed in
                try await audioPlayer.resume(speed: speed)
            },
            pause: {
                try await audioPlayer.pause()
            },
            fastForward: { seconds in
                try await audioPlayer.fastForward(seconds)
            },
            rewind: { seconds in
                try await audioPlayer.rewind(seconds)
            },
            changeSpeed: { speed in
                try await audioPlayer.changeSpeed(speed)
            },
            seek: { progress in
                try await audioPlayer.seek(to: progress)
            },
            currentTime: {
                try await audioPlayer.currentTime()
            }
        )
    }
}

extension DependencyValues {
    var playerClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}

private actor AudioPlayer {
    private var player: AVAudioPlayer?

    fileprivate init() {}

    func play(fileName: String, speed: Double) throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            throw AudioPlayerError.fileNotFound(fileName)
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.enableRate = true
            newPlayer.rate = Float(speed)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            throw AudioPlayerError.initializationError(error)
        }
    }

    func resume(speed: Double) async throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.rate = Float(speed)
        player.play()
    }

    func pause() throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.pause()
    }

    func fastForward(_ seconds: TimeInterval) throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.currentTime = min(player.currentTime + seconds, player.duration)
    }

    func rewind(_ seconds: TimeInterval) throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.currentTime = max(player.currentTime - seconds, 0)
    }

    func changeSpeed(_ speed: Double) throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.rate = Float(speed)
    }

    func seek(to progress: Double) throws {
        guard let player else { throw AudioPlayerError.noActivePlayer }
        player.currentTime = progress * player.duration
    }

    func currentTime() throws -> TimeInterval {
        guard let player else {
            throw AudioPlayerError.noActivePlayer
        }
        return player.currentTime
    }
}
