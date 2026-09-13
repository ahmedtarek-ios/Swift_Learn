//
//  LearningMotion.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
// 

import SwiftUI

enum LearningMotionPolicy {
    static func shouldReduceMotion(
        systemReduceMotion: Bool,
        preference: LearnerMotionPreference
    ) -> Bool {
        systemReduceMotion || preference == .reduced
    }
}

enum LearningMotion {
    static func selection(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.18)
    }

    static func feedback(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: 0.38, bounce: 0.18)
    }

    static func progress(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.45)
    }

    static func celebration(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.22)
    }
}

private struct LearnerMotionPreferenceKey: EnvironmentKey {
    static let defaultValue = LearnerMotionPreference.system
}

extension EnvironmentValues {
    var learnerMotionPreference: LearnerMotionPreference {
        get { self[LearnerMotionPreferenceKey.self] }
        set { self[LearnerMotionPreferenceKey.self] = newValue }
    }
}

struct AchievementUnlockOverlay: View {
    let achievement: AchievementProgress
    let headline: String
    let reduceMotion: Bool
    let dismiss: () -> Void

    @State private var isPresented = false
#if os(tvOS)
    @FocusState private var isDismissFocused: Bool
#endif

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                ZStack {
                    celebrationBurst

                    Image(systemName: "medal.fill")
                        .font(.system(size: 68, weight: .bold))
                        .foregroundStyle(.yellow)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isPresented || reduceMotion ? 1 : 0.45)
                }
                .frame(height: 118)

                Text(headline)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(achievement.definition.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(achievement.definition.summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Keep Learning", action: dismiss)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("dismiss-achievement-unlock")
#if os(tvOS)
                    .focused($isDismissFocused)
#endif
            }
            .frame(maxWidth: 460)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding()
            .scaleEffect(isPresented || reduceMotion ? 1 : 0.82)
            .opacity(isPresented || reduceMotion ? 1 : 0)
            .shadow(color: .black.opacity(0.22), radius: 22, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("achievement-unlock-overlay")
        .accessibilityValue(achievement.id)
        .onAppear {
            withAnimation(LearningMotion.celebration(reduceMotion: reduceMotion)) {
                isPresented = true
            }
#if os(tvOS)
            isDismissFocused = true
#endif
        }
    }

    private var celebrationBurst: some View {
        ForEach(0..<8, id: \.self) { index in
            Circle()
                .fill(index.isMultiple(of: 2) ? Color.yellow : Color.accentColor)
                .frame(width: 10, height: 10)
                .offset(y: isPresented && !reduceMotion ? -52 : -22)
                .rotationEffect(.degrees(Double(index) * 45))
                .opacity(isPresented && !reduceMotion ? 0.15 : 0.9)
        }
    }
}
