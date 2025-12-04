import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var settings: AppSettings
    
    let category: QuizQuestion.SpaceCategory?
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var score = 0
    @State private var streak = 0
    @State private var showExplanation = false
    @State private var quizCompleted = false
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer?
    @State private var animateQuestion = false
    @State private var showConfetti = false
    
    private var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var body: some View {
        ZStack {
            StarFieldView()
            
            if quizCompleted {
                QuizResultView(score: score, totalQuestions: questions.count, streak: streak, onDismiss: { dismiss() }, onPlayAgain: { resetQuiz() })
                    .transition(.opacity.combined(with: .scale))
                
                if showConfetti { ConfettiView() }
            } else if let question = currentQuestion {
                VStack(spacing: 0) {
                    quizHeader
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            progressSection
                            if settings.timerEnabled { timerView }
                            questionCard(question).offset(y: animateQuestion ? 0 : 50).opacity(animateQuestion ? 1 : 0)
                            answerOptions(question).offset(y: animateQuestion ? 0 : 50).opacity(animateQuestion ? 1 : 0)
                            if showExplanation && settings.showExplanations {
                                explanationView(question).transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    if showResult { nextButton.transition(.move(edge: .bottom).combined(with: .opacity)) }
                }
            } else {
                ProgressView().tint(.white).scaleEffect(1.5)
            }
        }
        .onAppear { loadQuestions(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }
    
    private var quizHeader: some View {
        HStack {
            Button(action: { if settings.hapticEnabled { HapticManager.shared.impact(.light) }; dismiss() }) {
                Image(systemName: "xmark").font(.title3).foregroundColor(.white.opacity(0.8)).padding(12)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(Color(hex: "ffd700"))
                Text("\(score)").font(.headline).foregroundColor(.white)
            }.padding(.horizontal, 16).padding(.vertical, 8).glassCard(cornerRadius: 20)
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "flame.fill").foregroundColor(Color(hex: "f5576c"))
                Text("\(streak)").font(.headline).foregroundColor(.white)
            }.padding(.horizontal, 16).padding(.vertical, 8).glassCard(cornerRadius: 20)
        }.padding(.horizontal, 20).padding(.top, 10)
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(currentIndex + 1) of \(questions.count)").font(.subheadline).foregroundColor(.white.opacity(0.7))
                Spacer()
                if let question = currentQuestion {
                    Text(question.difficulty.rawValue).font(.caption).fontWeight(.semibold).foregroundColor(question.difficulty.color)
                        .padding(.horizontal, 12).padding(.vertical, 4).background(Capsule().fill(question.difficulty.color.opacity(0.2)))
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                    Capsule().fill(LinearGradient(colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 6)
                        .animation(.spring(response: 0.5), value: currentIndex)
                }
            }.frame(height: 6)
        }
    }
    
    private var timerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill").foregroundColor(timeRemaining <= 10 ? Color(hex: "f5576c") : .white.opacity(0.7))
            Text("\(timeRemaining)s").font(.headline).fontWeight(.bold).foregroundColor(timeRemaining <= 10 ? Color(hex: "f5576c") : .white).monospacedDigit()
        }.padding(.horizontal, 20).padding(.vertical, 10).glassCard(cornerRadius: 20)
            .scaleEffect(timeRemaining <= 5 ? 1.1 : 1.0).animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timeRemaining <= 5)
    }
    
    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: question.category.icon).foregroundStyle(LinearGradient(colors: question.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(question.category.rawValue).font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.7))
            }
            Text(question.question).font(.title3).fontWeight(.semibold).foregroundColor(.white).multilineTextAlignment(.center).lineSpacing(4)
        }.padding(24).frame(maxWidth: .infinity).glassCard()
    }
    
    private func answerOptions(_ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                AnswerButton(text: option, index: index, isSelected: selectedAnswer == index,
                             isCorrect: showResult ? index == question.correctAnswer : nil,
                             isWrong: showResult && selectedAnswer == index && index != question.correctAnswer,
                             action: { selectAnswer(index, for: question) }).disabled(showResult)
            }
        }
    }
    
    private func explanationView(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundColor(Color(hex: "ffd700"))
                Text("Did you know?").font(.headline).foregroundColor(.white)
            }
            Text(question.explanation).font(.subheadline).foregroundColor(.white.opacity(0.8)).lineSpacing(4)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).glassCard()
    }
    
    private var nextButton: some View {
        Button(action: nextQuestion) {
            HStack {
                Text(currentIndex < questions.count - 1 ? "Next Question" : "See Results").fontWeight(.bold)
                Image(systemName: "arrow.right")
            }.frame(maxWidth: .infinity).padding(.vertical, 18)
        }.buttonStyle(CosmicButtonStyle(gradient: isCorrect ? [Color(hex: "43e97b"), Color(hex: "38f9d7")] : [Color(hex: "667eea"), Color(hex: "764ba2")]))
            .padding(.horizontal, 20).padding(.bottom, 30)
    }
    
    private func loadQuestions() {
        questions = QuestionBank.getQuestions(count: settings.questionCount, difficulty: settings.selectedDifficulty, category: category)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animateQuestion = true }
    }
    
    private func startTimer() {
        guard settings.timerEnabled else { return }
        timeRemaining = settings.timePerQuestion
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 && !showResult {
                timeRemaining -= 1
                if timeRemaining <= 5 && timeRemaining > 0 && settings.soundEnabled { SoundManager.shared.playCountdown() }
            } else if timeRemaining == 0 && !showResult {
                if let question = currentQuestion { selectAnswer(-1, for: question) }
            }
        }
    }
    
    private func selectAnswer(_ index: Int, for question: QuizQuestion) {
        guard !showResult else { return }
        selectedAnswer = index
        isCorrect = index == question.correctAnswer
        
        if settings.soundEnabled { isCorrect ? SoundManager.shared.playCorrect() : SoundManager.shared.playWrong() }
        if settings.hapticEnabled { isCorrect ? HapticManager.shared.notification(.success) : HapticManager.shared.notification(.error) }
        
        if isCorrect {
            score += question.difficulty.points
            streak += 1
            progress.correctAnswers += 1
            progress.currentStreak += 1
            if progress.currentStreak > progress.bestStreak { progress.bestStreak = progress.currentStreak }
        } else {
            streak = 0
            progress.currentStreak = 0
        }
        
        progress.questionsAnswered += 1
        progress.totalScore += isCorrect ? question.difficulty.points : 0
        let categoryKey = question.category.rawValue
        progress.categoryProgress[categoryKey] = (progress.categoryProgress[categoryKey] ?? 0) + (isCorrect ? 1 : 0)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showResult = true
            if settings.showExplanations { showExplanation = true }
        }
        timer?.invalidate()
        checkAchievements()
    }
    
    private func nextQuestion() {
        if settings.soundEnabled { SoundManager.shared.playSwipe() }
        if settings.hapticEnabled { HapticManager.shared.selection() }
        
        if currentIndex < questions.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) { animateQuestion = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex += 1; selectedAnswer = nil; showResult = false; showExplanation = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animateQuestion = true }
                startTimer()
            }
        } else {
            progress.lastPlayedDate = Date()
            progress.dailyQuizCompleted = true
            if settings.soundEnabled { SoundManager.shared.playSuccess() }
            if settings.hapticEnabled { HapticManager.shared.notification(.success) }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { quizCompleted = true; showConfetti = true }
        }
    }
    
    private func resetQuiz() {
        currentIndex = 0; selectedAnswer = nil; showResult = false; showExplanation = false
        score = 0; streak = 0; quizCompleted = false; showConfetti = false; animateQuestion = false
        loadQuestions(); startTimer()
    }
    
    private func checkAchievements() {
        for achievement in Achievement.all {
            if progress.achievements.contains(achievement.id) { continue }
            var unlocked = false
            switch achievement.type {
            case .questions: unlocked = progress.questionsAnswered >= achievement.requirement
            case .streak: unlocked = progress.bestStreak >= achievement.requirement
            case .score: unlocked = progress.totalScore >= achievement.requirement
            case .accuracy: unlocked = progress.accuracy >= Double(achievement.requirement)
            case .category: break
            }
            if unlocked {
                progress.achievements.insert(achievement.id)
                if settings.soundEnabled { SoundManager.shared.playAchievement() }
                if settings.hapticEnabled { HapticManager.shared.notification(.success) }
            }
        }
    }
}

