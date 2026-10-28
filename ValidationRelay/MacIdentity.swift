//
//  MacIdentity.swift
//  ValidationRelay
//
//  Since October 2026, Apple refuses activations that present an iPhone's
//  serial number and UDID from software, but accepts a correctly formatted
//  iMac serial number plus a UUID. When the Mac identity is turned on, the
//  relay reports these two values in get-version-info in place of the
//  phone's own. Everything else is reported unchanged.
//
//  Apple activates each serial number once, so an identity must stay the same
//  for as long as the registration that used it. It only changes when the
//  user explicitly asks for a new one.
//

import Foundation

struct MacIdentity: Equatable {
    let serialNumber: String
    let uniqueDeviceID: String

    // iMac13,1 model codes (the last 4 characters of a 12-character serial)
    private static let modelCodes = [
        "DNCT", "DNCR", "DNML", "DNMM", "F8QM", "F8QN", "F9RN",
        "FC6M", "FC6N", "FC6P", "FD55", "FD5Y", "FF7L"
    ]
    private static let years = Array("CDFGHJKLMNPQRSTUVWX")
    private static let weeks = Array("123456789CDFGHJKLMNPQRSTVW")
    // Apple serials never use I or O
    private static let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789")

    /// A new random identity: C02 + year + week + 3 characters + model code.
    static func generate() -> MacIdentity {
        let unique = String((0..<3).map { _ in characters.randomElement()! })
        let serial = "C02" + String(years.randomElement()!) + String(weeks.randomElement()!)
            + unique + modelCodes.randomElement()!
        return MacIdentity(serialNumber: serial, uniqueDeviceID: UUID().uuidString.uppercased())
    }

    /// Validates and normalizes values typed in by the user.
    /// Returns nil and an error message when either value is malformed.
    static func parse(serial: String, uuid: String) -> (MacIdentity?, String?) {
        let s = serial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let u = uuid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let allowed = Set(characters)
        if s.count != 12 || !s.hasPrefix("C02") || !s.allSatisfy({ allowed.contains($0) }) {
            return (nil, "The serial number must be 12 characters, start with C02, and use only A-Z (no I or O) and 0-9.")
        }
        guard let parsed = UUID(uuidString: u) else {
            return (nil, "The UUID must look like 1A2B3C4D-1A2B-1A2B-1A2B-1A2B3C4D5E6F.")
        }
        return (MacIdentity(serialNumber: s, uniqueDeviceID: parsed.uuidString.uppercased()), nil)
    }

    /// Both values on one line each, for copying somewhere safe.
    var backupText: String {
        "Serial: \(serialNumber)\nUUID: \(uniqueDeviceID)"
    }
}

/// Persists the Mac identity and the setting that turns it on.
enum MacIdentityStore {
    static let enabledKey = "macIdentityEnabled"
    private static let serialKey = "macIdentitySerialNumber"
    private static let uuidKey = "macIdentityUniqueDeviceID"

    private static var defaults: UserDefaults { .standard }

    /// Picks the default the first time this version runs. New installs get
    /// the Mac identity. Installs that already have a registration keep
    /// reporting the phone's own identity, so an update never changes what an
    /// existing registration is using.
    static func setDefaultIfNeeded() {
        if defaults.object(forKey: enabledKey) != nil { return }
        let alreadyRegistered = !(defaults.string(forKey: "savedRegistrationCode") ?? "").isEmpty
        defaults.set(!alreadyRegistered, forKey: enabledKey)
    }

    static var isEnabled: Bool {
        defaults.bool(forKey: enabledKey)
    }

    static var current: MacIdentity? {
        guard let serial = defaults.string(forKey: serialKey),
              let uuid = defaults.string(forKey: uuidKey),
              !serial.isEmpty, !uuid.isEmpty else { return nil }
        return MacIdentity(serialNumber: serial, uniqueDeviceID: uuid)
    }

    /// The stored identity, creating one the first time it's needed.
    static func currentOrCreate() -> MacIdentity {
        if let existing = current { return existing }
        let created = MacIdentity.generate()
        save(created)
        return created
    }

    static func save(_ identity: MacIdentity) {
        defaults.set(identity.serialNumber, forKey: serialKey)
        defaults.set(identity.uniqueDeviceID, forKey: uuidKey)
    }
}
