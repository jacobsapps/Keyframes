import SwiftUI

struct DNA3DView: View {
    
    struct Simple3DKeyframes {
        var rotationY: Double = 0
        var rotationX: Double = 0
        var scale: Double = 1
        var offsetY: Double = 0
        var opacity: Double = 1.0
        var hue: Double = 0.0
    }
    
    @State private var basePairCount: Double = 10
    
    var body: some View {
        HStack {
            basePairSlider
                .frame(width: 400)
                
            dnaAnimation
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.black)
        .ignoresSafeArea(.all)
    }
    
    private var basePairSlider: some View {
        VStack(spacing: 12) {
            Text("Base Pairs: \(Int(basePairCount))")
                .foregroundColor(.white)
                .font(.headline)
            
            Slider(value: $basePairCount, in: 2...80, step: 1)
                .accentColor(.cyan)
                .padding(.horizontal, 40)
        }
    }
    
    private var dnaAnimation: some View {
        ZStack {
            dnaBasePairs
        }
        .frame(width: 300, height: 400)
    }
    
    private var dnaBasePairs: some View {
        ForEach(0..<Int(basePairCount), id: \.self) { index in
            HStack(spacing: 60) {
                // Left base
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 25, height: 25)
                
                Circle()
                    .fill(Color.pink)
                    .frame(width: 25, height: 25)
            }
            .overlay(
                // Connection line
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 60, height: 2)
            )
            .keyframeAnimator(
                initialValue: Simple3DKeyframes(),
                repeating: true
            ) { basePair, keyframes in
                basePair
                    .rotation3DEffect(
                        .degrees(keyframes.rotationY),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(keyframes.rotationX),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .scaleEffect(keyframes.scale)
                    .offset(y: keyframes.offsetY)
                    .opacity(keyframes.opacity)
                    .hueRotation(.degrees(keyframes.hue))
            } keyframes: { _ in
                // Helix rotation
                KeyframeTrack(\.rotationY) {
                    let baseAngle = Double(index) * 36  // 36 degrees per base pair for helix
                    
                    LinearKeyframe(baseAngle + 90, duration: 2)
                    CubicKeyframe(baseAngle + 180, duration: 2)
                    SpringKeyframe(baseAngle + 270, duration: 2, spring: .smooth)
                    LinearKeyframe(baseAngle + 360, duration: 2)
                }
                
                // Helix tilt
                KeyframeTrack(\.rotationX) {
                    SpringKeyframe(15, duration: 2, spring: .bouncy)     // Tilt forward
                    CubicKeyframe(-15, duration: 2)                      // Tilt back
                    LinearKeyframe(0, duration: 2)                       // Return to center
                }
                
                // Base pair scale
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.1, duration: 1.5)
                    SpringKeyframe(0.9, duration: 1.5, spring: .bouncy)
                    LinearKeyframe(1.0, duration: 3)
                }
                
                KeyframeTrack(\.offsetY) {
                    let totalHeight = Double(basePairCount) * 25
                    let centerOffset = totalHeight / 2
                    let baseOffset = Double(index) * -25 + centerOffset
                    
                    LinearKeyframe(baseOffset + 10, duration: 2)
                    CubicKeyframe(baseOffset - 10, duration: 2)
                    SpringKeyframe(baseOffset, duration: 2, spring: .smooth)
                }
                
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.4, duration: 1.5)
                    SpringKeyframe(1.0, duration: 1.5, spring: .bouncy)
                    LinearKeyframe(0.7, duration: 3)
                }
                
                KeyframeTrack(\.hue) {
                    let phaseOffset = Double(index) * 30
                    LinearKeyframe(phaseOffset + 60, duration: 2)
                    CubicKeyframe(phaseOffset + 180, duration: 2)
                    SpringKeyframe(phaseOffset + 300, duration: 2, spring: .smooth)
                }
            }
        }
    }
}

#Preview {
    DNA3DView()
}