struct AnswerButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let isWrong: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        if let correct = isCorrect { if correct && (isSelected || index == 0) { return Color(hex: "43e97b").opacity(0.3) } }
        if isWrong { return Color(hex: "f5576c").opacity(0.3) }
        if isSelected { return Color(hex: "667eea").opacity(0.3) }
        return Color.white.opacity(0.08)
    }
    
    private var borderColor: Color {
        if let correct = isCorrect, correct { return Color(hex: "43e97b") }
        if isWrong { return Color(hex: "f5576c") }
        if isSelected { return Color(hex: "667eea") }
        return Color.white.opacity(0.2)
    }
    
    private var optionLetter: String { ["A", "B", "C", "D"][index] }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(isCorrect == true ? Color(hex: "43e97b") : isWrong ? Color(hex: "f5576c") : isSelected ? Color(hex: "667eea") : Color.white.opacity(0.1)).frame(width: 36, height: 36)
                    if isCorrect == true {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    } else if isWrong {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    } else {
                        Text(optionLetter).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    }
                }
                Text(text).font(.body).fontWeight(.medium).foregroundColor(.white).multilineTextAlignment(.leading)
                Spacer()
            }.padding(16).background(RoundedRectangle(cornerRadius: 16).fill(backgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 2))
        }.scaleEffect(isSelected && isCorrect == nil ? 1.02 : 1).animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct QuizResultView: View {
    let score: Int
    let totalQuestions: Int
    let streak: Int
    let onDismiss: () -> Void
    let onPlayAgain: () -> Void
    
    @State private var animateElements = false
    
    private var percentage: Double { Double(score) / Double(totalQuestions * 20) * 100 }
    
    private var resultMessage: (title: String, subtitle: String, icon: String) {
        switch percentage {
        case 90...100: return ("Cosmic Genius!", "You're a true space expert!", "crown.fill")
        case 70..<90: return ("Great Job!", "You really know your space facts!", "star.fill")
        case 50..<70: return ("Good Effort!", "Keep exploring the cosmos!", "hand.thumbsup.fill")
        default: return ("Keep Learning!", "The universe has more to teach you!", "book.fill")
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 120, height: 120).scaleEffect(animateElements ? 1 : 0.5).opacity(animateElements ? 1 : 0)
                Image(systemName: resultMessage.icon).font(.system(size: 50)).foregroundColor(.white).scaleEffect(animateElements ? 1 : 0)
            }
            VStack(spacing: 12) {
                Text(resultMessage.title).font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(hex: "e0e7ff")], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(resultMessage.subtitle).font(.title3).foregroundColor(.white.opacity(0.7))
            }.offset(y: animateElements ? 0 : 30).opacity(animateElements ? 1 : 0)
            HStack(spacing: 24) {
                ResultStatView(icon: "star.fill", value: "\(score)", label: "Points", color: Color(hex: "ffd700"))
                ResultStatView(icon: "checkmark.circle.fill", value: "\(totalQuestions)", label: "Questions", color: Color(hex: "43e97b"))
                ResultStatView(icon: "flame.fill", value: "\(streak)", label: "Best Streak", color: Color(hex: "f5576c"))
            }.offset(y: animateElements ? 0 : 30).opacity(animateElements ? 1 : 0)
            Spacer()
            VStack(spacing: 12) {
                Button(action: onPlayAgain) {
                    HStack { Image(systemName: "arrow.counterclockwise"); Text("Play Again") }.frame(maxWidth: .infinity).padding(.vertical, 18)
                }.buttonStyle(CosmicButtonStyle())
                Button(action: onDismiss) { Text("Back to Dashboard").font(.headline).foregroundColor(.white.opacity(0.8)).padding(.vertical, 12) }
            }.padding(.horizontal, 40).offset(y: animateElements ? 0 : 50).opacity(animateElements ? 1 : 0)
            Spacer()
        }.padding(.horizontal, 20).onAppear { withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) { animateElements = true } }
    }
}

struct ResultStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
        }.frame(maxWidth: .infinity).padding(.vertical, 20).glassCard(cornerRadius: 16)
    }
}

#Preview {
    QuizView(category: nil).environmentObject(UserProgress()).environmentObject(AppSettings())
}
