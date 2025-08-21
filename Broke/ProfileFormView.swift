//
//  EditProfileView.swift
//  Broke
//
//  Created by Oz Tamir on 23/08/2024.
//

import SwiftUI
import SFSymbolsPicker
import FamilyControls

struct ProfileFormView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var profileName: String
    @State private var profileIcon: String
    @State private var showSymbolsPicker = false
    @State private var showAppSelection = false
    @State private var activitySelection: FamilyActivitySelection
    @State private var showDeleteConfirmation = false
    @FocusState private var isTextFieldFocused: Bool
    let profile: Profile?
    let canDelete: Bool
    let onDismiss: () -> Void
    let iconSize: CGFloat = 30
    
    init(profile: Profile? = nil, canDelete: Bool = false, profileManager: ProfileManager, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.canDelete = canDelete
        self.profileManager = profileManager
        self.onDismiss = onDismiss
        _profileName = State(initialValue: profile?.name ?? "")
        _profileIcon = State(initialValue: profile?.icon ?? profileManager.getInitialIcon())
        
        var selection = FamilyActivitySelection()
        selection.applicationTokens = profile?.appTokens ?? []
        selection.categoryTokens = profile?.categoryTokens ?? []
        _activitySelection = State(initialValue: selection)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    VStack(alignment: .leading) {
                        Text("Profile Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter profile name", text: $profileName)
                            .focused($isTextFieldFocused)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
                    
                    Button(action: { showSymbolsPicker = true }) {
                        HStack {
                            Image(systemName: profileIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                            Text("Select Icon")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }.padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Screen Time")) {
                    Button(action: { showAppSelection = true }) {
                        HStack {
                            Text("Choose Blocked Activities")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    HStack {
                        Image(systemName: "app.badge")
                        Text("Blocked Apps")
                        Spacer()
                        Text("\(activitySelection.applicationTokens.count)")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text("Blocked Categories")
                        Spacer()
                        Text("\(activitySelection.categoryTokens.count)")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Image(systemName: "safari")
                        Text("Blocked Sites")
                        Spacer()
                        Text("\(activitySelection.webDomainTokens.count)")
                            .fontWeight(.bold)
                    }
                }
                
                if profile != nil && canDelete {
                    Section {
                        Button(action: { showDeleteConfirmation = true }) {
                            Text("Delete Profile")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(profile == nil ? "Add Profile" : "Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel", action: onDismiss),
                trailing: Button("Save", action: handleSave)
                    .disabled(profileName.isEmpty)
                    .fontWeight(.bold)
                    .tint(.blue)
                
            )
            .sheet(isPresented: $showSymbolsPicker) {
                IconSelectionSheet(icons: profileManager.icons, selectedIcon: $profileIcon).interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationView {
                    FamilyActivityPicker(selection: $activitySelection)
                        .navigationBarItems(trailing: Button("Done") {
                            showAppSelection = false
                        }
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        )
                }.interactiveDismissDisabled(true)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Profile"),
                    message: Text("Are you sure you want to delete this profile?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let profile = profile {
                            profileManager.deleteProfile(withId: profile.id)
                        }
                        onDismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func handleSave() {
        if let existingProfile = profile {
            profileManager.updateProfile(
                id: existingProfile.id,
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                icon: profileIcon
            )
        } else {
            let newProfile = Profile(
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                icon: profileIcon
            )
            profileManager.addProfile(newProfile: newProfile)
        }
        onDismiss()
    }
}


struct IconSelectionSheet: View {
    let icons: [String]
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var pressedIcon: String? = nil
    
    let columns = [GridItem(.adaptive(minimum: 60), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                selectedIcon = icon
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                dismiss()
                            }
                        }){
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Select Icon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
