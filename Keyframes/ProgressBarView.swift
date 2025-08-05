import SwiftUI

struct ProgressBarView: View {
    
    struct ProgressKeyframes {
        var progress: Double = 0.0
    }
    
    @State private var animationTrigger = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 60) {
                headerView
                progressBarWithLabel
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Progress Bar Animation")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Cubic + Linear keyframes with progress tracking")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
    }
    
    private var progressBarWithLabel: some View {
        VStack(spacing: 30) {
            percentageLabel
            progressBar
        }
        .onAppear {
            animationTrigger = true
        }
    }
    
    private var percentageLabel: some View {
        KeyframeAnimator(
            initialValue: ProgressKeyframes(),
            trigger: animationTrigger
        ) { keyframes in
            Text("\(Int(keyframes.progress * 100))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                CubicKeyframe(0.8, duration: 2.0)
                LinearKeyframe(1.0, duration: 3.0)
            }
        }
    }
    
    private var progressBar: some View {
        KeyframeAnimator(
            initialValue: ProgressKeyframes(),
            trigger: animationTrigger
        ) { keyframes in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 300, height: 30)
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 300 * keyframes.progress, height: 30)
            }
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                CubicKeyframe(0.8, duration: 2.0)
                LinearKeyframe(1.0, duration: 3.0)
            }
        }
    }
}

#Preview {
    ProgressBarView()
}
