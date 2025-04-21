//
//  BadgeModels.swift
//  NoodleShopFinder
//
//  Created by Thomas Friesman on 2025-04-20.
//

import Foundation

enum BadgeLevel: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
}

struct BadgeTier: Codable {
    let level: BadgeLevel
    let threshold: Int
}

struct BadgeDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tiers: [BadgeTier]
    let systemImageName: String
}

struct UserBadgeProgress: Identifiable, Codable {
    var id: String // badge ID
    var currentCount: Int
    var achievedLevel: BadgeLevel?
}

struct BadgeCatalog {
    static let all: [BadgeDefinition] = [
        BadgeDefinition(
            id: "explorer",
            name: "Explorer",
            description: "Visit different noodle shops",
            tiers: [
                BadgeTier(level: .bronze, threshold: 10),
                BadgeTier(level: .silver, threshold: 25),
                BadgeTier(level: .gold, threshold: 50)
            ],
            systemImageName: "map"
        ),
        BadgeDefinition(
            id: "reviewer",
            name: "Reviewer",
            description: "Submit reviews",
            tiers: [
                BadgeTier(level: .bronze, threshold: 5),
                BadgeTier(level: .silver, threshold: 15),
                BadgeTier(level: .gold, threshold: 30)
            ],
            systemImageName: "square.and.pencil"
        ),
        BadgeDefinition(
            id: "first_to_slurp",
            name: "First to Slurp",
            description: "Be the first to review a restaurant",
            tiers: [
                BadgeTier(level: .bronze, threshold: 1),
                BadgeTier(level: .silver, threshold: 5),
                BadgeTier(level: .gold, threshold: 10)
            ],
            systemImageName: "person.crop.circle.badge.checkmark"
        )
    ]
}

