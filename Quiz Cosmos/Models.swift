import Foundation
import SwiftUI
import Combine

struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let question: String
    let options: [String]
    let correctAnswer: Int
    let difficulty: Difficulty
    let category: SpaceCategory
    let explanation: String
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
        
        var points: Int {
            switch self {
            case .easy: return 10
            case .medium: return 20
            case .hard: return 30
            }
        }
    }
    
    enum SpaceCategory: String, Codable, CaseIterable {
        case planets = "Planets"
        case stars = "Stars"
        case galaxies = "Galaxies"
        case exploration = "Exploration"
        case blackHoles = "Black Holes"
        case moons = "Moons"
        
        var icon: String {
            switch self {
            case .planets: return "globe.americas.fill"
            case .stars: return "star.fill"
            case .galaxies: return "sparkles"
            case .exploration: return "airplane"
            case .blackHoles: return "circle.fill"
            case .moons: return "moon.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .planets: return [Color(hex: "667eea"), Color(hex: "764ba2")]
            case .stars: return [Color(hex: "f093fb"), Color(hex: "f5576c")]
            case .galaxies: return [Color(hex: "4facfe"), Color(hex: "00f2fe")]
            case .exploration: return [Color(hex: "43e97b"), Color(hex: "38f9d7")]
            case .blackHoles: return [Color(hex: "0c0c0c"), Color(hex: "434343")]
            case .moons: return [Color(hex: "c3cfe2"), Color(hex: "c3cfe2")]
            }
        }
    }
}

class UserProgress: ObservableObject {
    @Published var totalScore: Int { didSet { save() } }
    @Published var questionsAnswered: Int { didSet { save() } }
    @Published var correctAnswers: Int { didSet { save() } }
    @Published var currentStreak: Int { didSet { save() } }
    @Published var bestStreak: Int { didSet { save() } }
    @Published var achievements: Set<String> { didSet { save() } }
    @Published var categoryProgress: [String: Int] { didSet { save() } }
    @Published var dailyQuizCompleted: Bool { didSet { save() } }
    @Published var lastPlayedDate: Date? { didSet { save() } }
    
    init() {
        let defaults = UserDefaults.standard
        self.totalScore = defaults.integer(forKey: "totalScore")
        self.questionsAnswered = defaults.integer(forKey: "questionsAnswered")
        self.correctAnswers = defaults.integer(forKey: "correctAnswers")
        self.currentStreak = defaults.integer(forKey: "currentStreak")
        self.bestStreak = defaults.integer(forKey: "bestStreak")
        self.dailyQuizCompleted = defaults.bool(forKey: "dailyQuizCompleted")
        self.lastPlayedDate = defaults.object(forKey: "lastPlayedDate") as? Date
        
        if let achievementsData = defaults.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: achievementsData) {
            self.achievements = decoded
        } else {
            self.achievements = []
        }
        
        if let categoryData = defaults.data(forKey: "categoryProgress"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: categoryData) {
            self.categoryProgress = decoded
        } else {
            self.categoryProgress = [:]
        }
        
        checkDailyReset()
    }
    
    private func checkDailyReset() {
        if let lastDate = lastPlayedDate {
            if !Calendar.current.isDateInToday(lastDate) {
                dailyQuizCompleted = false
            }
        }
    }
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(totalScore, forKey: "totalScore")
        defaults.set(questionsAnswered, forKey: "questionsAnswered")
        defaults.set(correctAnswers, forKey: "correctAnswers")
        defaults.set(currentStreak, forKey: "currentStreak")
        defaults.set(bestStreak, forKey: "bestStreak")
        defaults.set(dailyQuizCompleted, forKey: "dailyQuizCompleted")
        defaults.set(lastPlayedDate, forKey: "lastPlayedDate")
        
        if let encoded = try? JSONEncoder().encode(achievements) {
            defaults.set(encoded, forKey: "achievements")
        }
        if let encoded = try? JSONEncoder().encode(categoryProgress) {
            defaults.set(encoded, forKey: "categoryProgress")
        }
    }
    
    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
    
    var level: Int {
        return totalScore / 500 + 1
    }
    
    var levelProgress: Double {
        let pointsInCurrentLevel = totalScore % 500
        return Double(pointsInCurrentLevel) / 500.0
    }
    
    func resetProgress() {
        totalScore = 0
        questionsAnswered = 0
        correctAnswers = 0
        currentStreak = 0
        bestStreak = 0
        achievements = []
        categoryProgress = [:]
        dailyQuizCompleted = false
    }
}

