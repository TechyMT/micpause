import Foundation

final class Controller {
    private var micOn: Bool = false
    private var armed: Bool = true
    private let stateQueue = DispatchQueue(label: "micpause.controller")

    func onMicAggregateChange(_ newMicOn: Bool) {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            let prev = self.micOn
            self.micOn = newMicOn

            if !prev && newMicOn {
                self.handleRisingEdge()
            } else if prev && !newMicOn {
                self.handleFallingEdge()
            }
        }
    }

    private func handleRisingEdge() {
        log("mic-on")
        guard armed else {
            log("not armed; skipping")
            return
        }
        let state = SpotifyControl.playerState()
        log("spotify state=\(state.rawValue)")
        if state == .playing {
            SpotifyControl.pauseIfPlaying()
            log("paused spotify")
        }
        armed = false
    }

    private func handleFallingEdge() {
        log("mic-off; re-arming")
        armed = true
    }

    private func log(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        FileHandle.standardOutput.write(Data("[\(ts)] \(message)\n".utf8))
    }
}

let controller = Controller()
let watcher = AudioWatcher(onAggregateChange: { controller.onMicAggregateChange($0) })
watcher.start()

FileHandle.standardOutput.write(Data("micpause started\n".utf8))
RunLoop.main.run()
