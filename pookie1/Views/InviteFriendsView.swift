import SwiftUI

struct InviteFriendsView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var sentRequests: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(BrainRotTheme.textSecondary)
                        TextField("Search by username", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(BrainRotTheme.textPrimary)
                    }
                    .padding()
                    .background(BrainRotTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    if isSearching {
                        ProgressView()
                            .tint(BrainRotTheme.neonPurple)
                            .padding()
                    }

                    // Results
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(searchResults) { user in
                                searchResultRow(user: user)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .background(BrainRotTheme.textSecondary)
                        .padding(.horizontal)

                    // Share link
                    ShareLink(item: "Check out DoomScroll - track your brainrot! \u{1F9E0}") {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share DoomScroll with friends")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrainRotTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Add Friends")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BrainRotTheme.neonPink)
                }
            }
            .onChange(of: searchText) { _, newValue in
                search(query: newValue)
            }
        }
    }

    private func searchResultRow(user: UserProfile) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.body.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            Text("\(user.brainRotScore)")
                .font(.headline)
                .foregroundColor(BrainRotTheme.scoreColor(for: user.brainRotScore))

            if sentRequests.contains(user.id) {
                Text("Sent")
                    .font(.caption.bold())
                    .foregroundColor(BrainRotTheme.neonGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BrainRotTheme.neonGreen.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Button {
                    Task {
                        await firebaseManager.sendFriendRequest(
                            toUID: user.id, toDisplayName: user.displayName
                        )
                        sentRequests.insert(user.id)
                    }
                } label: {
                    Text("Add")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(BrainRotTheme.neonPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func search(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        Task {
            searchResults = await firebaseManager.searchUsers(query: query)
            isSearching = false
        }
    }
}
