//
//  ContentView.swift
//  ValidationRelay
//
//  Created by James Gill on 3/24/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("autoConnect") private var wantRelayConnected = false
    @AppStorage("keepAwake") private var keepAwake = true
    
    @AppStorage("selectedRelay") private var selectedRelay = "Beeper"
    @AppStorage("customRelayURL") private var customRelayURL = ""
    
    @AppStorage(MacIdentityStore.enabledKey) private var macIdentityEnabled = false
    @State private var macIdentity: MacIdentity? = nil
    @State private var pendingAction: PendingAction? = nil
    @State private var showingIdentityEntry = false
    @State private var copiedIdentity = false
    
    @ObservedObject var relayConnectionManager: RelayConnectionManager

    func getCurrentRelayURL() -> URL? {
        if selectedRelay == "Custom" {
            guard let components = URLComponents(string: customRelayURL.trimmingCharacters(in: .whitespacesAndNewlines)),
                  components.scheme?.lowercased() == "wss",
                  components.host?.isEmpty == false,
                  components.user == nil,
                  components.password == nil,
                  components.percentEncodedQuery == nil,
                  components.fragment == nil else {
                return nil
            }
            return components.url
        } else if selectedRelay == "pypush" {
            return URL(string: "wss://registration-relay.jjtech.dev/api/v1/provider")!
        }
        
        // Default to Beeper relay
        return URL(string: "wss://registration-relay.beeper.com/api/v1/provider")!
    }

    func connectCurrentRelay() {
        guard let url = getCurrentRelayURL() else {
            relayConnectionManager.connectionStatusMessage = "Custom relay must be a secure wss:// URL without embedded credentials or a query."
            return
        }
        relayConnectionManager.connectIfNeeded(url)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Relay", isOn: $wantRelayConnected)
                        .onChange(of: wantRelayConnected) { newValue in
                            // Connect or disconnect the relay
                            if newValue {
                                connectCurrentRelay()
                            } else {
                                relayConnectionManager.disconnect()
                            }
                        }
                    HStack {
                        Text("Registration Code")
                        Spacer()
                        Text(relayConnectionManager.registrationCode)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } footer: {
                    Text(relayConnectionManager.connectionStatusMessage)
                }
                Section {
                    //Toggle("Run in Background", isOn: .constant(false))
                    //    .disabled(true)
                    Picker("Relay", selection: $selectedRelay) {
                        Text("Beeper").tag("Beeper")
                        //Text("pypush").tag("pypush")
                        Text("Custom").tag("Custom")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedRelay) { newValue in
                        // Disconnect when the user is switching relay servers
                        wantRelayConnected = false
                    }
                    if (selectedRelay == "Custom") {
                        TextField("Custom Relay Server URL", text: $customRelayURL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                } header: {
                    Text("Connection settings")
                } footer: {
                    Text("Beeper's relay server is recommended for most users")
                }
                
                Section {
                    Toggle("Mac Identity", isOn: Binding(
                        get: { macIdentityEnabled },
                        set: { newValue in
                            if hasRegistration {
                                pendingAction = .setIdentityEnabled(newValue)
                            } else {
                                setIdentityEnabled(newValue)
                            }
                        }
                    ))
                } header: {
                    Text("Identity settings")
                } footer: {
                    Text(macIdentityEnabled
                         ? "On: this phone registers as a Mac — recommended, and what Apple requires. Below are the serial and UUID it reports. See the README for what this is and when to change it."
                         : "Off: this phone reports its own identity, which Apple no longer accepts at activation. Turn on to register as a Mac. See the README for details.")
                }

                if macIdentityEnabled, let identity = macIdentity {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Serial Number")
                            Text(identity.serialNumber)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UUID")
                            Text(identity.uniqueDeviceID)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Button(copiedIdentity ? "Copied" : "Copy Identity") {
                            UIPasteboard.general.string = identity.backupText
                            copiedIdentity = true
                        }
                        Button("Enter Identity...") {
                            showingIdentityEntry = true
                        }
                        Button("Generate New Identity") {
                            pendingAction = .newIdentity
                        }
                        .foregroundColor(.red)
                    } footer: {
                        Text("Tap Copy Identity and save it somewhere safe. Enter Identity restores a saved one later — on a new phone or after reinstalling — without registering again.")
                    }
                }
                
                Section {
                    // Navigation to Log page
                    NavigationLink(destination: LogView(logItems: relayConnectionManager.logItems)) {
                        Text("Log")
                    }
                    Button("Dim Display") {
                        UIScreen.main.brightness = 0.0
                        UIScreen.main.wantsSoftwareDimming = true
                    }
                    Toggle("Keep Awake", isOn: $keepAwake)
                        .onChange(of: keepAwake) { newValue in
                            UIApplication.shared.isIdleTimerDisabled = newValue
                        }
                    Button("Reset Registration Code") {
                        pendingAction = .resetRegistration
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                } footer: {
                    Text("You will need to re-enter the code on your other devices. Keep ValidationRelay open in the foreground and keep this iPhone awake.")
                }

                Section {
                    Text("Relay+ v\(appVersion)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.grouped)
            .navigationBarHidden(true)
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = keepAwake
                if wantRelayConnected {
                    connectCurrentRelay()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active,
                      wantRelayConnected,
                      let url = getCurrentRelayURL() else {
                    return
                }
                UIApplication.shared.isIdleTimerDisabled = keepAwake
                relayConnectionManager.refreshOnForeground(url)
            }
        }
        .onAppear {
            refreshIdentity()
        }
        .alert(item: $pendingAction) { action in
            confirmation(for: action)
        }
        .sheet(isPresented: $showingIdentityEntry) {
            IdentityEntryView(current: macIdentity) { identity in
                MacIdentityStore.save(identity)
                relayConnectionManager.logItems.log("Mac identity entered manually")
                refreshIdentity()
            }
        }
        
    }
    
    // MARK: - Mac identity
    
    enum PendingAction: Identifiable {
        case setIdentityEnabled(Bool)
        case newIdentity
        case resetRegistration
        
        var id: String {
            switch self {
            case .setIdentityEnabled(let on): return "setIdentityEnabled-\(on)"
            case .newIdentity: return "newIdentity"
            case .resetRegistration: return "resetRegistration"
            }
        }
    }
    
    var hasRegistration: Bool {
        !relayConnectionManager.savedRegistrationCode.isEmpty
    }

    /// Marketing version from the app bundle (e.g. "1.0.2"), shown at the bottom of the screen.
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    
    func refreshIdentity() {
        macIdentity = macIdentityEnabled ? MacIdentityStore.currentOrCreate() : MacIdentityStore.current
        copiedIdentity = false
    }
    
    func setIdentityEnabled(_ on: Bool) {
        macIdentityEnabled = on
        relayConnectionManager.logItems.log(on ? "Mac identity turned on" : "Mac identity turned off")
        refreshIdentity()
    }
    
    func generateNewIdentity() {
        let identity = MacIdentity.generate()
        MacIdentityStore.save(identity)
        relayConnectionManager.logItems.log("Generated new Mac identity")
        refreshIdentity()
    }
    
    func resetRegistration() {
        relayConnectionManager.savedRegistrationURL = ""
        relayConnectionManager.savedRegistrationCode = ""
        relayConnectionManager.savedRegistrationSecret = ""
        relayConnectionManager.registrationCode = "None"
        wantRelayConnected = false
        // Apple activates each serial number once, so a new registration
        // needs a new identity.
        if macIdentityEnabled {
            generateNewIdentity()
        }
    }
    
    func confirmation(for action: PendingAction) -> Alert {
        switch action {
        case .setIdentityEnabled(let on):
            return Alert(
                title: Text(on ? "Turn on Mac identity?" : "Turn off Mac identity?"),
                message: Text("This changes the identity your current registration uses. Its renewals may stop working, and you would need to register again."),
                primaryButton: .destructive(Text(on ? "Turn On" : "Turn Off")) { setIdentityEnabled(on) },
                secondaryButton: .cancel()
            )
        case .newIdentity:
            return Alert(
                title: Text("Generate a new identity?"),
                message: Text("Registrations made with the current identity will stop renewing and must register again. Copy the current identity first if you might need it."),
                primaryButton: .destructive(Text("Generate")) { generateNewIdentity() },
                secondaryButton: .cancel()
            )
        case .resetRegistration:
            return Alert(
                title: Text("Reset registration code?"),
                message: Text(macIdentityEnabled
                              ? "You will get a new code and a new Mac identity, and will need to register your other devices again."
                              : "You will get a new code and will need to register your other devices again."),
                primaryButton: .destructive(Text("Reset")) { resetRegistration() },
                secondaryButton: .cancel()
            )
        }
    }

}

/// Lets the user restore a saved identity, or enter one used elsewhere.
struct IdentityEntryView: View {
    let current: MacIdentity?
    let onSave: (MacIdentity) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var serial = ""
    @State private var uuid = ""
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Serial number (C02...)", text: $serial)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.allCharacters)
                    TextField("UUID", text: $uuid)
                        .font(.system(.footnote, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.allCharacters)
                } header: {
                    Text("These fields start filled with your current identity — not your clipboard. Edit them, or paste in an identity you saved earlier, then tap Save to replace the current one.")
                        .textCase(nil)
                } footer: {
                    Text(error ?? "Used to restore an identity you backed up with Copy Identity — for example on a new phone or after reinstalling.")
                        .foregroundColor(error == nil ? .secondary : .red)
                }
            }
            .navigationBarTitle("Enter Identity", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    let (identity, message) = MacIdentity.parse(serial: serial, uuid: uuid)
                    if let identity = identity {
                        onSave(identity)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        error = message
                    }
                }
            )
            .onAppear {
                serial = current?.serialNumber ?? ""
                uuid = current?.uniqueDeviceID ?? ""
            }
        }
    }
}

#Preview {
    ContentView(relayConnectionManager: RelayConnectionManager())
}
