import SwiftUI
import ContactsUI

struct NewTripView: View {
    
    @State private var tripName: String = ""
    @State private var newMemberName: String = ""
    @State private var members: [String] = []
    
    @State private var showContactPicker = false
    @State private var goToChat = false   // For navigation
    
    let cardColor = Color(#colorLiteral(red: 0.10, green: 0.15, blue: 0.13, alpha: 1))
    let accentGreen = Color(#colorLiteral(red: 0.40, green: 0.80, blue: 0.65, alpha: 1))
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)),
                    Color(#colorLiteral(red: 0.07, green: 0.12, blue: 0.11, alpha: 1))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // TITLE
                    Text("Create a New Trip ✈️")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    // TRIP NAME FIELD
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Name")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("e.g., 🇹🇷 Turkey Trip", text: $tripName)
                            .padding()
                            .background(cardColor)
                            .cornerRadius(14)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    
                    // MEMBERS SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Members")
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Add member entry
                        HStack {
                            TextField("Add member (Ali, Mom, 🧑🏻‍💻)", text: $newMemberName)
                                .padding()
                                .background(cardColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            
                            Button {
                                if !newMemberName.isEmpty {
                                    members.append(newMemberName)
                                    newMemberName = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(accentGreen)
                            }
                        }
                        
                        // CONTACT PICKER BUTTON
                        Button {
                            showContactPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Add from Contacts")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(accentGreen)
                        }
                    }
                    
                    // MEMBERS LIST
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(members, id: \.self) { member in
                            HStack {
                                Text(member)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                Button {
                                    members.removeAll { $0 == member }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            .padding()
                            .background(cardColor.opacity(0.9))
                            .cornerRadius(12)
                        }
                    }
                    
                    // CREATE TRIP BUTTON — CLEAN + WORKING
                    Button {
                        goToChat = true
                    } label: {
                        Text("Create Trip")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.02, green: 0.05, blue: 0.04, alpha: 1)))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGreen)
                            .cornerRadius(16)
                            .shadow(color: accentGreen.opacity(0.3), radius: 18, y: 5)
                    }
                    .disabled(tripName.isEmpty || members.isEmpty)
                    .opacity(tripName.isEmpty || members.isEmpty ? 0.4 : 1)
                    .padding(.top, 10)
                    
                    // Navigation to chat screen
                    NavigationLink(
                        destination: TripChatView(tripName: tripName, members: members),
                        isActive: $goToChat
                    ) { EmptyView() }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("New Trip")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { contactName in
                members.append(contactName)
            }
        }
    }
}