class AppSettings: ObservableObject {
    @Published var soundEnabled: Bool { didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") } }
    @Published var hapticEnabled: Bool { didSet { UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled") } }
    @Published var showExplanations: Bool { didSet { UserDefaults.standard.set(showExplanations, forKey: "showExplanations") } }
    @Published var questionCount: Int { didSet { UserDefaults.standard.set(questionCount, forKey: "questionCount") } }
    @Published var selectedDifficulty: QuizQuestion.Difficulty? {
        didSet {
            if let diff = selectedDifficulty {
                UserDefaults.standard.set(diff.rawValue, forKey: "selectedDifficulty")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedDifficulty")
            }
        }
    }
    @Published var timerEnabled: Bool { didSet { UserDefaults.standard.set(timerEnabled, forKey: "timerEnabled") } }
    @Published var timePerQuestion: Int { didSet { UserDefaults.standard.set(timePerQuestion, forKey: "timePerQuestion") } }
    
    init() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "soundEnabled") == nil { defaults.set(true, forKey: "soundEnabled") }
        if defaults.object(forKey: "hapticEnabled") == nil { defaults.set(true, forKey: "hapticEnabled") }
        if defaults.object(forKey: "showExplanations") == nil { defaults.set(true, forKey: "showExplanations") }
        if defaults.object(forKey: "questionCount") == nil { defaults.set(10, forKey: "questionCount") }
        if defaults.object(forKey: "timerEnabled") == nil { defaults.set(true, forKey: "timerEnabled") }
        if defaults.object(forKey: "timePerQuestion") == nil { defaults.set(30, forKey: "timePerQuestion") }
        
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.hapticEnabled = defaults.bool(forKey: "hapticEnabled")
        self.showExplanations = defaults.bool(forKey: "showExplanations")
        self.questionCount = defaults.integer(forKey: "questionCount")
        self.timerEnabled = defaults.bool(forKey: "timerEnabled")
        self.timePerQuestion = defaults.integer(forKey: "timePerQuestion")
        
        if let diffString = defaults.string(forKey: "selectedDifficulty") {
            self.selectedDifficulty = QuizQuestion.Difficulty(rawValue: diffString)
        } else {
            self.selectedDifficulty = nil
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    let type: AchievementType
    
    enum AchievementType {
        case score, streak, questions, accuracy, category
    }
    
    static let all: [Achievement] = [
        Achievement(id: "first_steps", title: "First Steps", description: "Answer your first question", icon: "star.fill", requirement: 1, type: .questions),
        Achievement(id: "curious_mind", title: "Curious Mind", description: "Answer 50 questions", icon: "brain.head.profile", requirement: 50, type: .questions),
        Achievement(id: "space_scholar", title: "Space Scholar", description: "Answer 200 questions", icon: "graduationcap.fill", requirement: 200, type: .questions),
        Achievement(id: "cosmic_master", title: "Cosmic Master", description: "Answer 500 questions", icon: "crown.fill", requirement: 500, type: .questions),
        Achievement(id: "hot_streak_5", title: "Getting Warmed Up", description: "Get a 5 question streak", icon: "flame.fill", requirement: 5, type: .streak),
        Achievement(id: "hot_streak_10", title: "On Fire!", description: "Get a 10 question streak", icon: "flame.fill", requirement: 10, type: .streak),
        Achievement(id: "hot_streak_25", title: "Unstoppable", description: "Get a 25 question streak", icon: "bolt.fill", requirement: 25, type: .streak),
        Achievement(id: "centurion", title: "Centurion", description: "Reach 100 points", icon: "100.circle.fill", requirement: 100, type: .score),
        Achievement(id: "thousand_club", title: "Thousand Club", description: "Reach 1000 points", icon: "trophy.fill", requirement: 1000, type: .score),
        Achievement(id: "galaxy_brain", title: "Galaxy Brain", description: "Reach 5000 points", icon: "sparkles", requirement: 5000, type: .score),
    ]
}

struct QuestionBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(id: UUID(), question: "Which planet is known as the Red Planet?", options: ["Venus", "Mars", "Jupiter", "Saturn"], correctAnswer: 1, difficulty: .easy, category: .planets, explanation: "Mars is called the Red Planet due to iron oxide (rust) on its surface."),
        QuizQuestion(id: UUID(), question: "What is the largest planet in our Solar System?", options: ["Saturn", "Neptune", "Jupiter", "Uranus"], correctAnswer: 2, difficulty: .easy, category: .planets, explanation: "Jupiter is the largest planet, with a mass more than twice that of all other planets combined."),
        QuizQuestion(id: UUID(), question: "Which planet is closest to the Sun?", options: ["Venus", "Mercury", "Mars", "Earth"], correctAnswer: 1, difficulty: .easy, category: .planets, explanation: "Mercury orbits closest to the Sun at an average distance of about 58 million kilometers."),
        QuizQuestion(id: UUID(), question: "How many planets are in our Solar System?", options: ["7", "8", "9", "10"], correctAnswer: 1, difficulty: .easy, category: .planets, explanation: "There are 8 planets: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, and Neptune."),
        QuizQuestion(id: UUID(), question: "Which planet has the most visible rings?", options: ["Jupiter", "Uranus", "Neptune", "Saturn"], correctAnswer: 3, difficulty: .easy, category: .planets, explanation: "Saturn's rings are the most visible and extensive, made primarily of ice particles."),
        QuizQuestion(id: UUID(), question: "Which planet is called Earth's twin?", options: ["Mars", "Venus", "Mercury", "Neptune"], correctAnswer: 1, difficulty: .easy, category: .planets, explanation: "Venus is similar to Earth in size and mass, earning it the nickname Earth's twin."),
        QuizQuestion(id: UUID(), question: "Which planet is farthest from the Sun?", options: ["Uranus", "Saturn", "Neptune", "Pluto"], correctAnswer: 2, difficulty: .easy, category: .planets, explanation: "Neptune is the farthest planet from the Sun in our Solar System."),
        QuizQuestion(id: UUID(), question: "Which planet rotates on its side?", options: ["Neptune", "Uranus", "Saturn", "Jupiter"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "Uranus has an axial tilt of about 98 degrees, likely caused by a collision."),
        QuizQuestion(id: UUID(), question: "What is the Great Red Spot?", options: ["A volcano on Mars", "A storm on Jupiter", "A crater on Mercury", "A moon of Saturn"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "The Great Red Spot is a giant storm on Jupiter raging for at least 400 years."),
        QuizQuestion(id: UUID(), question: "Which planet has the longest day?", options: ["Mercury", "Venus", "Mars", "Jupiter"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "Venus takes 243 Earth days to complete one rotation."),
        QuizQuestion(id: UUID(), question: "Which planet has the shortest year?", options: ["Venus", "Mercury", "Mars", "Earth"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "Mercury orbits the Sun in just 88 Earth days."),
        QuizQuestion(id: UUID(), question: "What gives Mars its red color?", options: ["Copper", "Iron oxide", "Sulfur", "Nitrogen"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "Iron oxide (rust) in the Martian soil gives the planet its distinctive red color."),
        QuizQuestion(id: UUID(), question: "Which planet has the strongest magnetic field?", options: ["Earth", "Saturn", "Jupiter", "Uranus"], correctAnswer: 2, difficulty: .medium, category: .planets, explanation: "Jupiter has the strongest magnetic field of any planet in our Solar System."),
        QuizQuestion(id: UUID(), question: "How many Earth years does it take Saturn to orbit the Sun?", options: ["12 years", "29 years", "84 years", "165 years"], correctAnswer: 1, difficulty: .medium, category: .planets, explanation: "Saturn takes approximately 29 Earth years to complete one orbit around the Sun."),
        QuizQuestion(id: UUID(), question: "What is the average surface temperature on Venus?", options: ["200°C", "350°C", "465°C", "550°C"], correctAnswer: 2, difficulty: .hard, category: .planets, explanation: "Venus has an average surface temperature of 465°C due to its extreme greenhouse effect."),
        QuizQuestion(id: UUID(), question: "How fast are winds in Neptune's Great Dark Spot?", options: ["500 km/h", "1,200 km/h", "2,100 km/h", "3,000 km/h"], correctAnswer: 2, difficulty: .hard, category: .planets, explanation: "Neptune has the strongest winds in the solar system, reaching up to 2,100 km/h."),
        QuizQuestion(id: UUID(), question: "What is the atmospheric pressure on Venus compared to Earth?", options: ["10 times", "50 times", "92 times", "150 times"], correctAnswer: 2, difficulty: .hard, category: .planets, explanation: "Venus's atmospheric pressure is about 92 times that of Earth's."),
        QuizQuestion(id: UUID(), question: "What is the tallest volcano in the Solar System?", options: ["Mount Everest", "Olympus Mons", "Mauna Kea", "Maxwell Montes"], correctAnswer: 1, difficulty: .hard, category: .planets, explanation: "Olympus Mons on Mars is the tallest volcano, standing at about 22 km high."),
        QuizQuestion(id: UUID(), question: "Which planet has diamond rain?", options: ["Jupiter", "Saturn", "Neptune", "Both B and C"], correctAnswer: 3, difficulty: .hard, category: .planets, explanation: "Both Saturn and Neptune are believed to have diamond rain in their atmospheres."),
        QuizQuestion(id: UUID(), question: "What percentage of the Solar System's mass does the Sun contain?", options: ["85%", "92%", "99.86%", "75%"], correctAnswer: 2, difficulty: .hard, category: .planets, explanation: "The Sun contains 99.86% of all mass in our Solar System."),
        
        QuizQuestion(id: UUID(), question: "What is the closest star to Earth?", options: ["Proxima Centauri", "Sirius", "The Sun", "Alpha Centauri"], correctAnswer: 2, difficulty: .easy, category: .stars, explanation: "The Sun is our closest star, located about 150 million kilometers from Earth."),
        QuizQuestion(id: UUID(), question: "What color are the hottest stars?", options: ["Red", "Yellow", "Blue", "Orange"], correctAnswer: 2, difficulty: .easy, category: .stars, explanation: "Blue stars are the hottest, with surface temperatures exceeding 30,000 Kelvin."),
        QuizQuestion(id: UUID(), question: "What is the brightest star in the night sky?", options: ["Polaris", "Betelgeuse", "Sirius", "Vega"], correctAnswer: 2, difficulty: .easy, category: .stars, explanation: "Sirius, also known as the Dog Star, is the brightest star visible from Earth."),
        QuizQuestion(id: UUID(), question: "What is a group of stars that forms a pattern called?", options: ["Galaxy", "Constellation", "Nebula", "Cluster"], correctAnswer: 1, difficulty: .easy, category: .stars, explanation: "A constellation is a group of stars forming a recognizable pattern in the night sky."),
        QuizQuestion(id: UUID(), question: "What is the North Star called?", options: ["Sirius", "Vega", "Polaris", "Betelgeuse"], correctAnswer: 2, difficulty: .easy, category: .stars, explanation: "Polaris is the North Star, used for navigation for centuries."),
        QuizQuestion(id: UUID(), question: "What do stars produce energy through?", options: ["Combustion", "Nuclear fusion", "Chemical reactions", "Electricity"], correctAnswer: 1, difficulty: .easy, category: .stars, explanation: "Stars produce energy through nuclear fusion, converting hydrogen into helium."),
        QuizQuestion(id: UUID(), question: "What color are the coolest stars?", options: ["Blue", "White", "Yellow", "Red"], correctAnswer: 3, difficulty: .easy, category: .stars, explanation: "Red stars are the coolest, with surface temperatures around 3,000 Kelvin."),
        QuizQuestion(id: UUID(), question: "What type of star is our Sun?", options: ["Red Dwarf", "White Dwarf", "Yellow Dwarf", "Red Giant"], correctAnswer: 2, difficulty: .medium, category: .stars, explanation: "Our Sun is a G-type main-sequence star, commonly called a yellow dwarf."),
        QuizQuestion(id: UUID(), question: "What happens when a massive star dies?", options: ["It becomes a planet", "It explodes as a supernova", "It slowly fades away", "It turns into a comet"], correctAnswer: 1, difficulty: .medium, category: .stars, explanation: "Massive stars end their lives in spectacular supernova explosions."),
        QuizQuestion(id: UUID(), question: "What is a binary star system?", options: ["A dying star", "Two stars orbiting each other", "A star with planets", "A very bright star"], correctAnswer: 1, difficulty: .medium, category: .stars, explanation: "A binary star system consists of two stars orbiting around their common center of mass."),
        QuizQuestion(id: UUID(), question: "What is the life cycle stage after a red giant?", options: ["Supernova", "White dwarf", "Neutron star", "Depends on mass"], correctAnswer: 3, difficulty: .medium, category: .stars, explanation: "A star's fate after red giant depends on its mass - smaller stars become white dwarfs."),
        QuizQuestion(id: UUID(), question: "How long does light from the Sun take to reach Earth?", options: ["8 seconds", "8 minutes", "8 hours", "8 days"], correctAnswer: 1, difficulty: .medium, category: .stars, explanation: "Light from the Sun takes about 8 minutes and 20 seconds to reach Earth."),
        QuizQuestion(id: UUID(), question: "What is a red giant star?", options: ["A young hot star", "An old expanded star", "A binary star", "A neutron star"], correctAnswer: 1, difficulty: .medium, category: .stars, explanation: "A red giant is an aging star that has exhausted its hydrogen fuel and expanded."),
        QuizQuestion(id: UUID(), question: "What is the approximate age of the Sun?", options: ["1 billion years", "4.6 billion years", "10 billion years", "100 million years"], correctAnswer: 1, difficulty: .medium, category: .stars, explanation: "The Sun is approximately 4.6 billion years old."),
        QuizQuestion(id: UUID(), question: "What is a pulsar?", options: ["A dying star", "A rotating neutron star", "A binary star system", "A newly formed star"], correctAnswer: 1, difficulty: .hard, category: .stars, explanation: "A pulsar is a highly magnetized rotating neutron star emitting electromagnetic radiation."),
        QuizQuestion(id: UUID(), question: "What is the Chandrasekhar limit?", options: ["1.4 solar masses", "3 solar masses", "10 solar masses", "0.5 solar masses"], correctAnswer: 0, difficulty: .hard, category: .stars, explanation: "The Chandrasekhar limit is about 1.4 solar masses, the maximum mass of a white dwarf."),
        QuizQuestion(id: UUID(), question: "What is a magnetar?", options: ["A magnetic planet", "A type of neutron star", "A magnetic galaxy", "A solar flare"], correctAnswer: 1, difficulty: .hard, category: .stars, explanation: "A magnetar is a neutron star with an extremely powerful magnetic field."),
        QuizQuestion(id: UUID(), question: "What causes a star to become a supernova?", options: ["Collision with asteroid", "Core collapse", "Too much hydrogen", "Solar winds"], correctAnswer: 1, difficulty: .hard, category: .stars, explanation: "A supernova occurs when a massive star's core collapses after nuclear fusion stops."),
        QuizQuestion(id: UUID(), question: "What is stellar nucleosynthesis?", options: ["Star birth", "Element creation in stars", "Star death", "Star movement"], correctAnswer: 1, difficulty: .hard, category: .stars, explanation: "Stellar nucleosynthesis is the process of creating new elements through nuclear fusion in stars."),
        QuizQuestion(id: UUID(), question: "What is the most common type of star in the Milky Way?", options: ["Yellow dwarf", "Red dwarf", "Blue giant", "White dwarf"], correctAnswer: 1, difficulty: .hard, category: .stars, explanation: "Red dwarfs make up about 75% of all stars in the Milky Way galaxy."),
        
        QuizQuestion(id: UUID(), question: "What is the name of our galaxy?", options: ["Andromeda", "Milky Way", "Triangulum", "Whirlpool"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "We live in the Milky Way galaxy, containing 100-400 billion stars."),
        QuizQuestion(id: UUID(), question: "What shape is the Milky Way?", options: ["Elliptical", "Irregular", "Spiral", "Ring"], correctAnswer: 2, difficulty: .easy, category: .galaxies, explanation: "The Milky Way is a barred spiral galaxy with distinct spiral arms."),
        QuizQuestion(id: UUID(), question: "What is a galaxy?", options: ["A single star", "A collection of stars and matter", "A planet system", "A nebula"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "A galaxy is a massive collection of stars, gas, dust, and dark matter held together by gravity."),
        QuizQuestion(id: UUID(), question: "What is the nearest major galaxy to the Milky Way?", options: ["Triangulum", "Andromeda", "Sombrero", "Whirlpool"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "The Andromeda Galaxy is the nearest major galaxy, about 2.5 million light-years away."),
        QuizQuestion(id: UUID(), question: "What are the three main types of galaxies?", options: ["Big, medium, small", "Spiral, elliptical, irregular", "Young, middle, old", "Hot, warm, cold"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "Galaxies are classified as spiral, elliptical, or irregular based on their shape."),
        QuizQuestion(id: UUID(), question: "What holds galaxies together?", options: ["Magnetism", "Gravity", "Light", "Heat"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "Gravity holds galaxies together, including the gravitational effect of dark matter."),
        QuizQuestion(id: UUID(), question: "What is the band of light across the night sky?", options: ["Aurora", "Milky Way", "Zodiac", "Ecliptic"], correctAnswer: 1, difficulty: .easy, category: .galaxies, explanation: "The band of light is our edge-on view of the Milky Way galaxy."),
        QuizQuestion(id: UUID(), question: "Which galaxy is closest to the Milky Way?", options: ["Andromeda", "Triangulum", "Canis Major Dwarf", "Sagittarius Dwarf"], correctAnswer: 2, difficulty: .medium, category: .galaxies, explanation: "The Canis Major Dwarf Galaxy is closest at about 25,000 light-years from Earth."),
        QuizQuestion(id: UUID(), question: "Approximately how many galaxies are in the observable universe?", options: ["100 million", "2 billion", "200 billion", "2 trillion"], correctAnswer: 2, difficulty: .medium, category: .galaxies, explanation: "Recent estimates suggest there are about 200 billion galaxies in the observable universe."),
        QuizQuestion(id: UUID(), question: "What is a quasar?", options: ["A type of star", "An active galactic nucleus", "A black hole", "A nebula"], correctAnswer: 1, difficulty: .medium, category: .galaxies, explanation: "A quasar is an extremely luminous active galactic nucleus powered by a supermassive black hole."),
        QuizQuestion(id: UUID(), question: "What is the Local Group?", options: ["Nearby stars", "A cluster of galaxies", "Solar system planets", "Asteroid belt"], correctAnswer: 1, difficulty: .medium, category: .galaxies, explanation: "The Local Group is a cluster of over 80 galaxies including the Milky Way and Andromeda."),
        QuizQuestion(id: UUID(), question: "What will happen to the Milky Way and Andromeda?", options: ["Nothing", "They will collide", "They will move apart", "One will destroy the other"], correctAnswer: 1, difficulty: .medium, category: .galaxies, explanation: "The Milky Way and Andromeda are expected to collide in about 4.5 billion years."),
        QuizQuestion(id: UUID(), question: "What is dark matter?", options: ["Black holes", "Invisible matter affecting gravity", "Empty space", "Antimatter"], correctAnswer: 1, difficulty: .medium, category: .galaxies, explanation: "Dark matter is invisible matter that doesn't emit light but affects galaxies through gravity."),
        QuizQuestion(id: UUID(), question: "What percentage of the universe is dark matter?", options: ["5%", "27%", "68%", "95%"], correctAnswer: 1, difficulty: .medium, category: .galaxies, explanation: "Dark matter makes up about 27% of the universe's total mass-energy content."),
        QuizQuestion(id: UUID(), question: "What is a galaxy cluster?", options: ["A type of star", "Hundreds of galaxies bound by gravity", "A nebula", "A constellation"], correctAnswer: 1, difficulty: .hard, category: .galaxies, explanation: "A galaxy cluster contains hundreds to thousands of galaxies bound together by gravity."),
        QuizQuestion(id: UUID(), question: "What is the largest known structure in the universe?", options: ["Milky Way", "Hercules-Corona Borealis Great Wall", "Andromeda", "Virgo Supercluster"], correctAnswer: 1, difficulty: .hard, category: .galaxies, explanation: "The Hercules-Corona Borealis Great Wall is the largest known structure, spanning 10 billion light-years."),
        QuizQuestion(id: UUID(), question: "What is a starburst galaxy?", options: ["A dying galaxy", "A galaxy with rapid star formation", "A galaxy without stars", "A colliding galaxy"], correctAnswer: 1, difficulty: .hard, category: .galaxies, explanation: "A starburst galaxy is undergoing an exceptionally high rate of star formation."),
        QuizQuestion(id: UUID(), question: "What is the cosmic web?", options: ["A type of nebula", "Large-scale structure of the universe", "A black hole network", "Dark matter threads"], correctAnswer: 1, difficulty: .hard, category: .galaxies, explanation: "The cosmic web is the large-scale structure of the universe, with galaxies along filaments."),
        QuizQuestion(id: UUID(), question: "What is a Seyfert galaxy?", options: ["A spiral galaxy with an active core", "An elliptical galaxy", "A dwarf galaxy", "A dead galaxy"], correctAnswer: 0, difficulty: .hard, category: .galaxies, explanation: "A Seyfert galaxy is a spiral galaxy with an extremely bright, active galactic nucleus."),
        QuizQuestion(id: UUID(), question: "How fast is the Milky Way moving through space?", options: ["100 km/s", "370 km/s", "600 km/s", "1000 km/s"], correctAnswer: 2, difficulty: .hard, category: .galaxies, explanation: "The Milky Way moves at about 600 km/s relative to the cosmic microwave background."),
        
        QuizQuestion(id: UUID(), question: "Who was the first human in space?", options: ["Neil Armstrong", "Yuri Gagarin", "John Glenn", "Buzz Aldrin"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "Yuri Gagarin became the first human in space on April 12, 1961."),
        QuizQuestion(id: UUID(), question: "What year did humans first land on the Moon?", options: ["1965", "1967", "1969", "1971"], correctAnswer: 2, difficulty: .easy, category: .exploration, explanation: "Apollo 11 landed on the Moon on July 20, 1969."),
        QuizQuestion(id: UUID(), question: "What is the name of NASA's most famous space telescope?", options: ["Kepler", "Hubble", "Spitzer", "Chandra"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "The Hubble Space Telescope, launched in 1990, revolutionized our understanding of the universe."),
        QuizQuestion(id: UUID(), question: "What was the first artificial satellite?", options: ["Explorer 1", "Sputnik 1", "Vanguard 1", "Luna 1"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "Sputnik 1, launched by the Soviet Union in 1957, was the first artificial satellite."),
        QuizQuestion(id: UUID(), question: "Who was the first American in space?", options: ["John Glenn", "Alan Shepard", "Neil Armstrong", "Buzz Aldrin"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "Alan Shepard became the first American in space on May 5, 1961."),
        QuizQuestion(id: UUID(), question: "What is the International Space Station?", options: ["A satellite", "A space laboratory", "A rocket", "A telescope"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "The ISS is a modular space station and research laboratory orbiting Earth."),
        QuizQuestion(id: UUID(), question: "Which country launched the first human into space?", options: ["USA", "Soviet Union", "China", "Germany"], correctAnswer: 1, difficulty: .easy, category: .exploration, explanation: "The Soviet Union launched Yuri Gagarin, the first human in space, in 1961."),
        QuizQuestion(id: UUID(), question: "Which spacecraft left the Solar System first?", options: ["Pioneer 10", "Voyager 1", "Voyager 2", "New Horizons"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "Voyager 1 became the first human-made object to enter interstellar space in 2012."),
        QuizQuestion(id: UUID(), question: "What was the first rover on Mars?", options: ["Spirit", "Opportunity", "Sojourner", "Curiosity"], correctAnswer: 2, difficulty: .medium, category: .exploration, explanation: "Sojourner was the first rover on Mars, part of the Mars Pathfinder mission in 1997."),
        QuizQuestion(id: UUID(), question: "What is the James Webb Space Telescope primarily designed to observe?", options: ["X-rays", "Infrared light", "Visible light", "Radio waves"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "JWST is designed to observe infrared light from distant galaxies and early universe."),
        QuizQuestion(id: UUID(), question: "How long did the Apollo missions take to reach the Moon?", options: ["1 day", "3 days", "7 days", "14 days"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "Apollo missions took about 3 days to travel from Earth to the Moon."),
        QuizQuestion(id: UUID(), question: "What is SpaceX's reusable rocket called?", options: ["Atlas V", "Falcon 9", "Delta IV", "Ariane 5"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "Falcon 9 is SpaceX's partially reusable rocket used for cargo and crew missions."),
        QuizQuestion(id: UUID(), question: "Which spacecraft first landed on a comet?", options: ["Rosetta", "Philae", "Stardust", "Deep Impact"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "Philae, part of the Rosetta mission, was the first spacecraft to land on a comet in 2014."),
        QuizQuestion(id: UUID(), question: "What is the farthest human-made object from Earth?", options: ["Pioneer 10", "Voyager 1", "Voyager 2", "New Horizons"], correctAnswer: 1, difficulty: .medium, category: .exploration, explanation: "Voyager 1 is the farthest human-made object, over 14 billion miles from Earth."),
        QuizQuestion(id: UUID(), question: "What year was the Hubble Space Telescope launched?", options: ["1985", "1990", "1995", "2000"], correctAnswer: 1, difficulty: .hard, category: .exploration, explanation: "Hubble was launched on April 24, 1990, aboard the Space Shuttle Discovery."),
        QuizQuestion(id: UUID(), question: "What is the Artemis program?", options: ["Mars mission", "Moon return mission", "Space station", "Telescope"], correctAnswer: 1, difficulty: .hard, category: .exploration, explanation: "Artemis is NASA's program to return humans to the Moon and establish sustainable presence."),
        QuizQuestion(id: UUID(), question: "Which probe first visited Pluto?", options: ["Voyager 1", "Pioneer 10", "New Horizons", "Cassini"], correctAnswer: 2, difficulty: .hard, category: .exploration, explanation: "New Horizons flew by Pluto in July 2015, providing the first close-up images."),
        QuizQuestion(id: UUID(), question: "What is the Lagrange point L2?", options: ["A point on Mars", "A stable orbital point", "A type of rocket", "A space station"], correctAnswer: 1, difficulty: .hard, category: .exploration, explanation: "L2 is a gravitationally stable point where JWST orbits, 1.5 million km from Earth."),
        QuizQuestion(id: UUID(), question: "What was the first space station?", options: ["Mir", "Skylab", "Salyut 1", "ISS"], correctAnswer: 2, difficulty: .hard, category: .exploration, explanation: "Salyut 1, launched by the Soviet Union in 1971, was the first space station."),
        QuizQuestion(id: UUID(), question: "How many people have walked on the Moon?", options: ["6", "12", "18", "24"], correctAnswer: 1, difficulty: .hard, category: .exploration, explanation: "12 astronauts have walked on the Moon during the Apollo program (1969-1972)."),
        
        QuizQuestion(id: UUID(), question: "What is a black hole?", options: ["An empty region of space", "A collapsed massive star", "A type of galaxy", "A dark nebula"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "A black hole is a region where gravity is so strong that nothing can escape."),
        QuizQuestion(id: UUID(), question: "What is the boundary of a black hole called?", options: ["Singularity", "Event Horizon", "Accretion Disk", "Photon Sphere"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "The event horizon is the boundary beyond which nothing can escape a black hole."),
        QuizQuestion(id: UUID(), question: "Can light escape from a black hole?", options: ["Yes", "No", "Sometimes", "Only X-rays"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "No, not even light can escape from within a black hole's event horizon."),
        QuizQuestion(id: UUID(), question: "Who first predicted black holes?", options: ["Newton", "Einstein", "Hawking", "Schwarzschild"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "Einstein's theory of general relativity predicted the existence of black holes."),
        QuizQuestion(id: UUID(), question: "What happens to time near a black hole?", options: ["Speeds up", "Slows down", "Stops", "Reverses"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "Time slows down near a black hole due to gravitational time dilation."),
        QuizQuestion(id: UUID(), question: "What is the disk of matter around a black hole called?", options: ["Event horizon", "Singularity", "Accretion disk", "Corona"], correctAnswer: 2, difficulty: .easy, category: .blackHoles, explanation: "An accretion disk is the disk of gas and matter spiraling into a black hole."),
        QuizQuestion(id: UUID(), question: "What size are stellar black holes?", options: ["Planet-sized", "A few km across", "Sun-sized", "Galaxy-sized"], correctAnswer: 1, difficulty: .easy, category: .blackHoles, explanation: "Stellar black holes are typically only a few kilometers in diameter."),
        QuizQuestion(id: UUID(), question: "What is at the center of most galaxies?", options: ["A bright star", "A supermassive black hole", "A neutron star", "Nothing"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Most galaxies have supermassive black holes at their centers."),
        QuizQuestion(id: UUID(), question: "What is Hawking radiation?", options: ["Light from black holes", "Radiation escaping black holes", "X-rays from stars", "Cosmic rays"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Hawking radiation is theoretical radiation emitted by black holes due to quantum effects."),
        QuizQuestion(id: UUID(), question: "What creates a stellar black hole?", options: ["Planetary collision", "Supernova explosion", "Galaxy merger", "Nebula collapse"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Stellar black holes form when massive stars collapse after a supernova explosion."),
        QuizQuestion(id: UUID(), question: "What is spaghettification?", options: ["A cooking term", "Stretching by black hole gravity", "A type of nebula", "Star formation"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Spaghettification is the stretching of objects by extreme tidal forces near a black hole."),
        QuizQuestion(id: UUID(), question: "How do we detect black holes?", options: ["Direct observation", "Effects on nearby matter", "Sound waves", "Smell"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Black holes are detected by observing their effects on nearby stars and matter."),
        QuizQuestion(id: UUID(), question: "What is a primordial black hole?", options: ["Ancient black hole from Big Bang", "A dying black hole", "A small star", "A neutron star"], correctAnswer: 0, difficulty: .medium, category: .blackHoles, explanation: "Primordial black holes theoretically formed in the early universe shortly after the Big Bang."),
        QuizQuestion(id: UUID(), question: "Can black holes merge?", options: ["No", "Yes", "Only small ones", "Only large ones"], correctAnswer: 1, difficulty: .medium, category: .blackHoles, explanation: "Yes, black holes can merge, creating gravitational waves detected by LIGO."),
        QuizQuestion(id: UUID(), question: "What is the name of the black hole at the center of the Milky Way?", options: ["Cygnus X-1", "Sagittarius A*", "M87*", "TON 618"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "Sagittarius A* is a supermassive black hole with about 4 million solar masses."),
        QuizQuestion(id: UUID(), question: "What was the first black hole ever imaged?", options: ["Sagittarius A*", "M87*", "Cygnus X-1", "V404 Cygni"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "M87* was the first black hole directly imaged by the Event Horizon Telescope in 2019."),
        QuizQuestion(id: UUID(), question: "What is the Schwarzschild radius?", options: ["Black hole rotation speed", "Event horizon radius", "Accretion disk size", "Singularity size"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "The Schwarzschild radius defines the size of the event horizon for a non-rotating black hole."),
        QuizQuestion(id: UUID(), question: "What is a quasar powered by?", options: ["Nuclear fusion", "Supermassive black hole", "Neutron star", "White dwarf"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "Quasars are powered by supermassive black holes actively consuming matter."),
        QuizQuestion(id: UUID(), question: "What is the information paradox?", options: ["Missing data from telescopes", "Conflict between quantum mechanics and black holes", "Lost satellite signals", "Dark matter mystery"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "The information paradox questions whether information is destroyed in black holes."),
        QuizQuestion(id: UUID(), question: "What is a Kerr black hole?", options: ["A non-rotating black hole", "A rotating black hole", "A binary black hole", "A mini black hole"], correctAnswer: 1, difficulty: .hard, category: .blackHoles, explanation: "A Kerr black hole is a rotating black hole with angular momentum."),
        
        QuizQuestion(id: UUID(), question: "How many moons does Earth have?", options: ["0", "1", "2", "3"], correctAnswer: 1, difficulty: .easy, category: .moons, explanation: "Earth has one natural satellite, simply called the Moon or Luna."),
        QuizQuestion(id: UUID(), question: "Which planet has the most moons?", options: ["Jupiter", "Saturn", "Uranus", "Neptune"], correctAnswer: 1, difficulty: .easy, category: .moons, explanation: "Saturn has the most known moons with over 140 confirmed satellites."),
        QuizQuestion(id: UUID(), question: "What is the largest moon in the Solar System?", options: ["Titan", "Europa", "Ganymede", "Callisto"], correctAnswer: 2, difficulty: .easy, category: .moons, explanation: "Ganymede, a moon of Jupiter, is the largest moon in our Solar System."),
        QuizQuestion(id: UUID(), question: "How many moons does Mars have?", options: ["0", "1", "2", "4"], correctAnswer: 2, difficulty: .easy, category: .moons, explanation: "Mars has two small moons: Phobos and Deimos."),
        QuizQuestion(id: UUID(), question: "What are the names of Mars' moons?", options: ["Io and Europa", "Phobos and Deimos", "Titan and Rhea", "Triton and Nereid"], correctAnswer: 1, difficulty: .easy, category: .moons, explanation: "Mars' two moons are named Phobos (Fear) and Deimos (Terror)."),
        QuizQuestion(id: UUID(), question: "Which moon is known for its geysers?", options: ["Europa", "Enceladus", "Titan", "Io"], correctAnswer: 1, difficulty: .easy, category: .moons, explanation: "Enceladus, a moon of Saturn, has spectacular ice geysers at its south pole."),
        QuizQuestion(id: UUID(), question: "What causes the Moon's phases?", options: ["Earth's shadow", "Sun's position", "Moon's orbit around Earth", "Cloud cover"], correctAnswer: 2, difficulty: .easy, category: .moons, explanation: "Moon phases are caused by the Moon's changing position relative to Earth and Sun."),
        QuizQuestion(id: UUID(), question: "Which moon has a thick atmosphere?", options: ["Europa", "Ganymede", "Titan", "Io"], correctAnswer: 2, difficulty: .medium, category: .moons, explanation: "Titan has a thick nitrogen-rich atmosphere denser than Earth's."),
        QuizQuestion(id: UUID(), question: "Which moon has active volcanoes?", options: ["Europa", "Io", "Callisto", "Triton"], correctAnswer: 1, difficulty: .medium, category: .moons, explanation: "Io is the most volcanically active body in our Solar System."),
        QuizQuestion(id: UUID(), question: "What is special about Triton's orbit?", options: ["It's circular", "It's retrograde", "It's very fast", "It's tilted"], correctAnswer: 1, difficulty: .medium, category: .moons, explanation: "Triton orbits Neptune in a retrograde direction, opposite to Neptune's rotation."),
        QuizQuestion(id: UUID(), question: "Which moon has methane lakes?", options: ["Europa", "Ganymede", "Titan", "Enceladus"], correctAnswer: 2, difficulty: .medium, category: .moons, explanation: "Titan is the only moon known to have stable liquid lakes, made of methane and ethane."),
        QuizQuestion(id: UUID(), question: "What are Jupiter's four largest moons called?", options: ["Jovian moons", "Galilean moons", "Giant moons", "Classical moons"], correctAnswer: 1, difficulty: .medium, category: .moons, explanation: "The Galilean moons (Io, Europa, Ganymede, Callisto) were discovered by Galileo in 1610."),
        QuizQuestion(id: UUID(), question: "How was Earth's Moon likely formed?", options: ["Captured asteroid", "Giant impact", "Same time as Earth", "Comet collision"], correctAnswer: 1, difficulty: .medium, category: .moons, explanation: "The Moon likely formed from debris after a Mars-sized object hit early Earth."),
        QuizQuestion(id: UUID(), question: "Which moon has ice volcanoes?", options: ["Io", "Titan", "Triton", "Europa"], correctAnswer: 2, difficulty: .medium, category: .moons, explanation: "Triton has cryovolcanoes that erupt nitrogen ice instead of lava."),
        QuizQuestion(id: UUID(), question: "Which moon likely has a subsurface ocean?", options: ["Phobos", "Deimos", "Europa", "Miranda"], correctAnswer: 2, difficulty: .hard, category: .moons, explanation: "Europa is believed to have a global ocean beneath its icy crust."),
        QuizQuestion(id: UUID(), question: "What is tidal locking?", options: ["Ocean tides", "Moon always showing same face", "Orbit synchronization", "Gravitational waves"], correctAnswer: 1, difficulty: .hard, category: .moons, explanation: "Tidal locking means a moon's rotation matches its orbital period, showing one face."),
        QuizQuestion(id: UUID(), question: "Which moon orbits backwards around its planet?", options: ["Titan", "Triton", "Phobos", "Europa"], correctAnswer: 1, difficulty: .hard, category: .moons, explanation: "Triton orbits Neptune in a retrograde direction, suggesting it was captured."),
        QuizQuestion(id: UUID(), question: "What moon has the highest known cliffs in the Solar System?", options: ["Miranda", "Titan", "Io", "Ganymede"], correctAnswer: 0, difficulty: .hard, category: .moons, explanation: "Miranda has Verona Rupes, a cliff about 20 km high, the tallest known in the Solar System."),
        QuizQuestion(id: UUID(), question: "Which moon is slowly spiraling toward its planet?", options: ["The Moon", "Phobos", "Titan", "Triton"], correctAnswer: 1, difficulty: .hard, category: .moons, explanation: "Phobos is gradually spiraling inward and will crash into Mars in about 50 million years."),
        QuizQuestion(id: UUID(), question: "What is the Roche limit?", options: ["Moon size limit", "Distance where moons break apart", "Orbit speed", "Atmosphere boundary"], correctAnswer: 1, difficulty: .hard, category: .moons, explanation: "The Roche limit is the distance within which tidal forces would break apart a moon."),
    ]
    
    static func getQuestions(count: Int, difficulty: QuizQuestion.Difficulty? = nil, category: QuizQuestion.SpaceCategory? = nil) -> [QuizQuestion] {
        var filtered = questions
        if let diff = difficulty { filtered = filtered.filter { $0.difficulty == diff } }
        if let cat = category { filtered = filtered.filter { $0.category == cat } }
        return Array(filtered.shuffled().prefix(count))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
