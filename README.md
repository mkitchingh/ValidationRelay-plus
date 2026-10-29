# ValidationRelay-plus

A fork of [JJTech's ValidationRelay](https://github.com/JJTech0130/ValidationRelay),
based on his v1.8 release. The app is his work. This fork adds a Mac identity, so a relay iPhone can
register new devices again after Apple's October 2026 change, and safeguards
so that identity doesn't get lost.

It also includes the reliability fixes from
[Xare123's pull request #17](https://github.com/JJTech0130/ValidationRelay/pull/17),
which hasn't been merged into the original yet. His commits are applied
on top of v1.8 under his name.

## What's different from the original

- **Mac identity.** Apple now refuses activations that report an iPhone's
  serial number and UDID. With **Mac Identity** on, the app reports an
  iMac-format serial number and a UUID in their place. Everything else it
  sends, including the validation data, is unchanged.
- **Safe for existing installs.** New installs start with Mac identity on.
  If you update an install that already has a registration code, it stays
  off, so nothing changes for a registration that's working. Turn it on when
  you're ready to register again.
- **The identity stays the same.** It's created once and kept. Apple
  activates each serial number only once, so if the identity is lost or
  changed, registrations made with it stop renewing and must be done again.
- **Backup and restore.** **Copy Identity** copies the serial number and UUID
  so you can store them somewhere safe. **Enter Identity** restores them, for
  example after reinstalling the app.
- **Confirmations.** Generating a new identity, turning Mac identity on or off
  while you have a registration, and resetting the registration code all ask
  first. Resetting the code also creates a new identity, because a new
  registration needs one.
- **Reliability fixes** (Xare123, PR #17). Validation errors and timeouts
  are handled instead of crashing the app, reconnects are more dependable,
  low-level memory leaks are fixed, and the registration secret is kept in
  the Keychain and left out of the log. Custom relay addresses must start
  with `wss://`.
- **Automatic builds.** GitHub Actions builds `ValidationRelay.tipa` on every
  push.

## Install

Requires an iPhone with [TrollStore](https://github.com/opa334/TrollStore).

1. Open the latest successful run under this repo's **Actions** tab and
   download the **ValidationRelay** artifact. It's a zip containing
   `ValidationRelay.tipa`.
2. Unzip it and install the `.tipa` with TrollStore. It installs over the
   original app and keeps its settings and registration code. On the home
   screen it shows as **Relay+**.
3. If Mac identity is on, tap **Copy Identity** and save it somewhere safe.

To build it yourself on a Mac with Xcode, install `ldid` (`brew install ldid`)
and run `./build.sh`.

## Mac Identity

**Identity settings** has one switch, **Mac Identity**, and it's on by default.
On a new install you don't need to touch it — the app registers as a Mac, which
is what Apple requires. Just tap **Copy Identity** once and keep the serial and
UUID somewhere safe.

What the buttons do:

- **Copy Identity** — copies the serial and UUID. Save them; this is your backup.
- **Enter Identity** — restores a saved identity, for example after reinstalling
  or moving to a new phone, so you don't have to register again.
- **Generate New Identity** — makes a fresh identity. You'll need to register
  again, because Apple activates each serial only once.

The switch is on by default. The one time it starts **off** is when you install
over a phone that already has a working registration, so the update can't change
what that phone reports and break it. Turn it on yourself (or tap **Enter
Identity** / **Generate New Identity**) when you're ready to register as a Mac.

Leaving Mac Identity off makes the phone report its own identity. Apple refuses
that at activation now, so it's kept only for flexibility — a normal setup
leaves it on.
