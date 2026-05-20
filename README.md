<p align="center">
  <img src="banner.png" alt="micpause" width="100%" />
</p>

<p align="center">
  <em>don't think · just pause</em><br/>
  <sub>roll 01 · 35mm · iso 400 · cross-processed</sub>
</p>

---

<p align="center">
  <img src="assets/headers/frame-01.png" alt="Frame 01 — The Shot" width="100%" />
</p>

> shot from the hip. mic flicks on, spotify drops out. you take the call. you do the work. nobody asked, nobody clapped. that's the whole point.

a tiny macOS daemon that **pauses spotify the moment your microphone goes hot**. lazily aggressive — it pauses once per activation and then gets out of your way. you resume the music, it doesn't argue. mic toggles off and back on, it re-arms. never auto-resumes. you stay in control of the volume knob.

> *built because external speakers + a live mic = an echo loop and a colleague asking "is that Drake?"*

---

<p align="center">
  <img src="assets/headers/frame-02.png" alt="Frame 02 — Exposure Settings" width="100%" />
</p>

| stop | value |
|------|-------|
| **lens**    | CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere` |
| **shutter** | event-driven · zero polling |
| **film**    | Swift 5.9 · macOS 12+ |
| **trigger** | rising edge (mic-on) ➜ pause if playing |
| **reset**   | falling edge (mic-off) ➜ re-arm |
| **flash**   | AppleScript ➜ Spotify.app |
| **mood**    | underexposed · deliberate · doesn't talk much |

no mic permission needed. we read device metadata, never the audio stream. macOS won't even put up a dialog for the input side. it'll ask once for *Automation → Spotify*. that's the only flash.

---

<p align="center">
  <img src="assets/headers/frame-03.png" alt="Frame 03 — Loading the Film" width="100%" />
</p>

```bash
git clone https://github.com/TechyMT/micpause.git "$HOME/Personal Repos/micpause"
cd "$HOME/Personal Repos/micpause"
swift build -c release
./.build/release/micpause              # foreground · prints every click of the shutter
```

want it always-on? push the button once:

```bash
./install.sh
```

builds, drops the binary in `~/.local/bin/micpause`, lays down a LaunchAgent in `~/Library/LaunchAgents/`, and symlinks the `micpausectl` control script next to it. auto-starts at login. respawns on crash. mostly invisible.

---

<p align="center">
  <img src="assets/headers/frame-04.png" alt="Frame 04 — The Control Dial" width="100%" />
</p>

one little knob, ten little settings:

```bash
micpausectl status         # is it loaded? running? boot-enabled?
micpausectl start          # bring it back
micpausectl stop           # kill it (until next login)
micpausectl restart
micpausectl toggle         # the fast on/off switch ⟵ use this one
micpausectl disable        # stop now + block from login start
micpausectl enable         # re-allow login start
micpausectl logs           # tail /tmp/micpause.log and .err
micpausectl uninstall      # nuke plist + binary
```

---

<p align="center">
  <img src="assets/headers/frame-05.png" alt="Frame 05 — Contact Sheet" width="100%" />
</p>

```
┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│ ▶ spotify  │  │ 🎙 mic on  │  │ ⏸ paused   │  │ ▶ you      │
│ playing    │─▶│ photo booth│─▶│ within     │─▶│ resume     │
│ at desk    │  │ launches   │  │ ~200ms     │  │ manually   │
└────────────┘  └────────────┘  └────────────┘  └────────────┘
                                                       │
┌────────────┐  ┌────────────┐  ┌────────────┐         │
│ ▶ still    │  │ 🎙 mic off │  │ ▶ stays    │ ◀───────┘
│ playing    │◀─│ call ends  │◀─│ playing    │
│ rearmed    │  │            │  │ no resume  │
└────────────┘  └────────────┘  └────────────┘
```

> *the daemon doesn't decide. you decide. it just pulls the chain once when the mic clicks.*

---

<p align="center">
  <img src="assets/headers/frame-06.png" alt="Frame 06 — Developer Notes" width="100%" />
</p>

- **why CoreAudio and not `lsof` polling?** because polling is for people who like burning CPU. `kAudioDevicePropertyDeviceIsRunningSomewhere` fires a callback. zero overhead. zero lag.
- **why only spotify?** because the brief said spotify. apple music, youtube music, chrome tabs — not in this roll. maybe roll 02.
- **why no auto-resume?** because nothing is louder than music blasting back on at the *exact* moment a colleague says something you weren't supposed to hear.
- **airpods mid-call?** handled — a topology listener re-enumerates input devices when the audio landscape changes.

---

<p align="center">
  <img src="assets/headers/frame-07.png" alt="Frame 07 — Darkroom" width="100%" />
</p>

1. open spotify · hit play
2. open photo booth (or any mic-using app) ➜ spotify pauses inside ~200ms
3. hit play in spotify while photo booth is still open ➜ stays playing (we're disarmed)
4. quit photo booth ➜ spotify stays wherever you left it (no auto-resume)
5. re-open photo booth ➜ pauses again (re-armed on the rising edge)

if any of these don't fire, check `micpausectl logs`.

---

<p align="center">
  <img src="assets/headers/frame-08.png" alt="Frame 08 — End of Roll" width="100%" />
</p>

```
                   ▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓
                       sprocket holes · the end
                              · click ·
```

made by [@TechyMT](https://github.com/TechyMT) · MIT · no warranty, no apologies

<sub>header banners regenerable via `python3 tools/generate_headers.py` · requires Pillow</sub>
