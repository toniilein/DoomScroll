import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedFriendIDs: Set<String> = []
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Group name
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(BrainRotTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .padding(.horizontal)

                    // Friends selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Friends")
                            .font(.headline)
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .padding(.horizontal)

                        if firebaseManager.friends.isEmpty {
                            Text("Add some friends first to create a group")
                                .font(.subheadline)
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(firebaseManager.friends) { friend in
                                friendSelectRow(friend: friend)
                            }
                        }
                    }

                    Spacer()

                    // Create button
                    Button {
                        create()
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Create Group")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(canCreate ? BrainRotTheme.accentGradient : LinearGradient(
                        colors: [Color.gray], startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(!canCreate || isCreating)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("New Group")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BrainRotTheme.neonPink)
                }
            }
        }
    }

    private var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedFriendIDs.isEmpty
    }

    private func friendSelectRow(friend: Friendship) -> some View {
        Button {
            if selectedFriendIDs.contains(friend.id) {
                selectedFriendIDs.remove(friend.id)
            } else {
                selectedFriendIDs.insert(friend.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFriendIDs.contains(friend.id) ? BrainRotTheme.neonGreen : BrainRotTheme.textSecondary)
                    .font(.title3)

                Text(friend.displayName)
                    .font(.body)
                    .foregroundColor(BrainRotTheme.textPrimary)

                Spacer()

                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding()
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func create() {
        isCreating = true
        Task {
            await firebaseManager.createGroup(
                name: groupName.trimmingCharacters(in: .whitespaces),
                memberUIDs: Array(selectedFriendIDs)
            )
            dismiss()
        }
    }
}
