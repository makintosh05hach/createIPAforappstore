import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var soundEnabled = true
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }
    
    func playCorrect() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }
    
    func playWrong() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1053)
    }
    
    func playTap() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
    
    func playSuccess() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }
    
    func playCountdown() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1103)
    }
    
    func playAchievement() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1026)
    }
    
    func playButtonPress() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1306)
    }
    
    func playSwipe() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1105)
    }
}
