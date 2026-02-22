import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var menuBarVM = MenuBarViewModel()
    @AppStorage("showMenuBar") private var showMenuBar = true

    init() {
        ClaudeAPIClient.shared.isHostApp = true
    }

    var body: some Scene {
        WindowGroup(id: "settings") {
            SettingsView(onConfigSaved: { [weak menuBarVM] in
                menuBarVM?.reloadConfig()
            })
        }
        .windowResizability(.contentSize)

        MenuBarExtra(isInserted: $showMenuBar) {
            MenuBarPopoverView(viewModel: menuBarVM)
        } label: {
            Image(nsImage: menuBarVM.menuBarImage)
        }
        .menuBarExtraStyle(.window)
    }
}
