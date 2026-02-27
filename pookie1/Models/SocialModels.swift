import Foundation

// MARK: - User Profile
// Firestore: users/{uid}
struct UserProfile: Codable, Identifiable {
    var id: String
    var displayName: String
    var username: String
    var brainRotScore: Int
    var totalScreenTimeSeconds: TimeInterval
    var formattedScreenTime: String
    var lastUpdated: Date
    var createdAt: Date
}

// MARK: - Friend Request
// Firestore: friendRequests/{autoID}
struct FriendRequest: Codable, Identifiable {
    var id: String
    var fromUID: String
    var fromDisplayName: String
    var toUID: String
    var toDisplayName: String
    var status: Status
    var createdAt: Date

    enum Status: String, Codable {
        case pending, accepted, declined
    }
}

// MARK: - Friendship (denormalized)
// Firestore: users/{uid}/friends/{friendUID}
struct Friendship: Codable, Identifiable {
    var id: String
    var displayName: String
    var username: String
    var brainRotScore: Int
    var totalScreenTimeSeconds: TimeInterval
    var formattedScreenTime: String
    var lastUpdated: Date
}

// MARK: - Group
// Firestore: groups/{groupID}
struct SocialGroup: Codable, Identifiable {
    var id: String
    var name: String
    var memberUIDs: [String]
    var createdBy: String
    var createdAt: Date
}

// MARK: - Group Member (for leaderboard)
struct GroupMember: Codable, Identifiable {
    var id: String
    var displayName: String
    var brainRotScore: Int
    var formattedScreenTime: String
}
