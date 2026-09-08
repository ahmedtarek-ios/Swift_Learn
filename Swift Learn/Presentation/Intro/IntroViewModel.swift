//
//  IntroViewModel.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 25/08/2026.
//

import Observation

enum IntroStep: Int, CaseIterable, Sendable {
    case welcome
    case practice
    case progress
    case source

    var number: Int { rawValue + 1 }
}

@Observable
@MainActor
final class IntroViewModel {
    private(set) var isPresented: Bool
    private(set) var currentStep: IntroStep
    let sourceDisclosure: LearningSourceDisclosure

    init(
        isPresented: Bool = true,
        currentStep: IntroStep = .welcome,
        sourceDisclosure: LearningSourceDisclosure
    ) {
        self.isPresented = isPresented
        self.currentStep = currentStep
        self.sourceDisclosure = sourceDisclosure
    }

    var isFirstStep: Bool {
        currentStep == .welcome
    }

    var isLastStep: Bool {
        currentStep == .source
    }

    func showNextStep() {
        guard
            !isLastStep,
            let nextStep = IntroStep(rawValue: currentStep.rawValue + 1)
        else { return }

        currentStep = nextStep
    }

    func showPreviousStep() {
        guard
            !isFirstStep,
            let previousStep = IntroStep(rawValue: currentStep.rawValue - 1)
        else { return }

        currentStep = previousStep
    }

    func startLearning() {
        isPresented = false
    }
}
