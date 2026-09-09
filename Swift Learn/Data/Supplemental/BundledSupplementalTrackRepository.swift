@MainActor
final class BundledSupplementalTrackRepository: SupplementalTrackRepository {
    func loadTracks() throws -> [SupplementalTrack] {
        [
            testingTrack,
            cleanArchitectureTrack,
            persistenceTrack,
            architecturePatternsTrack,
            securityTrack,
            professionalPracticeTrack,
            releaseReadinessTrack
        ]
    }

    private var testingTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.testing.automation",
            title: "Testing & Automation",
            summary: "Write fast unit tests, focused UI tests, and deterministic runners.",
            source: source(
                id: "testing",
                title: "Swift Learn testing constitution and executable suites",
                references: [
                    "AGENTS.md §2 — Absolute test rule",
                    "Swift LearnTests — Swift Testing unit coverage",
                    "Swift LearnUITests/Swift_LearnUITests.swift — XCTest UI coverage"
                ]
            ),
            lessons: [
                lesson(
                    id: "testing.swift-testing",
                    title: "Unit Tests with Swift Testing",
                    objective: "Test Domain rules and view-model transitions through controlled dependencies.",
                    keyPoints: [
                        "Use Swift Testing for unit and integration behavior.",
                        "Inject repositories, clocks, and identifiers instead of reading global state.",
                        "Assert outcomes and state transitions, not implementation details."
                    ],
                    prompt: "Which dependency makes a time-based unit test deterministic?",
                    correct: "An injected clock",
                    incorrect: "The system wall clock"
                ),
                lesson(
                    id: "testing.ui-testing",
                    title: "UI Tests with XCTest",
                    objective: "Verify the visible entry point and result with a short deterministic path.",
                    keyPoints: [
                        "Launch with controlled fixture state.",
                        "Find controls through stable accessibility identifiers.",
                        "Keep catalog-wide coverage in fast Domain tests."
                    ],
                    prompt: "What should identify a UI-test control across platforms?",
                    correct: "A stable accessibility identifier",
                    incorrect: "Its screen coordinate"
                ),
                lesson(
                    id: "testing.runner-discipline",
                    title: "Runner Discipline",
                    objective: "Preserve trustworthy evidence from one finalized platform cycle.",
                    keyPoints: [
                        "Compile test targets before consuming the finalized run.",
                        "Run once per supported platform when authorized.",
                        "Preserve the first failure instead of hiding it with retries."
                    ],
                    prompt: "A finalized Apple TV test fails. What happens next?",
                    correct: "Record the failure and do not retry automatically",
                    incorrect: "Repeat until it passes"
                )
            ]
        )
    }

    private var cleanArchitectureTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.architecture.swift-learn",
            title: "MVVM + Clean Architecture",
            summary: "Apply the dependency boundaries used by Swift Learn.",
            source: source(
                id: "clean-architecture",
                title: "Swift Learn architecture constitution",
                references: [
                    "AGENTS.md §1 — Absolute architecture rule",
                    "docs/ARCHITECTURE.md — Dependency rule and layer ownership"
                ]
            ),
            lessons: [
                lesson(
                    id: "architecture.dependency-direction",
                    title: "Dependency Direction",
                    objective: "Place dependencies so Domain stays independent.",
                    keyPoints: [
                        "Presentation depends on Domain.",
                        "Data conforms to contracts declared by Domain.",
                        "App constructs and injects concrete dependencies."
                    ],
                    prompt: "Which layer may construct a SwiftData repository?",
                    correct: "App composition",
                    incorrect: "A SwiftUI view"
                ),
                lesson(
                    id: "architecture.mvvm-responsibilities",
                    title: "MVVM Responsibilities",
                    objective: "Keep views, view models, and use cases focused.",
                    keyPoints: [
                        "Views render state and forward user intent.",
                        "View models translate intent into Domain use-case calls.",
                        "Domain owns business rules and repository contracts."
                    ],
                    prompt: "Where should a lesson-unlock rule live?",
                    correct: "Domain",
                    incorrect: "The SwiftUI view"
                )
            ]
        )
    }

    private var persistenceTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.persistence.apple",
            title: "SwiftData & Core Data",
            summary: "Protect Domain while adapting Apple persistence frameworks in Data.",
            source: source(
                id: "persistence",
                title: "Swift Learn persistence and installed Apple SDK interfaces",
                references: [
                    "Swift Learn/Data/Persistence/SwiftLearnSchemaMigrationPlan.swift",
                    "Swift Learn/Data/Repositories/SwiftDataLearningProgressRepository.swift",
                    "Xcode 26.6 SDK — SwiftData and CoreData framework interfaces"
                ]
            ),
            lessons: [
                lesson(
                    id: "persistence.swiftdata-boundary",
                    title: "SwiftData Boundary",
                    objective: "Keep ModelContext and persistent records inside Data.",
                    keyPoints: [
                        "Data maps persistent records to Domain entities.",
                        "Domain declares protocols without importing SwiftData.",
                        "App injects the concrete SwiftData repository."
                    ],
                    prompt: "Where may ModelContext appear in Clean Architecture?",
                    correct: "Data and App composition",
                    incorrect: "Domain entities"
                ),
                lesson(
                    id: "persistence.schema-migrations",
                    title: "Versioned Migrations",
                    objective: "Evolve stored data without silently discarding existing learning state.",
                    keyPoints: [
                        "Use explicit versioned schemas.",
                        "Describe each migration stage.",
                        "Test old records against the current model."
                    ],
                    prompt: "What protects existing records after a schema change?",
                    correct: "An explicit tested migration path",
                    incorrect: "Deleting the store"
                ),
                lesson(
                    id: "persistence.coredata-comparison",
                    title: "Core Data Comparison",
                    objective: "Recognize equivalent persistence responsibilities without leaking either framework inward.",
                    keyPoints: [
                        "SwiftData uses Model, ModelContext, and ModelContainer APIs.",
                        "Core Data uses managed objects, managed-object contexts, and persistent containers.",
                        "Both remain implementation details behind Domain repository contracts."
                    ],
                    prompt: "What stays stable when replacing SwiftData with Core Data?",
                    correct: "The Domain repository contract",
                    incorrect: "The persistent framework types in Domain"
                )
            ]
        )
    }

    private var architecturePatternsTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.architecture.patterns",
            title: "Architecture Pattern Guide",
            summary: "Compare MVC, MVP, MVVM, VIPER, TCA, and Clean Architecture by responsibility.",
            source: source(
                id: "architecture-patterns",
                title: "Swift Learn architecture pattern decision guide",
                references: [
                    "docs/ARCHITECTURE.md — Layer ownership",
                    "AGENTS.md §1 — Required MVVM + Clean Architecture boundary"
                ]
            ),
            lessons: [
                lesson(
                    id: "patterns.mvc-mvp",
                    title: "MVC and MVP",
                    objective: "Compare controller-owned coordination with presenter-owned presentation decisions.",
                    keyPoints: [
                        "MVC places coordination in a controller between model and view.",
                        "MVP uses a presenter to prepare view-facing state and commands.",
                        "Keep framework and business responsibilities explicit in either pattern."
                    ],
                    prompt: "Which MVP component prepares state for the view?",
                    correct: "Presenter",
                    incorrect: "Persistent store"
                ),
                lesson(
                    id: "patterns.mvvm-clean",
                    title: "MVVM and Clean Architecture",
                    objective: "Separate presentation state ownership from inward-pointing business boundaries.",
                    keyPoints: [
                        "MVVM defines view and view-model responsibilities.",
                        "Clean Architecture defines dependency direction and layer boundaries.",
                        "They can work together without duplicating business logic."
                    ],
                    prompt: "What does Clean Architecture primarily constrain?",
                    correct: "Dependency direction",
                    incorrect: "Screen colors"
                ),
                lesson(
                    id: "patterns.viper-tca",
                    title: "VIPER and TCA",
                    objective: "Recognize explicit module roles and explicit state-action-effect modeling.",
                    keyPoints: [
                        "VIPER separates view, interactor, presenter, entity, and router roles.",
                        "TCA models feature state, actions, reducers, and injected dependencies.",
                        "Choose a pattern from verified feature pressure, not popularity."
                    ],
                    prompt: "Which pattern names an Interactor and Router as module roles?",
                    correct: "VIPER",
                    incorrect: "MVVM"
                )
            ]
        )
    }

    private var securityTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.security.privacy",
            title: "Security & Privacy",
            summary: "Minimize data, protect secrets, and make user-controlled export explicit.",
            source: source(
                id: "security-privacy",
                title: "Swift Learn confidentiality and local-data boundaries",
                references: [
                    "AGENTS.md — Confidentiality, non-use, and deletion rule",
                    "Swift Learn/Domain/Profile/CreateLearnerDataReportUseCase.swift",
                    "Swift Learn/Data/Profile/SwiftDataLearnerProfileRepository.swift"
                ]
            ),
            lessons: [
                lesson(
                    id: "security.data-minimization",
                    title: "Data Minimization",
                    objective: "Collect and export only the information required for the feature.",
                    keyPoints: [
                        "Learning diagnostics export aggregate counts only.",
                        "Profile name and avatar are excluded from that export.",
                        "Sharing starts only from an explicit user action."
                    ],
                    prompt: "What belongs in the learning diagnostics export?",
                    correct: "Aggregate learning counts",
                    incorrect: "The learner avatar image"
                ),
                lesson(
                    id: "security.secret-boundaries",
                    title: "Secret Boundaries",
                    objective: "Keep credentials and tokens outside source, logs, and learning fixtures.",
                    keyPoints: [
                        "Never commit bearer tokens or signing passwords.",
                        "Use injected, scoped dependencies for external services.",
                        "Sanitize diagnostics before sharing."
                    ],
                    prompt: "Where should an API bearer token be stored?",
                    correct: "A protected runtime secret store",
                    incorrect: "A bundled lesson fixture"
                )
            ]
        )
    }

    private var professionalPracticeTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.professional.practice",
            title: "Professional Practice",
            summary: "Debug, profile, refactor, review, and design accessibility from evidence.",
            source: source(
                id: "professional-practice",
                title: "Swift Learn evidence and change-discipline rules",
                references: [
                    "AGENTS.md §§3, 6, and 7",
                    "docs/ARCHITECTURE.md — Verification gates",
                    "Swift LearnUITests/Swift_LearnUITests.swift"
                ]
            ),
            lessons: [
                lesson(
                    id: "professional.debug-profile",
                    title: "Debug and Profile from Evidence",
                    objective: "Separate observations, hypotheses, and verified causes.",
                    keyPoints: [
                        "Preserve exact errors and failing paths.",
                        "Measure performance before changing behavior.",
                        "Do not report a hypothesis as a confirmed root cause."
                    ],
                    prompt: "What comes before a performance optimization?",
                    correct: "A reproducible measurement",
                    incorrect: "A speculative rewrite"
                ),
                lesson(
                    id: "professional.refactor-review",
                    title: "Refactor and Review Safely",
                    objective: "Preserve behavior while improving ownership and duplication.",
                    keyPoints: [
                        "Freeze affected behavior with tests.",
                        "Move one responsibility at a time.",
                        "Review dependency direction before style."
                    ],
                    prompt: "What is the first architecture review gate in Swift Learn?",
                    correct: "MVVM + Clean Architecture",
                    incorrect: "Formatting preference"
                ),
                lesson(
                    id: "professional.accessibility",
                    title: "Accessibility as Behavior",
                    objective: "Make controls understandable and operable beyond visual layout.",
                    keyPoints: [
                        "Use semantic controls and stable accessibility identifiers.",
                        "Support Dynamic Type, Reduced Motion, and logical focus order.",
                        "Test the visible result on every supported platform."
                    ],
                    prompt: "Which control should represent a tappable action?",
                    correct: "Button",
                    incorrect: "Decorative text with a tap gesture"
                )
            ]
        )
    }

    private var releaseReadinessTrack: SupplementalTrack {
        SupplementalTrack(
            id: "supplemental.release.readiness",
            title: "Release Readiness",
            summary: "Audit source attribution, privacy, accessibility, packaging, and platform proof.",
            source: source(
                id: "release-readiness",
                title: "Swift Learn release evidence",
                references: [
                    "LICENSE — MIT license for original project code",
                    "THIRD_PARTY_NOTICES.txt — Swift book attribution",
                    "PRIVACY.txt — Local-data disclosure",
                    "docs/RELEASE_READINESS.md — Release gate evidence"
                ]
            ),
            lessons: [
                lesson(
                    id: "release.legal-privacy",
                    title: "Legal and Privacy Gate",
                    objective: "Ship readable attribution and an accurate data-use disclosure.",
                    keyPoints: [
                        "Keep the project license consistent with repository documentation.",
                        "Retain required source and trademark attribution.",
                        "Describe collection, storage, export, and deletion behavior exactly."
                    ],
                    prompt: "What must a privacy disclosure match?",
                    correct: "The app's actual data behavior",
                    incorrect: "A generic marketing template"
                ),
                lesson(
                    id: "release.platform-gate",
                    title: "Four-Platform Gate",
                    objective: "Require independent evidence for every supported destination.",
                    keyPoints: [
                        "Compile the app and both test targets for every destination.",
                        "Run unit and UI suites once per platform when authorized.",
                        "Report blockers without converting them into passes."
                    ],
                    prompt: "Does an iPhone pass prove Apple TV behavior?",
                    correct: "No, each platform needs its own evidence",
                    incorrect: "Yes, because Domain is shared"
                )
            ]
        )
    }

    private func source(
        id: String,
        title: String,
        references: [String]
    ) -> SupplementalSourceLock {
        SupplementalSourceLock(
            id: "supplemental.source.\(id)",
            title: title,
            references: references
        )
    }

    private func lesson(
        id: String,
        title: String,
        objective: String,
        keyPoints: [String],
        prompt: String,
        correct: String,
        incorrect: String
    ) -> SupplementalLesson {
        SupplementalLesson(
            id: "supplemental.\(id)",
            title: title,
            objective: objective,
            keyPoints: keyPoints,
            practice: SupplementalPractice(
                prompt: prompt,
                choices: [
                    SupplementalPracticeChoice(id: "correct", text: correct),
                    SupplementalPracticeChoice(id: "incorrect", text: incorrect)
                ],
                correctChoiceID: "correct",
                correctFeedback: "Correct. Apply this boundary in the next production change.",
                incorrectFeedback: "Review the lesson boundary, then choose again."
            )
        )
    }
}
