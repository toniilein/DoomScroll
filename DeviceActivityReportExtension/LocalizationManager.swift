import SwiftUI
import Foundation

/// Manages app language override for the extension. Reads from shared UserDefaults.
class LocalizationManager {
    static let shared = LocalizationManager()

    var appLanguage: String {
        UserDefaults(suiteName: "group.pookie1.shared")?.string(forKey: "appLanguage") ?? "system"
    }

    var bundle: Bundle {
        let lang: String
        if appLanguage == "system" {
            lang = Locale.preferredLanguages.first?.prefix(2).lowercased() == "de" ? "de" : "en"
        } else {
            lang = appLanguage
        }

        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }

    func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(key)
}
