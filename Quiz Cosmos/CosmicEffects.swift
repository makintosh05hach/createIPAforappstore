import SwiftUI

struct StarFieldView: View {
    @State private var stars: [Star] = []
    @State private var animate = false
    
    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var twinkleSpeed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0a0a1a"),
                        Color(hex: "0d0d2b"),
                        Color(hex: "1a1a3e"),
                        Color(hex: "0d0d2b"),
                        Color(hex: "0a0a1a")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "7b2cbf").opacity(0.3),
                                Color(hex: "5a189a").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(x: 100, y: 150)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "3c096c").opacity(0.2),
                                Color(hex: "240046").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(x: 150, y: 300)
                    .blur(radius: 50)
                
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .opacity(animate ? star.opacity : star.opacity * 0.3)
                        .animation(
                            Animation.easeInOut(duration: star.twinkleSpeed)
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: animate
                        )
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
                animate = true
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars(in size: CGSize) {
        stars = (0..<150).map { _ in
            Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.4...1.0),
                twinkleSpeed: Double.random(in: 0.5...2.0)
            )
        }
    }
}


struct CosmicButtonStyle: ButtonStyle {
    let gradient: [Color]
    
    init(gradient: [Color] = [Color(hex: "667eea"), Color(hex: "764ba2")]) {
        self.gradient = gradient
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .shadow(color: gradient.first?.opacity(0.5) ?? .purple.opacity(0.5), radius: configuration.isPressed ? 5 : 15, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.08))
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

struct PulsingView: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.8)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingView())
    }
}

struct OrbitingView: View {
    let icon: String
    let color: Color
    let orbitRadius: CGFloat
    let duration: Double
    let delay: Double
    
    @State private var angle: Double = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(color)
            .offset(
                x: orbitRadius * cos(angle * .pi / 180),
                y: orbitRadius * sin(angle * .pi / 180) * 0.3
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    angle = 360
                }
            }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let size: CGFloat
        var rotation: Double
        var velocity: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 1.5)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
                animateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [
            Color(hex: "f093fb"),
            Color(hex: "f5576c"),
            Color(hex: "4facfe"),
            Color(hex: "43e97b"),
            Color(hex: "fa709a"),
            Color(hex: "fee140")
        ]
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                velocity: CGFloat.random(in: 3...6)
            )
        }
    }
    
    private func animateConfetti(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                particles[i].y += particles[i].velocity
                particles[i].rotation += 5
                particles[i].x += CGFloat.random(in: -1...1)
                
                if particles[i].y > size.height + 50 {
                    timer.invalidate()
                }
            }
        }
    }
}

struct RingProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: [Color]
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: gradient + [gradient.first!],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1, dampingFraction: 0.8), value: progress)
        }
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
