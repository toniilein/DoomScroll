import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    private var sortedFriends: [Friendship] {
        firebaseManager.friends.sorted { $0.brainRotScore < $1.brainRotScore }
    }

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            if firebaseManager.friends.isEmpty {
                VStack(spacing: 16) {
                    Text("\u{1F465}")
                        .font(.system(size: 60))
                    Text("No friends yet")
                        .font(.title2.bold())
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Text("Add friends to compare doomscroll scores")
                        .font(.body)
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(sortedFriends.enumerated()), id: \.element.id) { index, friend in
                            friendRow(friend: friend, rank: index + 1)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Friends")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func friendRow(friend: Friendship, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text(rankIcon(rank))
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.body.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(friend.brainRotScore)")
                    .font(.title3.bold())
                    .foregroundColor(BrainRotTheme.scoreColor(for: friend.brainRotScore))
                Text(friend.formattedScreenTime)
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rankIcon(_ rank: Int) -> String {
        switch rank {
        case 1: return "\u{1F947}"
        case 2: return "\u{1F948}"
        case 3: return "\u{1F949}"
        default: return "#\(rank)"
        }
    }
}
