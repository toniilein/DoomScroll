import Combine
import Foundation
#if !targetEnvironment(simulator)
import FirebaseAuth
import FirebaseFirestore
#endif

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var isSignedIn = false
    @Published var currentUserProfile: UserProfile?
    @Published var friends: [Friendship] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var groups: [SocialGroup] = []
    @Published var isLoading = false
    @Published var needsUsernameSetup = false

    #if !targetEnvironment(simulator)
    private let db = Firestore.firestore()
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    #endif

    private init() {
        #if targetEnvironment(simulator)
        setupMockData()
        #endif
    }

    // MARK: - Auth

    func signInAnonymously() async {
        #if targetEnvironment(simulator)
        isSignedIn = true
        #else
        guard !isSignedIn else { return }
        isLoading = true
        do {
            let result = try await Auth.auth().signIn(anonymously: true)
            let uid = result.user.uid
            isSignedIn = true

            let docRef = db.collection("users").document(uid)
            let doc = try await docRef.getDocument()
            if doc.exists, let data = try? doc.data(as: UserProfile.self) {
                currentUserProfile = data
                needsUsernameSetup = false
                listenForFriends()
                listenForIncomingRequests()
                fetchGroups()
            } else {
                needsUsernameSetup = true
            }
        } catch {
            print("Auth error: \(error)")
        }
        isLoading = false
        #endif
    }

    func setupUsername(displayName: String, username: String) async -> Bool {
        #if targetEnvironment(simulator)
        currentUserProfile = UserProfile(
            id: "mock-uid-001", displayName: displayName, username: username,
            brainRotScore: 72, totalScreenTimeSeconds: 9900,
            formattedScreenTime: "2h 45m", lastUpdated: .now, createdAt: .now
        )
        needsUsernameSetup = false
        return true
        #else
        guard let uid = Auth.auth().currentUser?.uid else { return false }

        // Check username uniqueness
        let query = db.collection("users").whereField("username", isEqualTo: username.lowercased())
        let snapshot = try? await query.getDocuments()
        guard snapshot?.documents.isEmpty ?? true else { return false }

        let profile = UserProfile(
            id: uid, displayName: displayName, username: username.lowercased(),
            brainRotScore: 0, totalScreenTimeSeconds: 0,
            formattedScreenTime: "0m", lastUpdated: .now, createdAt: .now
        )

        do {
            try db.collection("users").document(uid).setData(from: profile)
            currentUserProfile = profile
            needsUsernameSetup = false
            listenForFriends()
            listenForIncomingRequests()
            return true
        } catch {
            print("Setup error: \(error)")
            return false
        }
        #endif
    }

    // MARK: - Score Updates

    func updateScore(brainRotScore: Int, totalScreenTimeSeconds: TimeInterval, formattedTime: String) async {
        #if targetEnvironment(simulator)
        currentUserProfile?.brainRotScore = brainRotScore
        currentUserProfile?.totalScreenTimeSeconds = totalScreenTimeSeconds
        currentUserProfile?.formattedScreenTime = formattedTime
        #else
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "brainRotScore": brainRotScore,
            "totalScreenTimeSeconds": totalScreenTimeSeconds,
            "formattedScreenTime": formattedTime,
            "lastUpdated": Timestamp(date: .now)
        ]

        // Update own profile
        try? await db.collection("users").document(uid).updateData(data)
        currentUserProfile?.brainRotScore = brainRotScore
        currentUserProfile?.totalScreenTimeSeconds = totalScreenTimeSeconds
        currentUserProfile?.formattedScreenTime = formattedTime
        currentUserProfile?.lastUpdated = .now

        // Update denormalized entries in each friend's subcollection
        for friend in friends {
            try? await db.collection("users").document(friend.id)
                .collection("friends").document(uid).updateData(data)
        }
        #endif
    }

    // MARK: - Friends

    func searchUsers(query: String) async -> [UserProfile] {
        #if targetEnvironment(simulator)
        guard !query.isEmpty else { return [] }
        return [
            UserProfile(id: "search1", displayName: "Riley", username: "rileybrainrot",
                        brainRotScore: 55, totalScreenTimeSeconds: 7200,
                        formattedScreenTime: "2h 00m", lastUpdated: .now, createdAt: .now),
            UserProfile(id: "search2", displayName: "Taylor", username: "taylordoom",
                        brainRotScore: 33, totalScreenTimeSeconds: 3600,
                        formattedScreenTime: "1h 00m", lastUpdated: .now, createdAt: .now)
        ]
        #else
        let lowered = query.lowercased()
        let snapshot = try? await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowered)
            .whereField("username", isLessThanOrEqualTo: lowered + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()

        return snapshot?.documents.compactMap { try? $0.data(as: UserProfile.self) }
            .filter { $0.id != Auth.auth().currentUser?.uid } ?? []
        #endif
    }

    func sendFriendRequest(toUID: String, toDisplayName: String) async {
        #if targetEnvironment(simulator)
        return
        #else
        guard let uid = Auth.auth().currentUser?.uid,
              let profile = currentUserProfile else { return }

        let request = FriendRequest(
            id: UUID().uuidString, fromUID: uid, fromDisplayName: profile.displayName,
            toUID: toUID, toDisplayName: toDisplayName,
            status: .pending, createdAt: .now
        )

        try? db.collection("friendRequests").addDocument(from: request)
        #endif
    }

    func acceptFriendRequest(_ request: FriendRequest) async {
        #if targetEnvironment(simulator)
        incomingRequests.removeAll { $0.id == request.id }
        friends.append(Friendship(
            id: request.fromUID, displayName: request.fromDisplayName,
            username: "user", brainRotScore: 50, totalScreenTimeSeconds: 5400,
            formattedScreenTime: "1h 30m", lastUpdated: .now
        ))
        #else
        guard let uid = Auth.auth().currentUser?.uid,
              let profile = currentUserProfile else { return }

        // Update request status
        let reqQuery = db.collection("friendRequests")
            .whereField("fromUID", isEqualTo: request.fromUID)
            .whereField("toUID", isEqualTo: request.toUID)
            .whereField("status", isEqualTo: "pending")
        let docs = try? await reqQuery.getDocuments()
        for doc in docs?.documents ?? [] {
            try? await doc.reference.updateData(["status": "accepted"])
        }

        // Fetch requester's profile
        let requesterDoc = try? await db.collection("users").document(request.fromUID).getDocument()
        let requester = try? requesterDoc?.data(as: UserProfile.self)

        // Add friendship for both users
        let myFriendship = Friendship(
            id: request.fromUID, displayName: request.fromDisplayName,
            username: requester?.username ?? "", brainRotScore: requester?.brainRotScore ?? 0,
            totalScreenTimeSeconds: requester?.totalScreenTimeSeconds ?? 0,
            formattedScreenTime: requester?.formattedScreenTime ?? "0m", lastUpdated: .now
        )
        try? db.collection("users").document(uid)
            .collection("friends").document(request.fromUID).setData(from: myFriendship)

        let theirFriendship = Friendship(
            id: uid, displayName: profile.displayName,
            username: profile.username, brainRotScore: profile.brainRotScore,
            totalScreenTimeSeconds: profile.totalScreenTimeSeconds,
            formattedScreenTime: profile.formattedScreenTime, lastUpdated: .now
        )
        try? db.collection("users").document(request.fromUID)
            .collection("friends").document(uid).setData(from: theirFriendship)
        #endif
    }

    func declineFriendRequest(_ request: FriendRequest) async {
        #if targetEnvironment(simulator)
        incomingRequests.removeAll { $0.id == request.id }
        #else
        let reqQuery = db.collection("friendRequests")
            .whereField("fromUID", isEqualTo: request.fromUID)
            .whereField("toUID", isEqualTo: request.toUID)
            .whereField("status", isEqualTo: "pending")
        let docs = try? await reqQuery.getDocuments()
        for doc in docs?.documents ?? [] {
            try? await doc.reference.updateData(["status": "declined"])
        }
        #endif
    }

    func removeFriend(uid friendUID: String) async {
        #if targetEnvironment(simulator)
        friends.removeAll { $0.id == friendUID }
        #else
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid)
            .collection("friends").document(friendUID).delete()
        try? await db.collection("users").document(friendUID)
            .collection("friends").document(uid).delete()
        #endif
    }

    // MARK: - Groups

    func createGroup(name: String, memberUIDs: [String]) async {
        #if targetEnvironment(simulator)
        let group = SocialGroup(
            id: UUID().uuidString, name: name, memberUIDs: memberUIDs,
            createdBy: "mock-uid-001", createdAt: .now
        )
        groups.append(group)
        #else
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var allMembers = memberUIDs
        if !allMembers.contains(uid) { allMembers.insert(uid, at: 0) }

        let group = SocialGroup(
            id: UUID().uuidString, name: name, memberUIDs: allMembers,
            createdBy: uid, createdAt: .now
        )
        try? db.collection("groups").addDocument(from: group)
        fetchGroups()
        #endif
    }

    func fetchGroups() {
        #if !targetEnvironment(simulator)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            let snapshot = try? await db.collection("groups")
                .whereField("memberUIDs", arrayContains: uid)
                .getDocuments()
            groups = snapshot?.documents.compactMap { try? $0.data(as: SocialGroup.self) } ?? []
        }
        #endif
    }

    func fetchGroupMembers(group: SocialGroup) async -> [GroupMember] {
        #if targetEnvironment(simulator)
        return [
            GroupMember(id: "m1", displayName: "Sam", brainRotScore: 15, formattedScreenTime: "30m"),
            GroupMember(id: "m2", displayName: "You", brainRotScore: 72, formattedScreenTime: "2h 45m"),
            GroupMember(id: "m3", displayName: "Jordan", brainRotScore: 88, formattedScreenTime: "4h 00m"),
        ].sorted { $0.brainRotScore < $1.brainRotScore }
        #else
        var members: [GroupMember] = []
        for memberUID in group.memberUIDs {
            let doc = try? await db.collection("users").document(memberUID).getDocument()
            if let profile = try? doc?.data(as: UserProfile.self) {
                members.append(GroupMember(
                    id: profile.id, displayName: profile.displayName,
                    brainRotScore: profile.brainRotScore,
                    formattedScreenTime: profile.formattedScreenTime
                ))
            }
        }
        return members.sorted { $0.brainRotScore < $1.brainRotScore }
        #endif
    }

    func leaveGroup(groupID: String) async {
        #if targetEnvironment(simulator)
        groups.removeAll { $0.id == groupID }
        #else
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let query = db.collection("groups").whereField("memberUIDs", arrayContains: uid)
        let docs = try? await query.getDocuments()
        for doc in docs?.documents ?? [] where doc.documentID == groupID {
            try? await doc.reference.updateData([
                "memberUIDs": FieldValue.arrayRemove([uid])
            ])
        }
        fetchGroups()
        #endif
    }

    // MARK: - Listeners

    #if !targetEnvironment(simulator)
    private func listenForFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        friendsListener?.remove()
        friendsListener = db.collection("users").document(uid).collection("friends")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.friends = snapshot?.documents.compactMap {
                    try? $0.data(as: Friendship.self)
                } ?? []
            }
    }

    private func listenForIncomingRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        requestsListener?.remove()
        requestsListener = db.collection("friendRequests")
            .whereField("toUID", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.incomingRequests = snapshot?.documents.compactMap {
                    try? $0.data(as: FriendRequest.self)
                } ?? []
            }
    }
    #endif

    // MARK: - Simulator Mocks

    #if targetEnvironment(simulator)
    private func setupMockData() {
        isSignedIn = true
        currentUserProfile = UserProfile(
            id: "mock-uid-001", displayName: "You", username: "doomscroller99",
            brainRotScore: 72, totalScreenTimeSeconds: 9900,
            formattedScreenTime: "2h 45m", lastUpdated: .now, createdAt: .now
        )
        friends = [
            Friendship(id: "f1", displayName: "Alex", username: "alexscrolls",
                       brainRotScore: 45, totalScreenTimeSeconds: 5400,
                       formattedScreenTime: "1h 30m", lastUpdated: .now),
            Friendship(id: "f2", displayName: "Jordan", username: "jordanbrainrot",
                       brainRotScore: 88, totalScreenTimeSeconds: 14400,
                       formattedScreenTime: "4h 00m", lastUpdated: .now),
            Friendship(id: "f3", displayName: "Sam", username: "samtouchgrass",
                       brainRotScore: 15, totalScreenTimeSeconds: 1800,
                       formattedScreenTime: "30m", lastUpdated: .now),
        ]
        incomingRequests = [
            FriendRequest(id: "req1", fromUID: "u4", fromDisplayName: "Casey",
                          toUID: "mock-uid-001", toDisplayName: "You",
                          status: .pending, createdAt: .now)
        ]
        groups = [
            SocialGroup(id: "g1", name: "Brainrot Squad",
                        memberUIDs: ["mock-uid-001", "f1", "f2"],
                        createdBy: "mock-uid-001", createdAt: .now)
        ]
    }
    #endif
}
