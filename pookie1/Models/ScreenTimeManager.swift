import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var activitySelection = FamilyActivitySelection()
    @Published var isAuthorized = false

    enum AuthorizationStatus {
        case notDetermined, approved, denied
    }

    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    private init() {
        loadSelection()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            isAuthorized = true
        } catch {
            authorizationStatus = .denied
            isAuthorized = false
        }
    }

    // MARK: - Selection Persistence

    func saveSelection() {
        guard let defaults = userDefaults else { return }
        let data = try? encoder.encode(activitySelection)
        defaults.set(data, forKey: AppGroupConstants.selectionKey)
    }

    func loadSelection() {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: AppGroupConstants.selectionKey),
              let decoded = try? decoder.decode(FamilyActivitySelection.self, from: data)
        else { return }
        activitySelection = decoded
    }

    // MARK: - Filter

    var currentFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(
                during: Calendar.current.dateInterval(of: .day, for: .now)!
            ),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens
        )
    }

    var hasSelectedApps: Bool {
        !activitySelection.applicationTokens.isEmpty ||
        !activitySelection.categoryTokens.isEmpty
    }
}
