import SwiftUI

@main
struct SoniqApp: App {
    @StateObject private var model = SoniqModel()
    @StateObject private var tester = HeadphoneTester()

    private static let menuBarIcon: NSImage = {
        guard let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else { return NSImage(systemSymbolName: "slider.vertical.3", accessibilityDescription: "Soniq")! }
        image.size = NSSize(width: 18, height: 18 * image.size.height / image.size.width)
        image.isTemplate = true
        return image
    }()

    var body: some Scene {
        MenuBarExtra {
            SoniqView()
                .environmentObject(model)
                .environmentObject(tester)
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
