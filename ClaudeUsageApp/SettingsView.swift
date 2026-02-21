import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var sessionKey: String = ""
    @State private var organizationID: String = ""
    @State private var testResult: ConnectionTestResult?
    @State private var isTesting = false
    @State private var showSessionKey = false
    @State private var showGuide = false
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var importSuccess = false
    @State private var detectedBrowsers: [DetectedBrowser] = []
    @State private var showBrowserPicker = false

    private let bg = Color(hex: "#141416")
    private let cardBg = Color.white.opacity(0.04)
    private let accent = Color(hex: "#FF9F0A")
    private let accentRed = Color(hex: "#FF453A")
    private let green = Color(hex: "#32D74B")
    private let subtle = Color.white.opacity(0.4)
    private let faint = Color.white.opacity(0.06)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 28)
                    .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        credentialsCard
                        actionsRow
                        if let result = testResult {
                            resultBanner(result)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 0)

                footerSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 460, height: 520)
        .onAppear { loadConfig() }
        .sheet(isPresented: $showGuide) {
            guideSheet
        }
        .sheet(isPresented: $showBrowserPicker) {
            browserPickerSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("TokenEater")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Monitor your Claude usage")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(subtle)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Credentials Card

    private var credentialsCard: some View {
        VStack(spacing: 14) {
            // Auto-import from browser
            autoImportSection

            Rectangle()
                .fill(faint)
                .frame(height: 1)

            // Session Key
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Session Key")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(0.5)
                        .textCase(.uppercase)
                    Spacer()
                    Button {
                        showSessionKey.toggle()
                    } label: {
                        Image(systemName: showSessionKey ? "eye.slash" : "eye")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }

                Group {
                    if showSessionKey {
                        TextField("sk-ant-sid01-...", text: $sessionKey)
                    } else {
                        SecureField("sk-ant-sid01-...", text: $sessionKey)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }

            // Separator
            Rectangle()
                .fill(faint)
                .frame(height: 1)

            // Org ID
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Organization ID")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(0.5)
                        .textCase(.uppercase)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.2))
                    Text("cookie lastActiveOrg")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                }

                TextField("941eb286-b278-...", text: $organizationID)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .onChange(of: sessionKey) { saveConfig() }
        .onChange(of: organizationID) { saveConfig() }
    }

    // MARK: - Actions

    private var actionsRow: some View {
        HStack(spacing: 10) {
            // Test button
            Button {
                testConnection()
            } label: {
                HStack(spacing: 6) {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                    }
                    Text("Tester")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(sessionKey.isEmpty || organizationID.isEmpty ? .white.opacity(0.3) : .white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: sessionKey.isEmpty || organizationID.isEmpty
                                    ? [Color.white.opacity(0.04), Color.white.opacity(0.04)]
                                    : [accent, accentRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(sessionKey.isEmpty || organizationID.isEmpty || isTesting)

            // Refresh button
            Button {
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Rafraichir")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(sessionKey.isEmpty ? .white.opacity(0.3) : .white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(sessionKey.isEmpty)

            // Guide button
            Button {
                showGuide = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                    Text("Guide")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Result Banner

    private func resultBanner(_ result: ConnectionTestResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(result.success ? green : accentRed)

            Text(result.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(result.success ? green.opacity(0.1) : accentRed.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(result.success ? green.opacity(0.2) : accentRed.opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeOut(duration: 0.3), value: testResult?.success)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Les cookies expirent chaque mois")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.2))
            Spacer()
            Text("v1.0.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.15))
        }
    }

    // MARK: - Guide Sheet

    private var guideSheet: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sheet header
                HStack {
                    Text("Configuration")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showGuide = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        guideStep(1, "globe", "Ouvrez **claude.ai** dans Chrome et connectez-vous")
                        guideStep(2, "terminal", "Ouvrez les DevTools : **Cmd + Option + I**")
                        guideStep(3, "tray.full", "Onglet **Application** > **Cookies** > **claude.ai**")
                        guideStep(4, "key.fill", "Copiez le cookie **sessionKey**", detail: "sk-ant-sid01-...")
                        guideStep(5, "building.2", "Copiez le cookie **lastActiveOrg**", detail: "C'est l'Organization ID")
                        guideStep(6, "checkmark.circle", "Collez les deux valeurs et testez")

                        // Widget add instruction
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                                .foregroundStyle(accent)
                                .frame(width: 32, height: 32)
                                .background(accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ajouter le widget")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("Clic droit sur le bureau > **Modifier les widgets** > **TokenEater**")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accent.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accent.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(width: 440, height: 480)
    }

    private func guideStep(_ number: Int, _ icon: String, _ text: LocalizedStringKey, detail: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            .background(
                Circle().fill(
                    LinearGradient(
                        colors: [accent, accentRed],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    // MARK: - Auto Import

    private var autoImportSection: some View {
        VStack(spacing: 10) {
            Button {
                detectAndImport()
            } label: {
                HStack(spacing: 8) {
                    if isImporting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 13))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Importer depuis le navigateur")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Detecte automatiquement vos cookies Claude")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(.white.opacity(0.85))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.15), accentRed.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(accent.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isImporting)

            if let message = importMessage {
                HStack(spacing: 8) {
                    Image(systemName: importSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(importSuccess ? green : accent)
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }

    private func detectAndImport() {
        isImporting = true
        importMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let browsers = BrowserCookieReader.detectBrowsers()

            if browsers.isEmpty {
                DispatchQueue.main.async {
                    isImporting = false
                    importMessage = "Aucun navigateur Chromium detecte"
                    importSuccess = false
                }
                return
            }

            // If multiple browsers, show picker
            if browsers.count > 1 {
                DispatchQueue.main.async {
                    detectedBrowsers = browsers
                    showBrowserPicker = true
                    isImporting = false
                }
                return
            }

            // Single browser, try directly
            importFromBrowser(browsers[0])
        }
    }

    private func importFromBrowser(_ browser: DetectedBrowser) {
        isImporting = true
        importMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = BrowserCookieReader.importCookies(from: browser)

            DispatchQueue.main.async {
                isImporting = false
                switch result {
                case .success(let cookies):
                    sessionKey = cookies.sessionKey
                    organizationID = cookies.organizationID
                    saveConfig()
                    importMessage = "Importe depuis \(cookies.browser)"
                    importSuccess = true
                    showBrowserPicker = false
                case .failure(let error):
                    importMessage = "\(browser.name) : \(error.localizedDescription)"
                    importSuccess = false
                }
            }
        }
    }

    // MARK: - Browser Picker Sheet

    private var browserPickerSheet: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Choisir un navigateur")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showBrowserPicker = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }

                ForEach(detectedBrowsers) { browser in
                    Button {
                        importFromBrowser(browser)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: browserIcon(browser.id))
                                .font(.system(size: 18))
                                .foregroundStyle(accent)
                                .frame(width: 36, height: 36)
                                .background(accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(browser.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("\(browser.cookiePaths.count) profil(s)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.35))
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if isImporting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(accent)
                        Text("Import en cours...")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                if let message = importMessage, !importSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(accentRed)
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 360, height: 320)
    }

    private func browserIcon(_ id: String) -> String {
        switch id {
        case "chrome": return "globe"
        case "arc": return "circle.hexagongrid"
        case "brave": return "shield"
        case "edge": return "globe.americas"
        default: return "globe"
        }
    }

    // MARK: - Config Persistence

    private func loadConfig() {
        if let config = SharedStorage.readConfig(fromHost: true) {
            sessionKey = config.sessionKey
            organizationID = config.organizationID
        }
    }

    private func saveConfig() {
        let config = SharedConfig(sessionKey: sessionKey, organizationID: organizationID)
        SharedStorage.writeConfig(config, fromHost: true)
    }

    // MARK: - Actions

    private func testConnection() {
        isTesting = true
        testResult = nil
        saveConfig()

        Task {
            let result = await ClaudeAPIClient.shared.testConnection(
                sessionKey: sessionKey,
                orgID: organizationID
            )

            await MainActor.run {
                testResult = result
                isTesting = false

                if result.success {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
}
