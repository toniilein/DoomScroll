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
    private let center = DeviceActivityCenter()
    #endif

    private init() {
        #if !targetEnvironment(simulator)
        checkExistingAuthorization()
        loadSelection()
        #endif
    }

    // MARK: - Authorization

    @Published var authError: String?

    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        authorizationStatus = .approved
        isAuthorized = true
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            isAuthorized = true
            UserDefaults.standard.set(true, forKey: "screenTimeAuthorized")
            startMonitoring()
        } catch {
            authorizationStatus = .denied
            isAuthorized = false
            authError = error.localizedDescription
            print("\u{274C} Screen Time auth error: \(error)")
        }
        #endif
    }

    #if !targetEnvironment(simulator)
    private func checkExistingAuthorization() {
        let systemStatus = AuthorizationCenter.shared.authorizationStatus
        let hadPreviousAuth = UserDefaults.standard.bool(forKey: "screenTimeAuthorized")

        switch systemStatus {
        case .approved:
            authorizationStatus = .approved
            isAuthorized = true
            UserDefaults.standard.set(true, forKey: "screenTimeAuthorized")
            startMonitoring()
        case .denied:
            authorizationStatus = .denied
            isAuthorized = false
        case .notDetermined:
            if hadPreviousAuth {
                // Trust persisted flag immediately so UI doesn't flash onboarding
                authorizationStatus = .approved
                isAuthorized = true
                startMonitoring()
                // Verify in background
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } catch {
                        // Auth was revoked — show onboarding again
                        authorizationStatus = .notDetermined
                        isAuthorized = false
                        UserDefaults.standard.set(false, forKey: "screenTimeAuthorized")
                    }
                }
            } else {
                authorizationStatus = .notDetermined
                isAuthorized = false
            }
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
        do {
            let data = try JSONEncoder().encode(activitySelection)
            UserDefaults.standard.set(data, forKey: "savedActivitySelection")
            let hasApps = !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
            UserDefaults.standard.set(hasApps, forKey: "hasSelectedApps")
            print("\u{2705} Saved selection: \(activitySelection.applicationTokens.count) apps, \(activitySelection.categoryTokens.count) categories")
            startMonitoring()
        } catch {
            print("\u{274C} Failed to save selection: \(error)")
        }
        #endif
    }

    func loadSelection() {
        #if !targetEnvironment(simulator)
        guard let data = UserDefaults.standard.data(forKey: "savedActivitySelection") else {
            print("\u{26A0}\u{FE0F} No saved selection found")
            return
        }
        do {
            let decoded = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            activitySelection = decoded
            objectWillChange.send()
            print("\u{2705} Loaded selection: \(decoded.applicationTokens.count) apps, \(decoded.categoryTokens.count) categories")
        } catch {
            print("\u{274C} Failed to load selection: \(error)")
        }
        #endif
    }

    // MARK: - Filter

    #if !targetEnvironment(simulator)
    func filterForDate(_ date: Date) -> DeviceActivityFilter {
        let hasTokens = !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
        if hasTokens {
            return DeviceActivityFilter(
                segment: .daily(
                    during: Calendar.current.dateInterval(of: .day, for: date)!
                ),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens
            )
        } else {
            // Tokens didn't survive persistence — show all activity
            return DeviceActivityFilter(
                segment: .daily(
                    during: Calendar.current.dateInterval(of: .day, for: date)!
                ),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        }
    }

    func weeklyFilter() -> DeviceActivityFilter {
        let hasTokens = !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
        let interval = DateInterval(
            start: Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: -6, to: .now)!
            ),
            end: .now
        )
        if hasTokens {
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens
            )
        } else {
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        }
    }

    var currentFilter: DeviceActivityFilter {
        filterForDate(.now)
    }
    #endif

    var hasSelectedApps: Bool {
        #if targetEnvironment(simulator)
        return mockSelectedAppCount > 0 || mockSelectedCategoryCount > 0
        #else
        // Check live tokens first, fall back to persisted flag
        let liveHasApps = !activitySelection.applicationTokens.isEmpty ||
                          !activitySelection.categoryTokens.isEmpty
        if liveHasApps { return true }
        // Fallback: tokens may not survive JSON roundtrip but user did select before
        return UserDefaults.standard.bool(forKey: "hasSelectedApps")
        #endif
    }
}

#if !targetEnvironment(simulator)
extension DeviceActivityName {
    static let dailyActivity = Self("dailyActivity")
}
#endif
