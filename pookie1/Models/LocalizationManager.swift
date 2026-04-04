import SwiftUI
import Foundation
import Combine

/// Manages app language override. Uses system language by default.
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @AppStorage("appLanguage") var appLanguage: String = "system" {
        didSet {
            // Also write to shared defaults so extension can read it
            UserDefaults(suiteName: "group.pookie1.shared")?.set(appLanguage, forKey: "appLanguage")
            objectWillChange.send()
        }
    }

    /// Current bundle for localized strings
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

/// Shorthand for localized strings
func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(key)
}

/// LocalizedStringKey helper for SwiftUI Text views
func LK(_ key: String) -> LocalizedStringKey {
    LocalizedStringKey(L(key))
}
