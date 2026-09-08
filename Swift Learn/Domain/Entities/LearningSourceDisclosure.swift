//
//  LearningSourceDisclosure.swift
//  Swift Learn
//
//  Created by Codex on 08/09/2026.
//

struct LearningSourceDisclosure: Equatable, Sendable {
    let sourceID: String
    let editionTitle: String

    init(catalog: LearningCatalog) {
        sourceID = catalog.sourceID
        editionTitle = catalog.editionTitle
    }

    init(sourceID: String, editionTitle: String) {
        self.sourceID = sourceID
        self.editionTitle = editionTitle
    }
}
