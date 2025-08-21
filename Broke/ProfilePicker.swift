//
//  ProfilePicker.swift
//  Broke
//
//  Created by Oz Tamir on 23/08/2024.
//

import SwiftUI
import FamilyControls

struct ProfilesPicker: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showAddProfileView = false
    @State private var editingProfile: Profile?
    
    var body: some View {
        VStack {HStack {
            Text("Profiles")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                showAddProfileView = true
            }) {
                Image(systemName: "plus")
                    .font(.headline)
            }
        }
        .padding(.horizontal)
        .padding(.top)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                    ForEach(profileManager.profiles) { profile in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                if (profileManager.currentProfileId == profile.id) {
                                    editingProfile = profile
                                }
                                else
                                {
                                    profileManager.setCurrentProfile(id: profile.id)
                                }
                            }
                        }) {
                            ProfileCell(profile: profile, isSelected: profile.id == profileManager.currentProfileId)
                        }
                        .onLongPressGesture {
                            editingProfile = profile
                        }
                        
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
        }
        .background(Color("ProfileSectionBackground"))
        .sheet(item: $editingProfile) { profile in
            ProfileFormView(profile: profile, canDelete: profileManager.profiles.count > 1, profileManager: profileManager) {
                editingProfile = nil
            }.interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showAddProfileView) {
            ProfileFormView(profileManager: profileManager) {
                showAddProfileView = false
            }.interactiveDismissDisabled(true)
        }
    }
}

struct ProfileCellBase: View {
    let name: String
    let icon: String
    let appsBlocked: Int?
    let categoriesBlocked: Int?
    let isSelected: Bool
    var isDashed: Bool = false
    var hasDivider: Bool = true
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(width: 90, height: 90)
        .padding(2)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.blue : (isDashed ? Color.secondary : Color.clear),
                    style: StrokeStyle(lineWidth: 2, dash: isDashed ? [5] : [])
                )
        )
    }
}

struct ProfileCell: View {
    let profile: Profile
    let isSelected: Bool
    
    var body: some View {
        ProfileCellBase(
            name: profile.name,
            icon: profile.icon,
            appsBlocked: profile.appTokens.count,
            categoriesBlocked: profile.categoryTokens.count,
            isSelected: isSelected
        )
    }
}
