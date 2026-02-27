import Combine
import Foundation
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
import ManagedSettings
#endif

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isAuthorized = false

    #if !targetEnvironment(simulator)
    @Published var activitySelection = FamilyActivitySelection()
    #endif

    // Simulator mock state
    @Published var mockSelectedAppCount = 0
    @Published var mockSelectedCategoryCount = 0

    enum AuthorizationStatus {
        case notDetermined, approved, denied
    }

    #if !targetEnvironment(simulator)
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    private let center = DeviceActivityCenter()
    #endif

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    private init() {
        #if !targetEnvironment(simulator)
        loadSelection()
        checkExistingAuthorization()
        #endif
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        authorizationStatus = .approved
        isAuthorized = true
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            isAuthorized = true
            startMonitoring()
        } catch {
            authorizationStatus = .denied
            isAuthorized = false
        }
        #endif
    }

    #if !targetEnvironment(simulator)
    private func checkExistingAuthorization() {
        // Check if we already have authorization from a previous launch
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            authorizationStatus = .approved
            isAuthorized = true
            startMonitoring()
        case .denied:
            authorizationStatus = .denied
            isAuthorized = false
        case .notDetermined:
            authorizationStatus = .notDetermined
            isAuthorized = false
        @unknown default:
            break
        }
    }
    #endif

    // MARK: - Activity Monitoring

    #if !targetEnvironment(simulator)
    func startMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                .dailyActivity,
                during: schedule
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    #endif

    // MARK: - Firebase Score Sync

    func pushScoreToFirebase(brainRotScore: Int, totalSeconds: TimeInterval) {
        let formatted = BrainRotCalculator.formatDuration(totalSeconds)
        Task {
            await FirebaseManager.shared.updateScore(
                brainRotScore: brainRotScore,
                totalScreenTimeSeconds: totalSeconds,
                formattedTime: formatted
            )
        }
    }

    // MARK: - Selection Persistence

    func saveSelection() {
        #if !targetEnvironment(simulator)
        guard let defaults = userDefaults else { return }
        let data = try? encoder.encode(activitySelection)
        defaults.set(data, forKey: AppGroupConstants.selectionKey)
        startMonitoring()
        #endif
    }

    func loadSelection() {
        #if !targetEnvironment(simulator)
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: AppGroupConstants.selectionKey),
              let decoded = try? decoder.decode(FamilyActivitySelection.self, from: data)
        else { return }
        activitySelection = decoded
        #endif
    }

    // MARK: - Filter

    #if !targetEnvironment(simulator)
    func filterForDate(_ date: Date) -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(
                during: Calendar.current.dateInterval(of: .day, for: date)!
            ),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens
        )
    }

    var currentFilter: DeviceActivityFilter {
        filterForDate(.now)
    }
    #endif

    var hasSelectedApps: Bool {
        #if targetEnvironment(simulator)
        return mockSelectedAppCount > 0 || mockSelectedCategoryCount > 0
        #else
        return !activitySelection.applicationTokens.isEmpty ||
               !activitySelection.categoryTokens.isEmpty
        #endif
    }
}

#if !targetEnvironment(simulator)
extension DeviceActivityName {
    static let dailyActivity = Self("dailyActivity")
}
#endif
