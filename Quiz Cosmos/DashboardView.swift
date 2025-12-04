import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var settings: AppSettings
    
    @State private var showQuiz = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showCategoryPicker = false
    @State private var selectedCategory: QuizQuestion.SpaceCategory?
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            StarFieldView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar
                    
                    headerSection
                    
                    levelProgressCard
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                    
                    statsGrid
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                    
                    playSection
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                    
                    categoriesSection
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                    
                    dailyChallengeCard
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(category: selectedCategory)
                .environmentObject(progress)
                .environmentObject(settings)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(progress)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(progress)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { showAchievements = true }) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "ffd700"), Color(hex: "ffaa00")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quiz Cosmos")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "e0e7ff")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Explore the Universe")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 90, height: 25)
                        .rotationEffect(.degrees(-20))
                }
                .pulsing()
            }
        }
    }
    
    private var levelProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(progress.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(progress.totalScore) XP")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ZStack {
                    RingProgressView(
                        progress: progress.levelProgress,
                        lineWidth: 8,
                        gradient: [Color(hex: "667eea"), Color(hex: "764ba2"), Color(hex: "f093fb")]
                    )
                    .frame(width: 70, height: 70)
                    
                    Text("\(Int(progress.levelProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress.levelProgress, height: 8)
                        .animation(.spring(response: 0.8), value: progress.levelProgress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(500 - (progress.totalScore % 500)) XP to Level \(progress.level + 1)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(icon: "checkmark.circle.fill", value: "\(progress.correctAnswers)", label: "Correct", color: Color(hex: "43e97b"))
            StatCard(icon: "flame.fill", value: "\(progress.bestStreak)", label: "Best Streak", color: Color(hex: "f5576c"))
            StatCard(icon: "percent", value: String(format: "%.0f%%", progress.accuracy), label: "Accuracy", color: Color(hex: "4facfe"))
        }
    }
    
    private var playSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                selectedCategory = nil
                if settings.soundEnabled { SoundManager.shared.playButtonPress() }
                if settings.hapticEnabled { HapticManager.shared.impact(.medium) }
                showQuiz = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.title2)
                    Text("Start Quiz").font(.title3).fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(CosmicButtonStyle(gradient: [Color(hex: "667eea"), Color(hex: "764ba2")]))
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories").font(.title3).fontWeight(.bold).foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuizQuestion.SpaceCategory.allCases, id: \.self) { category in
                    CategoryCard(category: category) {
                        selectedCategory = category
                        if settings.soundEnabled { SoundManager.shared.playTap() }
                        if settings.hapticEnabled { HapticManager.shared.selection() }
                        showQuiz = true
                    }
                }
            }
        }
    }
    
    private var dailyChallengeCard: some View {
        Button(action: {
            if !progress.dailyQuizCompleted {
                selectedCategory = nil
                if settings.soundEnabled { SoundManager.shared.playButtonPress() }
                if settings.hapticEnabled { HapticManager.shared.impact(.medium) }
                showQuiz = true
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "f093fb"), Color(hex: "f5576c")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: progress.dailyQuizCompleted ? "checkmark" : "calendar")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Challenge").font(.headline).foregroundColor(.white)
                    Text(progress.dailyQuizCompleted ? "Completed! Come back tomorrow" : "Complete for bonus XP!")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if !progress.dailyQuizCompleted {
                    Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(16)
            .glassCard()
        }
        .disabled(progress.dailyQuizCompleted)
        .opacity(progress.dailyQuizCompleted ? 0.6 : 1)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 16)
    }
}

struct CategoryCard: View {
    let category: QuizQuestion.SpaceCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.icon).font(.title3).foregroundColor(.white)
                }
                
                Text(category.rawValue).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCard(cornerRadius: 16)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(UserProgress())
        .environmentObject(AppSettings())
}
