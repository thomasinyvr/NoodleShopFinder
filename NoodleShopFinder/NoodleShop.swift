//
//  NoodleShop.swift
//  NoodleShopFinder
//
//  Created by Thomas Friesman on 2025-04-18.
//

import Foundation

struct OpeningPeriod: Codable {
    let open: OpeningTime
    let close: OpeningTime
}

struct OpeningTime: Codable {
    let date: String
    let day: Int
    let time: String
}

struct CurrentOpeningHours: Codable {
    let open_now: Bool
    let periods: [OpeningPeriod]
    let weekday_text: [String]
}

struct Review: Codable {
    let author_name: String?
    let rating: Double?
    let text: String?
    let time: Int?
    let profile_photo_url: String?
}

struct NoodleShop: Identifiable, Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let address: String
    let photo_url: String
    let website: String?
    let rating: Double?
    let price_level: Int?
    let user_ratings_total: Int?
    let current_opening_hours: CurrentOpeningHours?
    let reviews: [Review]?
    let serves_beer: Bool?
    let serves_breakfast: Bool?
}
