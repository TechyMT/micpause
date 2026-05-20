import Foundation

enum SpotifyState: String {
    case playing
    case paused
    case stopped
    case notRunning
    case unknown
}

enum SpotifyControl {
    static func playerState() -> SpotifyState {
        let script = """
        tell application "System Events"
            if not (exists (processes where name is "Spotify")) then return "notRunning"
        end tell
        tell application "Spotify"
            try
                return (player state as text)
            on error
                return "unknown"
            end try
        end tell
        """
        let raw = runOsascript(script).trimmingCharacters(in: .whitespacesAndNewlines)
        return SpotifyState(rawValue: raw) ?? .unknown
    }

    static func pauseIfPlaying() {
        let script = """
        tell application "System Events"
            if not (exists (processes where name is "Spotify")) then return
        end tell
        tell application "Spotify"
            try
                if player state is playing then pause
            end try
        end tell
        """
        _ = runOsascript(script)
    }

    @discardableResult
    private static func runOsascript(_ source: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
