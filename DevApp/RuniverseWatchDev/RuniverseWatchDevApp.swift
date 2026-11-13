import RuniverseWatch
import SwiftUI

@main
struct RuniverseWatchDevApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: RuniverseWatchAppDelegate

    var body: some Scene {
        RuniverseWatchScene()
    }
}
