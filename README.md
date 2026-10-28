# ValidationRelay

A fork of [JJTech's ValidationRelay](https://github.com/JJTech0130/ValidationRelay).
The app is his work. This fork adds a Mac identity, so a relay iPhone can
register new devices again after Apple's October 2026 change, and safeguards
so that identity doesn't get lost.

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
- **Automatic builds.** GitHub Actions builds `ValidationRelay.tipa` on every
  push.

## Install

Requires an iPhone with [TrollStore](https://github.com/opa334/TrollStore).

1. Open the latest successful run under this repo's **Actions** tab and
   download the **ValidationRelay** artifact. It's a zip containing
   `ValidationRelay.tipa`.
2. Unzip it and install the `.tipa` with TrollStore. It installs over the
   original app and keeps its settings and registration code.
3. If Mac identity is on, tap **Copy Identity** and save it somewhere safe.

To build it yourself on a Mac with Xcode, install `ldid` (`brew install ldid`)
and run `./build.sh`.

## Using an existing registration

If you register through a proxy that already swaps the identity, such as
[OpenBubblesProxy](https://github.com/ziggy416/OpenBubblesProxy), leave Mac identity off. The proxy keeps doing that job.
To move off the proxy, register again with Mac identity on.
