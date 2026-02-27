import SwiftUI

struct GroupDetailView: View {
    let group: SocialGroup
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var members: [GroupMember] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Group header
                    VStack(spacing: 4) {
                        Text("\(group.memberUIDs.count) members")
                            .font(.subheadline)
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }
                    .padding(.top)

                    if isLoading {
                        ProgressView()
                            .tint(BrainRotTheme.neonPurple)
                            .padding(40)
                    } else {
                        // Leaderboard
                        VStack(spacing: 8) {
                            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                                leaderboardRow(member: member, rank: index + 1)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)

                    Button {
                        Task {
                            await firebaseManager.leaveGroup(groupID: group.id)
                        }
                    } label: {
                        Text("Leave Group")
                            .font(.subheadline.bold())
                            .foregroundColor(BrainRotTheme.neonPink)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(BrainRotTheme.neonPink.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(group.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            members = await firebaseManager.fetchGroupMembers(group: group)
            isLoading = false
        }
    }

    private func leaderboardRow(member: GroupMember, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text(rankDisplay(rank))
                .font(.title3)
                .frame(width: 36)

            Text(member.displayName)
                .font(.body.bold())
                .foregroundColor(BrainRotTheme.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.brainRotScore)")
                    .font(.title3.bold())
                    .foregroundColor(BrainRotTheme.scoreColor(for: member.brainRotScore))
                Text(member.formattedScreenTime)
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding()
        .background(rank <= 3 ? rankColor(rank).opacity(0.08) : BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rank <= 3 ? rankColor(rank).opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func rankDisplay(_ rank: Int) -> String {
        switch rank {
        case 1: return "\u{1F947}"
        case 2: return "\u{1F948}"
        case 3: return "\u{1F949}"
        default: return "#\(rank)"
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return BrainRotTheme.neonGreen
        case 2: return BrainRotTheme.neonBlue
        case 3: return BrainRotTheme.neonPurple
        default: return BrainRotTheme.textSecondary
        }
    }
}
