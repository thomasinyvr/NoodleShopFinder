import SwiftUI

struct BadgeView: View {
    let badge: BadgeDefinition
    let progress: UserBadgeProgress?
    let size: CGFloat
    @State private var showingAchievement = false
    @State private var achievementLevel: BadgeLevel?
    
    private var currentLevel: BadgeLevel? {
        guard let progress = progress else { return nil }
        for tier in badge.tiers.sorted(by: { $0.threshold > $1.threshold }) {
            if progress.currentCount >= tier.threshold {
                return tier.level
            }
        }
        return nil
    }
    
    private var progressPercentage: Double {
        guard let progress = progress else { return 0 }
        let nextTier = badge.tiers.first { $0.threshold > progress.currentCount }
        let currentTier = badge.tiers.last { $0.threshold <= progress.currentCount }
        
        if let nextTier = nextTier, let currentTier = currentTier {
            let range = nextTier.threshold - currentTier.threshold
            let progressInRange = Double(progress.currentCount - currentTier.threshold)
            return progressInRange / Double(range)
        }
        return 1.0
    }
    
    private func color(for level: BadgeLevel?) -> Color {
        switch level {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .none: return .black.opacity(0.3)
        }
    }
    
    private func checkForNewAchievement() {
        guard let progress = progress else { return }
        
        // Check if we've reached a new tier
        for tier in badge.tiers {
            if progress.currentCount == tier.threshold {
                achievementLevel = tier.level
                showingAchievement = true
                break
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color(for: currentLevel).opacity(0.3), lineWidth: 4)
                    .frame(width: size, height: size)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(color(for: currentLevel), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                
                // Badge icon
                Image(systemName: badge.systemImageName)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(color(for: currentLevel))
            }
            
            Text(badge.name)
                .font(.headline)
                .lineLimit(1)
            
            if let level = currentLevel {
                Text(level.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Locked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let progress = progress {
                Text("\(progress.currentCount)/\(badge.tiers.last?.threshold ?? 0)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size + 40)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: progress?.currentCount) { _, _ in
            checkForNewAchievement()
        }
        .sheet(isPresented: $showingAchievement) {
            if let level = achievementLevel {
                BadgeAchievementSheet(badge: badge, level: level)
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
    
    let progress = UserBadgeProgress(id: "explorer", currentCount: 15, achievedLevel: .bronze)
    
    return BadgeView(badge: badge, progress: progress, size: 80)
} 