import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4A90E2"), Color(hex: "5B9BD5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Price tag animation
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .rotation3DEffect(
                            .degrees(isAnimating ? 360 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                    
                    Image(systemName: "tag.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "4A90E2"))
                        .rotation3DEffect(
                            .degrees(isAnimating ? 360 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .opacity(showTitle ? 0 : 1)
                
                if showTitle {
                    VStack(spacing: 10) {
                        Text("Personal Service")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Price List")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showTitle = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }
}
