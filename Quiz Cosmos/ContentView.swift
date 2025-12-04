import SwiftUI

struct ContentView: View {
    @StateObject private var progress = UserProgress()
    @StateObject private var settings = AppSettings()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else {
                DashboardView()
                    .environmentObject(progress)
                    .environmentObject(settings)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashScreen: View {
    @State private var animateLogo = false
    @State private var animateText = false
    @State private var animateRings = false
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            StarFieldView()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "667eea").opacity(0.3 - Double(index) * 0.1),
                                        Color(hex: "764ba2").opacity(0.2 - Double(index) * 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 160 + CGFloat(index * 40), height: 160 + CGFloat(index * 40))
                            .scaleEffect(animateRings ? 1 : 0.5)
                            .opacity(animateRings ? 1 : 0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.15),
                                value: animateRings
                            )
                    }
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "667eea").opacity(0.5),
                                        Color(hex: "764ba2").opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "818cf8"),
                                        Color(hex: "667eea"),
                                        Color(hex: "4f46e5")
                                    ],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Ellipse()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 150, height: 35)
                            .rotationEffect(.degrees(-20))
                        
                        Image(systemName: "sparkle")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .offset(x: 35, y: -35)
                            .opacity(animateLogo ? 1 : 0)
                            .scaleEffect(animateLogo ? 1 : 0)
                    }
                    .scaleEffect(animateLogo ? 1 : 0.3)
                    .rotationEffect(.degrees(animateLogo ? 0 : -30))
                }
                
                VStack(spacing: 12) {
                    Text("Quiz Cosmos")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "c7d2fe")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(y: animateText ? 0 : 30)
                        .opacity(animateText ? 1 : 0)
                    
                    Text("Explore the Universe")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                        .offset(y: animateText ? 0 : 20)
                        .opacity(animateText ? 1 : 0)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateText ? 1 : 0.5)
                            .opacity(animateText ? 1 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animateText
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateLogo = true
                animateRings = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animateText = true
            }
        }
    }
}

#Preview {
    ContentView()
}
