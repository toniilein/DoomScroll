import ManagedSettings
import ManagedSettingsUI
import UIKit

class DoomScrollShieldConfiguration: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(name: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(name: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(name: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(name: webDomain.domain)
    }

    private func makeConfig(name: String?) -> ShieldConfiguration {
        let appName = name ?? "This app"

        // Read the current score to determine the kraken's mood message
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let score = shared?.integer(forKey: "lastBrainRotScore") ?? 50

        let message: String
        if score < 20 {
            message = "You're doing amazing! Don't ruin it by opening \(appName)."
        } else if score < 40 {
            message = "Stay strong! \(appName) can wait."
        } else if score < 60 {
            message = "\(appName) is blocked. Your kraken is watching..."
        } else if score < 80 {
            message = "Seriously? \(appName)? Your kraken is disappointed."
        } else {
            message = "NO. Put the phone down. \(appName) is blocked for your own good."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: UIColor(red: 0.969, green: 0.961, blue: 0.941, alpha: 1.0),
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Blocked by DoomScroll",
                color: UIColor(red: 0.239, green: 0.224, blue: 0.161, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: message,
                color: UIColor(red: 0.549, green: 0.522, blue: 0.467, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK, I'll do something else",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.855, green: 0.467, blue: 0.337, alpha: 1.0),
            secondaryButtonLabel: nil
        )
    }
}
