import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progress: UserProgress
    
    @State private var animateContent = false
    @State private var selectedTab = 0
    
    private var unlockedCount: Int { Achievement.all.filter { progress.achievements.contains($0.id) }.count }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerStats.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        tabSelector.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        if selectedTab == 0 { achievementsList } else { leaderboardView }
                        Spacer(minLength: 50)
                    }.padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle("Achievements").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).foregroundColor(Color(hex: "4facfe"))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { animateContent = true } }
        }
    }
    
    private var headerStats: some View {
        VStack(spacing: 20) {
            ZStack {
                RingProgressView(progress: Double(unlockedCount) / Double(Achievement.all.count), lineWidth: 8,
                                 gradient: [Color(hex: "ffd700"), Color(hex: "ffaa00"), Color(hex: "ff8c00")]).frame(width: 120, height: 120)
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill").font(.system(size: 30))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "ffd700"), Color(hex: "ffaa00")], startPoint: .top, endPoint: .bottom))
                    Text("\(unlockedCount)/\(Achievement.all.count)").font(.caption).fontWeight(.bold).foregroundColor(.white)
                }
            }
            VStack(spacing: 4) {
                Text("Achievement Hunter").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("\(Int(Double(unlockedCount) / Double(Achievement.all.count) * 100))% Complete").font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
        }.padding(.vertical, 24).frame(maxWidth: .infinity).glassCard()
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Achievements", icon: "trophy.fill", isSelected: selectedTab == 0) { withAnimation(.spring(response: 0.3)) { selectedTab = 0 } }
            TabButton(title: "Leaderboard", icon: "chart.bar.fill", isSelected: selectedTab == 1) { withAnimation(.spring(response: 0.3)) { selectedTab = 1 } }
        }.padding(4).glassCard(cornerRadius: 16)
    }
    
    private var achievementsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(Achievement.all.enumerated()), id: \.element.id) { index, achievement in
                AchievementCard(achievement: achievement, isUnlocked: progress.achievements.contains(achievement.id), progress: getProgressForAchievement(achievement))
                    .offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateContent)
            }
        }
    }
    
    private var leaderboardView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: "4facfe").opacity(0.3), Color.clear], center: .center, startRadius: 0, endRadius: 80)).frame(width: 160, height: 160)
                    Image(systemName: "globe.americas.fill").font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(spacing: 12) {
                    Text("Global Leaderboards").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Coming Soon!").font(.title3).fontWeight(.semibold)
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "f093fb"), Color(hex: "f5576c")], startPoint: .leading, endPoint: .trailing))
                    Text("Compete with space enthusiasts from around the world. Track your ranking and climb to the top!")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center).padding(.horizontal, 20)
                }
                VStack(spacing: 12) {
                    FeaturePreviewRow(icon: "chart.line.uptrend.xyaxis", text: "Weekly & Monthly Rankings")
                    FeaturePreviewRow(icon: "person.3.fill", text: "Friend Challenges")
                    FeaturePreviewRow(icon: "rosette", text: "Seasonal Competitions")
                }.padding(.top, 8)
            }.padding(.vertical, 32).frame(maxWidth: .infinity).glassCard().offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
        }
    }
    
    private func getProgressForAchievement(_ achievement: Achievement) -> Double {
        switch achievement.type {
        case .questions: return min(1.0, Double(progress.questionsAnswered) / Double(achievement.requirement))
        case .streak: return min(1.0, Double(progress.bestStreak) / Double(achievement.requirement))
        case .score: return min(1.0, Double(progress.totalScore) / Double(achievement.requirement))
        case .accuracy: return min(1.0, progress.accuracy / Double(achievement.requirement))
        case .category: return 0
        }
    }
}

struct FeaturePreviewRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.body).foregroundColor(Color(hex: "4facfe")).frame(width: 24)
            Text(text).font(.subheadline).foregroundColor(.white.opacity(0.8))
            Spacer()
            Image(systemName: "lock.fill").font(.caption).foregroundColor(.white.opacity(0.3))
        }.padding(.horizontal, 20)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.subheadline)
                Text(title).font(.subheadline).fontWeight(.medium)
            }.foregroundColor(isSelected ? .white : .white.opacity(0.5)).padding(.vertical, 10).padding(.horizontal, 16).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.white.opacity(0.15) : Color.clear))
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(isUnlocked ? LinearGradient(colors: [Color(hex: "ffd700"), Color(hex: "ffaa00")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 50, height: 50)
                Image(systemName: achievement.icon).font(.title3).foregroundColor(isUnlocked ? .white : .white.opacity(0.3))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title).font(.headline).foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                Text(achievement.description).font(.caption).foregroundColor(.white.opacity(0.5))
                if !isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                            Capsule().fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }.frame(height: 4).padding(.top, 4)
                }
            }
            Spacer()
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(Color(hex: "43e97b"))
            } else {
                Text("\(Int(progress * 100))%").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.5))
            }
        }.padding(16).glassCard(cornerRadius: 16).opacity(isUnlocked ? 1 : 0.7)
    }
}

#Preview {
    AchievementsView().environmentObject(UserProgress())
}
