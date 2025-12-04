import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var progress: UserProgress
    
    @State private var showResetAlert = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        settingsSection(title: "Game Settings", icon: "gamecontroller.fill") {
                            VStack(spacing: 0) {
                                SettingsRow {
                                    HStack {
                                        Image(systemName: "number.circle.fill").foregroundColor(Color(hex: "4facfe"))
                                        Text("Questions per Quiz").foregroundColor(.white)
                                        Spacer()
                                        Picker("", selection: $settings.questionCount) {
                                            ForEach([5, 10, 15, 20], id: \.self) { Text("\($0)").tag($0) }
                                        }.pickerStyle(.menu).tint(Color(hex: "4facfe"))
                                    }
                                }
                                Divider().background(Color.white.opacity(0.1))
                                SettingsRow {
                                    HStack {
                                        Image(systemName: "speedometer").foregroundColor(Color(hex: "f5576c"))
                                        Text("Difficulty").foregroundColor(.white)
                                        Spacer()
                                        Picker("", selection: $settings.selectedDifficulty) {
                                            Text("All").tag(nil as QuizQuestion.Difficulty?)
                                            ForEach(QuizQuestion.Difficulty.allCases, id: \.self) { Text($0.rawValue).tag($0 as QuizQuestion.Difficulty?) }
                                        }.pickerStyle(.menu).tint(Color(hex: "f5576c"))
                                    }
                                }
                                Divider().background(Color.white.opacity(0.1))
                                SettingsRow {
                                    Toggle(isOn: $settings.timerEnabled) {
                                        HStack {
                                            Image(systemName: "clock.fill").foregroundColor(Color(hex: "43e97b"))
                                            Text("Timer").foregroundColor(.white)
                                        }
                                    }.tint(Color(hex: "43e97b"))
                                }
                                if settings.timerEnabled {
                                    Divider().background(Color.white.opacity(0.1))
                                    SettingsRow {
                                        HStack {
                                            Image(systemName: "timer").foregroundColor(Color(hex: "f093fb"))
                                            Text("Time per Question").foregroundColor(.white)
                                            Spacer()
                                            Picker("", selection: $settings.timePerQuestion) {
                                                ForEach([15, 20, 30, 45, 60], id: \.self) { Text("\($0)s").tag($0) }
                                            }.pickerStyle(.menu).tint(Color(hex: "f093fb"))
                                        }
                                    }
                                }
                            }
                        }.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        
                        settingsSection(title: "Experience", icon: "sparkles") {
                            VStack(spacing: 0) {
                                SettingsRow {
                                    Toggle(isOn: $settings.soundEnabled) {
                                        HStack {
                                            Image(systemName: "speaker.wave.2.fill").foregroundColor(Color(hex: "667eea"))
                                            Text("Sound Effects").foregroundColor(.white)
                                        }
                                    }.tint(Color(hex: "667eea"))
                                }
                                Divider().background(Color.white.opacity(0.1))
                                SettingsRow {
                                    Toggle(isOn: $settings.hapticEnabled) {
                                        HStack {
                                            Image(systemName: "hand.tap.fill").foregroundColor(Color(hex: "764ba2"))
                                            Text("Haptic Feedback").foregroundColor(.white)
                                        }
                                    }.tint(Color(hex: "764ba2"))
                                }
                                Divider().background(Color.white.opacity(0.1))
                                SettingsRow {
                                    Toggle(isOn: $settings.showExplanations) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill").foregroundColor(Color(hex: "ffd700"))
                                            Text("Show Explanations").foregroundColor(.white)
                                        }
                                    }.tint(Color(hex: "ffd700"))
                                }
                            }
                        }.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        
                        settingsSection(title: "Your Stats", icon: "chart.bar.fill") {
                            VStack(spacing: 16) {
                                HStack {
                                    StatInfoRow(label: "Total XP", value: "\(progress.totalScore)", icon: "star.fill", color: Color(hex: "ffd700"))
                                    Spacer()
                                    StatInfoRow(label: "Level", value: "\(progress.level)", icon: "chart.line.uptrend.xyaxis", color: Color(hex: "4facfe"))
                                }
                                Divider().background(Color.white.opacity(0.1))
                                HStack {
                                    StatInfoRow(label: "Questions", value: "\(progress.questionsAnswered)", icon: "questionmark.circle.fill", color: Color(hex: "43e97b"))
                                    Spacer()
                                    StatInfoRow(label: "Correct", value: "\(progress.correctAnswers)", icon: "checkmark.circle.fill", color: Color(hex: "667eea"))
                                }
                                Divider().background(Color.white.opacity(0.1))
                                HStack {
                                    StatInfoRow(label: "Accuracy", value: String(format: "%.1f%%", progress.accuracy), icon: "percent", color: Color(hex: "f093fb"))
                                    Spacer()
                                    StatInfoRow(label: "Best Streak", value: "\(progress.bestStreak)", icon: "flame.fill", color: Color(hex: "f5576c"))
                                }
                            }.padding(.vertical, 8)
                        }.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        
                        settingsSection(title: "Data", icon: "externaldrive.fill") {
                            VStack(spacing: 0) {
                                Button(action: { showResetAlert = true }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise").foregroundColor(Color(hex: "f5576c"))
                                        Text("Reset All Progress").foregroundColor(Color(hex: "f5576c"))
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
                                    }.padding(.horizontal, 16).padding(.vertical, 14)
                                }
                            }
                        }.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        
                        aboutSection.offset(y: animateContent ? 0 : 30).opacity(animateContent ? 1 : 0)
                        Spacer(minLength: 50)
                    }.padding(.horizontal, 20).padding(.top, 20)
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).foregroundColor(Color(hex: "4facfe"))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    progress.resetProgress()
                    if settings.hapticEnabled { HapticManager.shared.notification(.warning) }
                }
            } message: { Text("This will delete all your progress, achievements, and statistics. This action cannot be undone.") }
            .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { animateContent = true } }
        }
    }
    
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(title).font(.headline).foregroundColor(.white)
            }
            content().glassCard(cornerRadius: 16)
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                Image(systemName: "sparkles").font(.system(size: 35)).foregroundColor(.white)
            }
            VStack(spacing: 4) {
                Text("Quiz Cosmos").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Version 1.0.0").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Text("Explore the wonders of space through interactive quizzes. Learn about planets, stars, galaxies, and more!")
                .font(.subheadline).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center).padding(.horizontal, 20)
        }.padding(.vertical, 24).frame(maxWidth: .infinity).glassCard()
    }
}

struct SettingsRow<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.padding(.horizontal, 16).padding(.vertical, 14) }
}

struct StatInfoRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline).foregroundColor(.white)
                Text(label).font(.caption).foregroundColor(.white.opacity(0.5))
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsView().environmentObject(AppSettings()).environmentObject(UserProgress())
}
