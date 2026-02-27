import SwiftUI

struct SocialView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var showingAddFriend = false
    @State private var showingCreateGroup = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                Group {
                    if firebaseManager.isLoading {
                        ProgressView()
                            .tint(BrainRotTheme.neonPurple)
                    } else if !firebaseManager.isSignedIn {
                        signInPrompt
                    } else if firebaseManager.needsUsernameSetup {
                        UsernameSetupView()
                    } else {
                        socialContent
                    }
                }
            }
            .navigationTitle("Social")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if firebaseManager.isSignedIn && !firebaseManager.needsUsernameSetup {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingAddFriend = true
                            } label: {
                                Label("Add Friend", systemImage: "person.badge.plus")
                            }
                            Button {
                                showingCreateGroup = true
                            } label: {
                                Label("Create Group", systemImage: "person.3.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(BrainRotTheme.neonPink)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) { InviteFriendsView() }
            .sheet(isPresented: $showingCreateGroup) { CreateGroupView() }
            .task {
                if !firebaseManager.isSignedIn {
                    await firebaseManager.signInAnonymously()
                }
            }
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        VStack(spacing: 20) {
            Text("\u{1F465}")
                .font(.system(size: 60))
            Text("Connect with Friends")
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Sign in to compare doomscroll scores and create groups")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await firebaseManager.signInAnonymously() }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrainRotTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Main Social Content

    private var socialContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Your profile card
                if let profile = firebaseManager.currentUserProfile {
                    UserProfileCardView(
                        displayName: profile.displayName,
                        username: profile.username,
                        brainRotScore: profile.brainRotScore,
                        formattedScreenTime: profile.formattedScreenTime
                    )
                    .padding(.horizontal)
                }

                // Pending requests
                if !firebaseManager.incomingRequests.isEmpty {
                    requestsSection
                }

                // Friends
                friendsSection

                // Groups
                groupsSection
            }
            .padding(.top)
        }
    }

    // MARK: - Requests

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(BrainRotTheme.neonPink)
                Text("Friend Requests")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(firebaseManager.incomingRequests.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(BrainRotTheme.neonPink)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)

            ForEach(firebaseManager.incomingRequests) { request in
                requestRow(request)
            }
        }
    }

    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            Text(request.fromDisplayName)
                .font(.body.bold())
                .foregroundColor(BrainRotTheme.textPrimary)

            Spacer()

            Button {
                Task { await firebaseManager.acceptFriendRequest(request) }
            } label: {
                Text("Accept")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BrainRotTheme.neonGreen)
                    .clipShape(Capsule())
            }

            Button {
                Task { await firebaseManager.declineFriendRequest(request) }
            } label: {
                Text("Decline")
                    .font(.caption.bold())
                    .foregroundColor(BrainRotTheme.neonPink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BrainRotTheme.neonPink.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Friends

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Friends")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                if !firebaseManager.friends.isEmpty {
                    NavigationLink {
                        FriendListView()
                    } label: {
                        Text("See All")
                            .font(.caption.bold())
                            .foregroundColor(BrainRotTheme.neonPurple)
                    }
                }
            }
            .padding(.horizontal)

            if firebaseManager.friends.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No friends yet")
                            .font(.subheadline)
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Button {
                            showingAddFriend = true
                        } label: {
                            Text("Add Friends")
                                .font(.caption.bold())
                                .foregroundColor(BrainRotTheme.neonPurple)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(firebaseManager.friends.sorted(by: { $0.brainRotScore < $1.brainRotScore })) { friend in
                            friendCard(friend)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func friendCard(_ friend: Friendship) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(BrainRotTheme.scoreColor(for: friend.brainRotScore).opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Text("\(friend.brainRotScore)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.scoreColor(for: friend.brainRotScore))
            }

            Text(friend.displayName)
                .font(.caption.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
                .lineLimit(1)

            Text(friend.formattedScreenTime)
                .font(.caption2)
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Groups

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(BrainRotTheme.neonBlue)
                Text("Groups")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal)

            if firebaseManager.groups.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No groups yet")
                            .font(.subheadline)
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Button {
                            showingCreateGroup = true
                        } label: {
                            Text("Create Group")
                                .font(.caption.bold())
                                .foregroundColor(BrainRotTheme.neonBlue)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            } else {
                ForEach(firebaseManager.groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        groupCard(group)
                    }
                }
            }
        }
    }

    private func groupCard(_ group: SocialGroup) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundColor(BrainRotTheme.neonBlue)
                .frame(width: 44, height: 44)
                .background(BrainRotTheme.neonBlue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.body.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)
                Text("\(group.memberUIDs.count) members")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
