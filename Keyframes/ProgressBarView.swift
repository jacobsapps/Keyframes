import SwiftUI

struct ProgressBarView: View {
    
    struct ProgressKeyframes {
        var progress: Double = 0.0
    }
    
    @State private var animationTrigger = false
    @State private var currentProgress: Double = 0.0
    @State private var animationStartTime: Date = Date()
    
    private var progressTimeline: KeyframeTimeline<ProgressKeyframes> {
        KeyframeTimeline(initialValue: ProgressKeyframes()) {
            KeyframeTrack(\.progress) {
                CubicKeyframe(0.8, duration: 2.0)
                LinearKeyframe(1.0, duration: 3.0)
            }
        }
    }
    
    var body: some View {
        progressBarWithLabel
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(.black)
            .ignoresSafeArea(.all)
    }
    
    private var progressBarWithLabel: some View {
        VStack(spacing: 30) {
            percentageLabel
            progressBar
            resetButton
        }
        .onAppear {
            animationTrigger = true
            animationStartTime = Date()
        }
    }
    
    private var percentageLabel: some View {
        Text("\(Int(currentProgress * 100))%")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
    
    private var progressBar: some View {
        TimelineView(.animation) { context in
            // Calculate animation progress (0 to 1)
            let animationDuration = 5.0 // Total duration of our keyframe animation
            let elapsedTime = animationTrigger ? context.date.timeIntervalSince(animationStartTime) : 0
            let animationProgress = min(elapsedTime / animationDuration, 1.0)
            
            // Use value(progress:) API to get the interpolated keyframe value
            let keyframeValue = progressTimeline.value(progress: animationProgress)
            
            // Derive hue from the keyframe progress value (red to green)
            let hue = keyframeValue.progress * 120 // 0 to 120 degrees
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 300, height: 30)
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.0, saturation: 0.8, brightness: 0.8),
                                Color(hue: hue / 360, saturation: 0.8, brightness: 0.8),
                                Color(hue: hue / 360, saturation: 0.9, brightness: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 300 * keyframeValue.progress, height: 30)
            }
            .onChange(of: keyframeValue.progress) { _, newValue in
                currentProgress = newValue
            }
        }
    }
    
    private var resetButton: some View {
        Button(action: {
            animationTrigger = false
            currentProgress = 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationStartTime = Date()
                animationTrigger = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                Text("Reset")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.8))
            )
        }
        .padding(.top, 20)
    }
}


#Preview {
    ProgressBarView()
}
