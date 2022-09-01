//
//  PlayerHandler.swift
//  App
//
//  Created by Rasmus Krämer on 11.04.22.
//

import Foundation
import RealmSwift

class PlayerHandler {
    private static var player: AudioPlayer?
    
    public static var sleepTimerChapterStopTime: Double? = nil
    
    public static func startPlayback(sessionId: String, playWhenReady: Bool, playbackRate: Float) {
        guard let session = Database.shared.getPlaybackSession(id: sessionId) else { return }
        
        // Clean up the existing player
        if player != nil {
            player?.destroy()
            player = nil
        }
        
        // Cleanup and sync old sessions
        cleanupOldSessions(currentSessionId: sessionId)
        Task { await PlayerProgress.shared.syncToServer() }
        
        // Set now playing info
        NowPlayingInfo.shared.setSessionMetadata(metadata: NowPlayingMetadata(id: session.id, itemId: session.libraryItemId!, artworkUrl: session.coverPath, title: session.displayTitle ?? "Unknown title", author: session.displayAuthor, series: nil))
        
        // Create the audio player
        player = AudioPlayer(sessionId: sessionId, playWhenReady: playWhenReady, playbackRate: playbackRate)
    }
    
    public static func stopPlayback() {
        // Pause playback first, so we can sync our current progress
        player?.pause()
        
        player?.destroy()
        player = nil
        
        cleanupOldSessions(currentSessionId: nil)
        
        NowPlayingInfo.shared.reset()
    }
    
    public static var paused: Bool {
        get {
            guard let player = player else { return true }
            return player.rate == 0.0
        }
        set(paused) {
            if paused {
                self.player?.pause()
            } else {
                self.player?.play()
            }
        }
    }
    
    public static var remainingSleepTime: Int? {
        get {
            guard let player = player else { return nil }
            guard let currentTime = player.getCurrentTime() else { return nil }
            
            // Return the player time until sleep
            var timeUntilSleep: Double? = nil
            if let sleepTimerChapterStopTime = sleepTimerChapterStopTime {
                timeUntilSleep = sleepTimerChapterStopTime - currentTime
            } else if let stopAt = player.getSleepStopAt() {
                timeUntilSleep = stopAt - currentTime
            }
            
            // Scale the time until sleep based on the playback rate
            if let timeUntilSleep = timeUntilSleep {
                // Consider paused as playing at 1x
                let rate = Double(player.rate > 0 ? player.rate : 1)
                
                let timeUntilSleepScaled = timeUntilSleep / rate
                guard timeUntilSleepScaled.isNaN == false else { return nil }
                
                return Int(timeUntilSleepScaled.rounded())
            } else {
                return nil
            }
        }
    }
    
    public static func getCurrentTime() -> Double? {
        self.player?.getCurrentTime()
    }
    
    public static func setPlaybackSpeed(speed: Float) {
        self.player?.setPlaybackRate(speed)
    }
    
    public static func setSleepTime(secondsUntilSleep: Double) {
        guard let player = player else { return }
        guard let currentTime = player.getCurrentTime() else { return }
        let stopAt = secondsUntilSleep + currentTime
        player.setSleepTime(stopAt: stopAt, scaleBasedOnSpeed: true)
    }
    
    public static func setChapterSleepTime(stopAt: Double) {
        guard let player = player else { return }
        player.setChapterSleepTime(stopAt: stopAt)
    }
    
    public static func increaseSleepTime(increaseSeconds: Double) {
        self.sleepTimerChapterStopTime = nil
        self.player?.increaseSleepTime(extraTimeInSeconds: increaseSeconds)
    }
    
    public static func decreaseSleepTime(decreaseSeconds: Double) {
        self.sleepTimerChapterStopTime = nil
        self.player?.decreaseSleepTime(removeTimeInSeconds: decreaseSeconds)
    }
    
    public static func cancelSleepTime() {
        PlayerHandler.sleepTimerChapterStopTime = nil
        self.player?.removeSleepTimer()
    }
    
    public static func getPlayMethod() -> Int? {
        self.player?.getPlayMethod()
    }
    
    public static func getPlaybackSession() -> PlaybackSession? {
        guard let player = player else { return nil }
        guard player.isInitialized() else { return nil }
        
        return Database.shared.getPlaybackSession(id: player.getPlaybackSessionId())
    }
    
    public static func seekForward(amount: Double) {
        guard let player = player else { return }
        guard let currentTime = player.getCurrentTime() else { return }
        
        let destinationTime = currentTime + amount
        player.seek(destinationTime, from: "handler")
    }
    
    public static func seekBackward(amount: Double) {
        guard let player = player else { return }
        guard let currentTime = player.getCurrentTime() else { return }
        
        let destinationTime = currentTime - amount
        player.seek(destinationTime, from: "handler")
    }
    
    public static func seek(amount: Double) {
        player?.seek(amount, from: "handler")
    }
    
    public static func getMetdata() -> [String: Any]? {
        guard let player = player else { return nil }
        guard player.isInitialized() else { return nil }
        
        return [
            "duration": player.getDuration(),
            "currentTime": player.getCurrentTime(),
            "playerState": !paused,
            "currentRate": player.rate,
        ]
    }
    
    // MARK: - Helper logic
    
    private static func cleanupOldSessions(currentSessionId: String?) {
        do {
            let realm = try Realm()
            let oldSessions = realm.objects(PlaybackSession.self) .where({
                $0.isActiveSession == true && $0.serverConnectionConfigId == Store.serverConfig?.id
            })
            try realm.write {
                for s in oldSessions {
                    if s.id != currentSessionId {
                        s.isActiveSession = false
                    }
                }
            }
        } catch {
            debugPrint("Failed to cleanup sessions")
            debugPrint(error)
        }
    }
}
