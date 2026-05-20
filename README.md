<p align="center">
  <img src="banner.png" alt="micpause" width="100%" />
</p>

A tiny macOS daemon that pauses Spotify the moment your microphone goes hot.

Lazily aggressive: it pauses **once** per mic activation, then gets out of your way. Resume the music during a call — it stays resumed. The next time the mic toggles off and back on (new call, unmute, etc.), it re-arms and pauses again. It never auto-resumes — you control unpause.

Built to stop the echo loop when working from external speakers and a call comes in.

## How it works

- Listens to CoreAudio's `kAudioDevicePropertyDeviceIsRunningSomewhere` on every input device. Event-driven, zero polling.
- On the rising edge (any input device starts running): if Spotify is `playing`, send `pause` via AppleScript.
- On the falling edge: re-arm.
- A device-topology listener re-enumerates inputs when AirPods etc. connect mid-session.

## Requirements

- macOS 12+
- Swift 5.9+ (for building from source)

## Build & install

```bash
git clone https://github.com/TechyMT/micpause.git
cd micpause
./install.sh
```

`install.sh` builds the release binary, installs it to `~/.local/bin/micpause`, drops a LaunchAgent into `~/Library/LaunchAgents/`, and symlinks the `micpausectl` control script. The daemon auto-starts at login and respawns on crash.

To run in the foreground (useful for debugging):

```bash
swift build -c release
./.build/release/micpause
```

## Permissions

- **Microphone**: not required — we only read device metadata, not the audio stream.
- **Automation → Spotify**: macOS will prompt the first time we send `pause`. Click OK.

## Controlling the daemon

After install, `micpausectl` is on your PATH:

```
micpausectl status       # is it loaded, running, enabled at login?
micpausectl start        # start now
micpausectl stop         # stop until next login
micpausectl restart
micpausectl toggle       # stop if running, start if not
micpausectl disable      # stop now + block from starting at login
micpausectl enable       # allow it to start at login
micpausectl logs         # tail /tmp/micpause.log and .err
micpausectl uninstall    # stop + remove plist + remove binary
```

## Verifying behavior

1. Open Spotify and start playing.
2. Open any app that uses the mic (Photo Booth, Zoom). Spotify should pause within ~200ms.
3. Hit play in Spotify while the mic is still in use. It stays playing — the daemon is disarmed for this activation.
4. Close the mic-using app. Spotify stays wherever you left it.
5. Open it again. Spotify pauses again — re-armed on the new rising edge.

If something doesn't fire, check `micpausectl logs`.

## Uninstall

```bash
micpausectl uninstall
```

## License

MIT. See [LICENSE](LICENSE).
