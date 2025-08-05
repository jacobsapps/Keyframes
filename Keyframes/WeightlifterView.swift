//
//  WeightlifterView.swift
//  Keyframes
//
//  Created by Jacob Bartlett on 01/08/2025.
//

import SwiftUI

struct WeightlifterView: View {
    
    struct WeightlifterKeyframes {
        var verticalScale: Double = 1.0
        var verticalOffset: Double = 0.0
    }
    
    struct CloudKeyframes {
        var opacity: Double = 0.0
        var scale: Double = 1.0
    }
    
    var body: some View {
        ZStack {
            Color.indigo.ignoresSafeArea()
            
            VStack(spacing: 40) {
                headerView
                cloudsAndAnimation
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            
            pullTextEffect
        }
        .foregroundColor(.white)
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Weightlifter Animation")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Enhanced with cloud effects and peak moment indicators")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
    
    private var cloudsAndAnimation: some View {
        ZStack {
            clouds
            weightlifterAnimation
        }
    }
    
    private var clouds: some View {
        HStack(spacing: 80) {
            cloudView(delay: 0.0)
            cloudView(delay: 0.1)
            cloudView(delay: 0.2)
        }
        .offset(y: -230)
    }
    
    private func cloudView(delay: Double) -> some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: 80))
            .foregroundColor(.white)
            .keyframeAnimator(
                initialValue: CloudKeyframes(),
                repeating: true
            ) { cloud, keyframes in
                cloud
                    .opacity(keyframes.opacity)
                    .scaleEffect(keyframes.scale)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.0, duration: 0.5 + delay)
                    CubicKeyframe(0.8, duration: 0.25)
                    CubicKeyframe(0.0, duration: 0.25 - delay)
                }
                
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.0, duration: 0.5 + delay, spring: .smooth)
                    SpringKeyframe(0.6, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.25 - delay, spring: .smooth)
                }
            }
    }
    
    private var pullTextEffect: some View {
        Text("PULL!")
            .font(.system(size: 60, weight: .black, design: .rounded))
            .foregroundColor(.yellow)
            .shadow(color: .orange, radius: 10)
            .keyframeAnimator(
                initialValue: CloudKeyframes(),
                repeating: true
            ) { text, keyframes in
                text
                    .opacity(keyframes.opacity)
                    .scaleEffect(keyframes.scale)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.0, duration: 0.5)
                    CubicKeyframe(1.0, duration: 0.25)
                    CubicKeyframe(0.0, duration: 0.25)
                }
                
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.0, duration: 0.5, spring: .smooth)
                    SpringKeyframe(1.3, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.25, spring: .smooth)
                }
            }
            .offset(y: -50)
    }
    
    private var weightlifterAnimation: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .resizable()
            .foregroundStyle(.white)
            .frame(width: 200, height: 200)
            .keyframeAnimator(
                initialValue: WeightlifterKeyframes(),
                repeating: true
            ) { figure, keyframes in
                figure
                    .scaleEffect(y: keyframes.verticalScale, anchor: .bottom)
                    .offset(y: keyframes.verticalOffset)
            } keyframes: { _ in
                KeyframeTrack(\.verticalScale) {
                    LinearKeyframe(0.5, duration: 0.25)
                    LinearKeyframe(1.0, duration: 0.25)
                    LinearKeyframe(1.3, duration: 0.25)
                    LinearKeyframe(1.0, duration: 0.25)
                }
                
                KeyframeTrack(\.verticalOffset) {
                    LinearKeyframe(20, duration: 0.25)
                    SpringKeyframe(-40, duration: 0.5, spring: .snappy)
                    CubicKeyframe(0, duration: 0.25)
                }
            }
    }
}

#Preview {
    WeightlifterView()
}
