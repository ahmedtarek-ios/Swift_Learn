import SwiftUI

struct LearningDiscoveryView: View {
    @Bindable private var viewModel: LearningDiscoveryViewModel
    @State private var supplementalViewModel: SupplementalTracksViewModel
    let journeyViewModel: LearningJourneyViewModel

    init(
        viewModel: LearningDiscoveryViewModel,
        supplementalViewModel: SupplementalTracksViewModel,
        journeyViewModel: LearningJourneyViewModel
    ) {
        self.viewModel = viewModel
        _supplementalViewModel = State(initialValue: supplementalViewModel)
        self.journeyViewModel = journeyViewModel
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading discovery…")
                    .accessibilityIdentifier("discovery-loading")
            case .loaded:
                discoveryContent
            case let .failed(message):
                ContentUnavailableView {
                    Label("Discovery Unavailable", systemImage: "magnifyingglass")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again", action: viewModel.load)
                        .accessibilityIdentifier("retry-discovery")
                }
            }
        }
        .navigationTitle("Discover")
        .searchable(text: $viewModel.query, prompt: "Search skills, syntax, diagnostics, sources")
        .task {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
            if supplementalViewModel.loadState == .idle {
                supplementalViewModel.load()
            }
        }
    }

    @ViewBuilder
    private var discoveryContent: some View {
        if let snapshot = viewModel.snapshot {
            List {
                if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sourceSection(snapshot)
                    supplementalSection
                    glossarySection(snapshot.items)
                } else if viewModel.searchResults.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                        .accessibilityIdentifier("discovery-search-empty")
                } else {
                    Section("Search results") {
                        ForEach(viewModel.searchResults) { result in
                            discoveryLink(
                                item: result.item,
                                matchedFields: result.matchedFields
                            )
                        }
                    }
                }
            }
            .accessibilityIdentifier("discovery-screen")
        }
    }

    private func sourceSection(_ snapshot: LearningDiscoverySnapshot) -> some View {
        Section("Source") {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.editionTitle)
                    .font(.headline)
                Text(snapshot.sourceID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("discovery-source")
        }
    }

    @ViewBuilder
    private var supplementalSection: some View {
        Section("Supplemental labs") {
            switch supplementalViewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading supplemental labs…")
            case .loaded:
                ForEach(supplementalViewModel.tracks) { track in
                    NavigationLink {
                        SupplementalTrackDetailView(
                            track: track,
                            viewModel: supplementalViewModel
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.headline)
                            Text(track.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label("Supplemental · Not Swift-book coverage", systemImage: "books.vertical")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .accessibilityIdentifier("supplemental-track-\(track.id)")
                    .accessibilityValue("\(track.lessons.count) lessons")
                }
            case let .failed(message):
                VStack(alignment: .leading, spacing: 8) {
                    Text(message)
                        .foregroundStyle(.secondary)
                    Button("Try Again", action: supplementalViewModel.load)
                        .accessibilityIdentifier("retry-supplemental-tracks")
                }
            }
        }
    }

    private func glossarySection(_ items: [LearningDiscoveryItem]) -> some View {
        Section("Canonical skill glossary") {
            ForEach(items) { item in
                discoveryLink(item: item, matchedFields: [])
            }
        }
    }

    private func discoveryLink(
        item: LearningDiscoveryItem,
        matchedFields: Set<LearningDiscoveryMatchField>
    ) -> some View {
        NavigationLink {
            LearningDiscoveryDetailView(
                item: item,
                matchedFields: matchedFields,
                journeyViewModel: journeyViewModel
            )
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.skill.title)
                    .font(.headline)
                Text(item.levelTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(availabilityLabel(for: item.primaryLesson))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !matchedFields.isEmpty {
                    Text(matchSummary(matchedFields))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("discovery-skill-\(item.id.rawValue)")
        .accessibilityValue(availabilityLabel(for: item.primaryLesson))
    }

    private func availabilityLabel(for lesson: LearningLesson?) -> String {
        guard let lesson else { return "Unavailable" }
        return switch journeyViewModel.journey?.availability(for: lesson.id) {
        case .unavailable:
            "Unavailable"
        case .locked:
            "Locked"
        case .available:
            "Available"
        case .completed:
            "Completed"
        case nil:
            "Unavailable"
        }
    }

    private func matchSummary(_ fields: Set<LearningDiscoveryMatchField>) -> String {
        fields.sorted { $0.rawValue < $1.rawValue }
            .map { $0.rawValue.capitalized }
            .formatted()
    }
}

private struct LearningDiscoveryDetailView: View {
    let item: LearningDiscoveryItem
    let matchedFields: Set<LearningDiscoveryMatchField>
    let journeyViewModel: LearningJourneyViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.levelTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(item.skill.title)
                    .font(.largeTitle.bold())

                if !matchedFields.isEmpty {
                    Label(
                        "Matched: \(matchedFields.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue).formatted())",
                        systemImage: "magnifyingglass"
                    )
                    .accessibilityIdentifier("discovery-match-fields")
                }

                ForEach(item.lessons) { lesson in
                    lessonSection(lesson)
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle("Skill Detail")
        .accessibilityIdentifier("discovery-skill-detail")
    }

    @ViewBuilder
    private func lessonSection(_ lesson: LearningLesson) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lesson.objective)
                .font(.title3)
            Text(lesson.instruction)
            Divider()
            Text("Source")
                .font(.headline)
            Text(lesson.sourceTitle)
            ForEach(lesson.sourceReferences, id: \.self) { reference in
                Text(reference)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            switch journeyViewModel.journey?.availability(for: lesson.id) {
            case .available, .completed:
                NavigationLink {
                    LessonChallengeView(lesson: lesson, viewModel: journeyViewModel)
                } label: {
                    Label("Practice this skill", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("discovery-practice-\(lesson.id)")
            case let .locked(_, prerequisiteTitle):
                Label(
                    "Complete “\(prerequisiteTitle)” first.",
                    systemImage: "lock.fill"
                )
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("discovery-locked-reason-\(lesson.id)")
            case .unavailable, nil:
                Label("Lesson unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SupplementalTrackDetailView: View {
    let track: SupplementalTrack
    let viewModel: SupplementalTracksViewModel

    var body: some View {
        List {
            Section("Scope") {
                Label("Supplemental · Not Swift-book coverage", systemImage: "books.vertical")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("supplemental-scope-label")
                Text(track.summary)
                Label("Bundled for offline use", systemImage: "network.slash")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("supplemental-offline-status")
            }

            Section("Lessons") {
                ForEach(track.lessons) { lesson in
                    NavigationLink {
                        SupplementalLessonDetailView(
                            lesson: lesson,
                            source: track.source,
                            viewModel: viewModel
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lesson.title)
                                .font(.headline)
                            Text(lesson.objective)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("supplemental-lesson-\(lesson.id)")
                }
            }

            Section("Source lock") {
                Text(track.source.title)
                    .font(.headline)
                ForEach(track.source.references, id: \.self) { reference in
                    Text(reference)
                        .font(.caption.monospaced())
                }
            }
        }
        .navigationTitle(track.title)
        .accessibilityIdentifier("supplemental-track-detail")
    }
}

private struct SupplementalLessonDetailView: View {
    let lesson: SupplementalLesson
    let source: SupplementalSourceLock
    @Bindable var viewModel: SupplementalTracksViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(lesson.objective)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lesson.keyPoints, id: \.self) { point in
                        Label(point, systemImage: "checkmark.circle")
                    }
                }
                .accessibilityElement(children: .contain)

                Divider()
                practice
                if lesson.lab != nil {
                    Divider()
                    authoredLab
                }
                Divider()

                Text("Source lock")
                    .font(.headline)
                Text(source.title)
                ForEach(source.references, id: \.self) { reference in
                    Text(reference)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle(lesson.title)
        .accessibilityIdentifier("supplemental-lesson-detail")
        .onAppear {
            viewModel.resetPractice(for: lesson.id)
        }
    }

    private var practice: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Practice")
                .font(.headline)
            Text(lesson.practice.prompt)
                .font(.title3)
                .accessibilityIdentifier("supplemental-practice-prompt")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    choices
                }
                VStack(alignment: .leading, spacing: 12) {
                    choices
                }
            }

            Button("Check Answer") {
                viewModel.submit(lesson)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedChoiceByLessonID[lesson.id] == nil)
            .accessibilityIdentifier("submit-supplemental-practice")

            if let result = viewModel.resultByLessonID[lesson.id] {
                feedback(result)
                    .accessibilityIdentifier("supplemental-practice-result")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var authoredLab: some View {
        if let lab = lesson.lab {
            let selection = viewModel.labSelection(for: lesson.id)
            VStack(alignment: .leading, spacing: 14) {
                Text("Try a lab")
                    .font(.headline)
                LearningActivityRenderer(
                    activity: lab.activity,
                    orderedChoices: viewModel.orderedLabChoices(for: lesson),
                    selectedChoiceID: nil,
                    codeIdentifier: "supplemental-lab-code",
                    choiceIdentifierPrefix: "supplemental-lab-choice-",
                    selectChoice: { _ in },
                    reduceMotion: LearningMotionPolicy.shouldReduceMotion(
                        systemReduceMotion: systemReduceMotion,
                        preference: motionPreference
                    ),
                    draftText: selection.draftText,
                    selectedTokenIDs: selection.selectedTokenIDs,
                    editText: { viewModel.editLabText($0, for: lesson.id) },
                    selectToken: { viewModel.selectLabToken($0, for: lesson) },
                    removeToken: { viewModel.removeLabToken($0, for: lesson) },
                    resetSelection: { viewModel.resetLabSelection(for: lesson.id) },
                    selectedLayers: selection.selectedLayers,
                    selectLayer: { itemID, layer in
                        viewModel.classify(itemID: itemID, as: layer, for: lesson)
                    }
                )
                Button("Check Lab") {
                    viewModel.submitLab(lesson)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmitLab(lesson))
                .accessibilityIdentifier("submit-supplemental-lab")
#if os(tvOS)
                // A full-width section is reachable by pressing down from any layer column.
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSection()
#endif

                if let result = viewModel.labResultByLessonID[lesson.id] {
                    feedback(result)
                        .accessibilityIdentifier("supplemental-lab-result")
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    @ViewBuilder
    private var choices: some View {
        ForEach(viewModel.orderedPracticeChoices(for: lesson)) { choice in
            Button {
                viewModel.select(choiceID: choice.id, for: lesson.id)
            } label: {
                Label(
                    choice.text,
                    systemImage: viewModel.selectedChoiceByLessonID[lesson.id] == choice.id
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("supplemental-choice-\(choice.id)")
            .accessibilityValue(
                viewModel.selectedChoiceByLessonID[lesson.id] == choice.id
                    ? "Selected"
                    : "Not selected"
            )
        }
    }

    private func feedback(_ result: SupplementalPracticeResult) -> some View {
        switch result {
        case let .correct(message):
            Label(message, systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case let .incorrect(message):
            Label(message, systemImage: "arrow.counterclockwise.circle.fill")
                .foregroundStyle(.orange)
        }
    }
}
