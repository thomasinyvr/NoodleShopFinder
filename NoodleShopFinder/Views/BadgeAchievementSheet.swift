import SwiftUI

struct BadgeAchievementSheet: View {
    let badge: BadgeDefinition
    let level: BadgeLevel
    @Environment(\.dismiss) private var dismiss
    
    private func color(for level: BadgeLevel) -> Color {
        switch level {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        }
    }
    
    private func message(for level: BadgeLevel) -> String {
        switch level {
        case .bronze: return "You've earned the Bronze level!"
        case .silver: return "Amazing! You've reached Silver!"
        case .gold: return "Incredible! You've achieved Gold!"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(color(for: level).opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: badge.systemImageName)
                        .font(.system(size: 60))
                        .foregroundColor(color(for: level))
                }
                
                // Achievement Text
                VStack(spacing: 8) {
                    Text(badge.name)
                        .font(.title)
                        .bold()
                    
                    Text(level.rawValue.capitalized)
                        .font(.title2)
                        .foregroundColor(color(for: level))
                    
                    Text(message(for: level))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                // Description
                Text(badge.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Achievement Unlocked!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let badge = BadgeDefinition(
        id: "explorer",
        name: "Explorer",
        description: "Visit different noodle shops",
        tiers: [
            BadgeTier(level: .bronze, threshold: 10),
            BadgeTier(level: .silver, threshold: 25),
            BadgeTier(level: .gold, threshold: 50)
        ],
        systemImageName: "map"
    )
    
    return BadgeAchievementSheet(badge: badge, level: .gold)
} 