# Origin

Source project: [BasedHardware/omi](https://github.com/BasedHardware/omi).
Upstream baseline: `2ce52f13f4724eee989158da6318dc6f27aa744e`.

The snapshot includes local Personal Team/offline changes
(`8bbf848d905b32de395e8ee2fc9840e96ff9d0ee`) and WAV recording
(`bae122dbb48d0fe46bcab384736dee239328234f`). These reference the original
local commits for cross-checking; they are not ancestors of this history.

During preparation, components outside the MVP, demo materials, and
deployment workflows were removed; the README and top-level commands were
rewritten. Embedded upstream Team IDs were replaced with the
`OMI_APPLE_TEAM_ID` variable, Firebase presets with local emulator
fixtures; the upstream deployment verification token and generated
Custom.xcconfig were excluded. CV1 intake, WAV recording, and the network
restriction logic are preserved.

The [MIT license and the Based Hardware Contributors notice](LICENSE) are
kept, as are the original component agent guides. Dependency and third-party
asset licenses continue to apply to their components.
