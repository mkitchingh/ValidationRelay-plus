//
//  MacIdentity.swift
//  ValidationRelay
//
//  Since October 2026, Apple refuses activations that present an iPhone's
//  serial number from software, but accepts a correctly formatted iMac serial
//  number. This app generates and stores one iMac-format serial and sends it
//  in the `activate` bridge command (see buildActivationPayload in Relay.swift);
//  get-version-info and get-validation-data report the phone's real identity.
//
//  Apple activates each serial number once, so the identity must stay the same
//  for as long as the registration that used it. It only changes when the user
//  explicitly asks for a new one, which is why Copy / Enter Identity back it up
//  and restore it.
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

/// Persists the generated iMac identity used for the `activate` command.
enum MacIdentityStore {
    private static let serialKey = "macIdentitySerialNumber"
    private static let uuidKey = "macIdentityUniqueDeviceID"

    private static var defaults: UserDefaults { .standard }

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
