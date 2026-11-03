# ValidationRelay-plus

A fork of [JJTech's ValidationRelay](https://github.com/JJTech0130/ValidationRelay),
based on his v1.8 release. This app is based off his work. This fork implements
the `activate` and `sign-data` bridge commands the current OpenBubbles release
needs, and generates the iMac identity `activate` requires, so a relay iPhone
keeps registering after Apple's October 2026 change — with safeguards so that
identity doesn't get lost.

It also includes the reliability fixes from
[Xare123's pull request #17](https://github.com/JJTech0130/ValidationRelay/pull/17),
which hasn't been merged into the original yet. His commits are applied
on top of v1.8 under his name.

<p align="center">
  <img src="docs/relay-plus-screen.png" width="300" alt="Relay+ settings screen">
  <br>
  <em>The app's one screen (UI mockup; the code, serial and UUID are examples).</em>
</p>

## What's different from the original

- **Activate & sign-data.** The 11/1/2026 OpenBubbles release sends two new
  bridge commands, `activate` and `sign-data`. This fork answers them:
  `activate` returns a generated iMac-format serial (an `iMac13,1` identity),
  and `sign-data` returns an empty response. `get-version-info` and the
  validation data report the phone's **real** serial and a persistent UUID —
  with `activate` implemented, Apple accepts the real serial again.
- **Updating re-registers.** This version reports a different identity than
  earlier Mac-identity builds, so after updating, reset the registration code
  and register your devices once more.
- **The identity stays the same.** It's created once and kept. Apple
  activates each serial number only once, so if the identity is lost or
  changed, registrations made with it stop renewing and must be done again.
- **Backup and restore.** **Copy Identity** copies the serial number and UUID
  so you can store them somewhere safe. **Enter Identity** restores them, for
  example after reinstalling the app.
- **Confirmations.** Generating a new identity and resetting the registration
  code both ask first. Resetting the code also creates a new identity, because
  a new registration needs one.
- **Reliability fixes** (Xare123, PR #17). Validation errors and timeouts
  are handled instead of crashing the app, reconnects are more dependable,
  low-level memory leaks are fixed, and the registration secret is kept in
  the Keychain and left out of the log. Custom relay addresses must start
  with `wss://`.
- **Automatic builds.** GitHub Actions builds `ValidationRelay.tipa` on every
  push.

## Install

Requires an iPhone with [TrollStore](https://github.com/opa334/TrollStore).

1. Download **[ValidationRelay.tipa](https://github.com/mkitchingh/ValidationRelay-plus/releases/latest/download/ValidationRelay.tipa)**
   (always the latest release). Do this on the iPhone, or AirDrop the file to it.
2. Open the `.tipa` with TrollStore and tap **Install**. It installs over the
   original app and keeps its settings and registration code. On the home
   screen it shows as **Relay+**.
3. If Mac Identity is on, open the app, tap **Copy Identity** and save it
   somewhere safe.

All releases are on the [Releases page](https://github.com/mkitchingh/ValidationRelay-plus/releases).

To build it yourself on a Mac with Xcode, install `ldid` (`brew install ldid`)
and run `./build.sh`.

## Mac Identity

**Why this exists:** in October 2026, Apple changed how iMessage activation
works, and the current OpenBubbles release (11/1/2026) added an `activate`
bridge command to match. When OpenBubbles sends `activate`, this app answers
with a generated **iMac-format serial** (an `iMac13,1` identity). `get-version-info`
and the validation data keep reporting the phone's **real** serial and a
persistent UUID — with `activate` supplying the Mac serial, Apple accepts the
real identity again.

There's no on/off switch and nothing to configure: the iMac serial is generated
automatically the first time it's needed. The only thing to do is tap **Copy
Identity** once and keep the serial and UUID somewhere safe, because Apple
activates each serial only once.

Buttons under **Identity settings**:

- **Copy Identity** — copies the serial and UUID. Save them; this is your backup.
- **Enter Identity** — restores a saved identity, for example after reinstalling
  or moving to a new phone, so you don't have to register again.
- **Generate New Identity** — makes a fresh one. You'll have to register again,
  because Apple activates each serial only once.

**Updating from an earlier build:** older versions of this app swapped the Mac
serial into `get-version-info` instead of using `activate`. This version reports
a different identity, so after updating, tap **Reset Registration Code** and
register your devices once more.

## Related

[registration-relay-selfhost](https://github.com/mkitchingh/registration-relay-selfhost) — a self-hosted, drop-in replacement for Beeper's registration relay. Run your own instead of depending on Beeper's.
