//
//  IntroView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 25/08/2026.
//

import SwiftUI

struct IntroView: View {
    let viewModel: IntroViewModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            IntroBackground()

            ScrollView {
                VStack(spacing: 24) {
                    IntroProgressHeader(currentStep: viewModel.currentStep)

                    IntroStepContent(
                        step: viewModel.currentStep,
                        hasAppeared: hasAppeared,
                        reduceMotion: systemReduceMotion
                    )
                    .id(viewModel.currentStep)
                    .transition(stepTransition)

                    IntroNavigation(
                        viewModel: viewModel,
                        reduceMotion: systemReduceMotion
                    )

                    Text("In ❤️ of Swift")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.64))
                }
                .frame(maxWidth: 960)
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.vertical, alignment: .center)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("intro-screen")
        .onAppear {
            withAnimation(
                LearningMotion.celebration(reduceMotion: systemReduceMotion)
            ) {
                hasAppeared = true
            }
        }
    }

    private var stepTransition: AnyTransition {
        guard !systemReduceMotion else { return .opacity }

        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

private struct IntroProgressHeader: View {
    let currentStep: IntroStep

    var body: some View {
        HStack(spacing: 14) {
            Text("STEP \(currentStep.number) OF \(IntroStep.allCases.count)")
                .font(.caption.weight(.heavy))
                .tracking(1.6)
                .foregroundStyle(.orange)

            Spacer()

            HStack(spacing: 8) {
                ForEach(IntroStep.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(
                            step.rawValue <= currentStep.rawValue
                                ? Color.orange
                                : Color.white.opacity(0.18)
                        )
                        .frame(
                            width: step == currentStep ? 30 : 10,
                            height: 10
                        )
                }
            }
            .animation(.snappy, value: currentStep)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Step \(currentStep.number) of \(IntroStep.allCases.count)"
        )
        .accessibilityIdentifier("intro-progress")
    }
}

private struct IntroStepContent: View {
    let step: IntroStep
    let hasAppeared: Bool
    let reduceMotion: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 54) {
                IntroStepArtwork(
                    step: step,
                    hasAppeared: hasAppeared,
                    reduceMotion: reduceMotion,
                    size: 310
                )

                IntroStepMessage(step: step)
                    .frame(maxWidth: 500, alignment: .leading)
            }
            .frame(minWidth: 800)

            VStack(spacing: 26) {
                IntroStepArtwork(
                    step: step,
                    hasAppeared: hasAppeared,
                    reduceMotion: reduceMotion,
                    size: 180
                )

                IntroStepMessage(step: step)
                    .frame(maxWidth: 620)
            }
        }
        .padding(28)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 28)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 30, y: 16)
        .accessibilityIdentifier("intro-step-\(step.number)")
    }
}

private struct IntroStepArtwork: View {
    let step: IntroStep
    let hasAppeared: Bool
    let reduceMotion: Bool
    let size: CGFloat

    var body: some View {
        artwork
            .frame(width: size, height: size)
            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.82)
            .offset(y: hasAppeared || reduceMotion ? 0 : 24)
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
            .shadow(color: .orange.opacity(0.24), radius: 34, y: 18)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var artwork: some View {
        switch step {
        case .welcome:
            Image("CodeAscensionTransparent")
                .resizable()
                .scaledToFit()
                .accessibilityIdentifier("intro-logo")
        case .practice:
            IntroSymbolArtwork(
                symbol: "chevron.left.forwardslash.chevron.right",
                colors: [.orange, .red]
            )
        case .progress:
            IntroSymbolArtwork(
                symbol: "chart.line.uptrend.xyaxis",
                colors: [.red, .orange]
            )
        }
    }
}

private struct IntroSymbolArtwork: View {
    let symbol: String
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: colors.map { $0.opacity(0.22) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 1)

            Image(systemName: symbol)
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

private struct IntroStepMessage: View {
    let step: IntroStep

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(step.eyebrow)
                .font(.caption.weight(.heavy))
                .tracking(2.4)
                .foregroundStyle(.orange)

            Text(step.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("intro-title")

            Text(step.subtitle)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text(step.detail)
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
    }
}

private struct IntroNavigation: View {
    let viewModel: IntroViewModel
    let reduceMotion: Bool

#if os(tvOS)
    @FocusState private var isPrimaryFocused: Bool
#endif

    var body: some View {
        HStack(spacing: 14) {
            if !viewModel.isFirstStep {
                Button("Back", systemImage: "arrow.left") {
                    changeStep(viewModel.showPreviousStep)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("intro-back")
            }

            Button(action: primaryAction) {
                Label(
                    viewModel.isLastStep ? "Start Learning" : "Next",
                    systemImage: viewModel.isLastStep
                        ? "arrow.up.forward"
                        : "arrow.right"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .accessibilityHint(primaryAccessibilityHint)
            .accessibilityIdentifier(
                viewModel.isLastStep
                    ? "intro-start-learning"
                    : "intro-next"
            )
#if os(tvOS)
            .focused($isPrimaryFocused)
#endif
        }
        .frame(maxWidth: 620)
#if os(tvOS)
        .onAppear {
            isPrimaryFocused = true
        }
        .onChange(of: viewModel.currentStep) {
            isPrimaryFocused = true
        }
#endif
    }

    private var primaryAccessibilityHint: String {
        viewModel.isLastStep
            ? "Opens the Swift learning journey"
            : "Shows the next introduction step"
    }

    private func primaryAction() {
        if viewModel.isLastStep {
            changeStep(viewModel.startLearning)
        } else {
            changeStep(viewModel.showNextStep)
        }
    }

    private func changeStep(_ action: () -> Void) {
        withAnimation(LearningMotion.celebration(reduceMotion: reduceMotion)) {
            action()
        }
    }
}

private struct IntroBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.10),
                Color(red: 0.10, green: 0.07, blue: 0.12),
                Color(red: 0.16, green: 0.06, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.orange.opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: 120, y: -140)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(.red.opacity(0.14))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: -120, y: 120)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private extension IntroStep {
    var eyebrow: LocalizedStringKey {
        switch self {
        case .welcome:
            "CODE ASCENSION"
        case .practice:
            "LEARN BY BUILDING"
        case .progress:
            "BUILD MOMENTUM"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .welcome:
            "Welcome to Swift Learn"
        case .practice:
            "Write code. See why it works."
        case .progress:
            "Turn practice into progress."
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome:
            "Rise through Swift one challenge at a time."
        case .practice:
            "Practice Swift in focused challenges."
        case .progress:
            "Complete lessons, unlock the path, and celebrate every milestone."
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .welcome:
            "A focused path that turns Swift study into short, practical wins."
        case .practice:
            "Choose an answer, get immediate feedback, and understand the idea before moving forward."
        case .progress:
            "Your journey and profile make growth visible so the next challenge always feels within reach."
        }
    }
}

#Preview {
    IntroView(viewModel: IntroViewModel())
}
