//
//  DialogScheduleService.swift
//  DialogSchedule
//
//  Created by Eugene Kurilenko on 1/23/17.
//  Copyright © 2017 Eugene Kurilenko. All rights reserved.
//

import Foundation


protocol DialogScheduleServiceDelegate: class {
    func shouldCreateNewDialog()
}

class DialogScheduleService {
    
    private let remainingTimeKey = "DialogScheduleServiceRemainingTimeKey"
    private let appEndTimeKey = "DialogScheduleServiceAppEndTimeKey"
    
    weak var delegate: DialogScheduleServiceDelegate?
    private var timer: Timer?
    private var time: TimeInterval?
    private let userDefaults = UserDefaults.standard
    
    
    init(with time: TimeInterval) {
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate),
                                               name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive, object: nil)
        
        self.time = time
        
    }
    // Start
    func start() {
        // Start timer if previous complited
        guard let restOfTime = restOfTime()
            else {
                startTimer(with: self.time!)
                return
        }
        // Start new timer if previous not complited
        // Show dialog if time is expired
        if restOfTime > 0 {
            startTimer(with: restOfTime)
        } else {
            timerDidEnd()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Strat timer with time interval
    private func startTimer(with timeInterval: TimeInterval) {
        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: self,
                                     selector: #selector(timerDidEnd),
                                     userInfo: nil, repeats: false)
    }
    
    // Affter timer has done
    @objc private func timerDidEnd() {
        
        delegate?.shouldCreateNewDialog()
        // Timer is ended, remove remain Time Interval
        userDefaults.removeObject(forKey: remainingTimeKey)
        userDefaults.removeObject(forKey: appEndTimeKey)
    }

    // MARK: Notifications
    @objc private func applicationWillTerminate() {
        
        // Save Remaining Time
        saveRemainingTime()
        // Invalidate curent timer
        timer?.invalidate()
    }
    
    @objc private func applicationDidEnterBackground() {
        
        // Save Remaining Time
        saveRemainingTime()
        // Invalidate curent timer
        timer?.invalidate()

    }
    
    @objc private func applicationDidBecomeActive() {
        // 
        guard let restOfTimeInterval = restOfTime() else { return }
        
        if restOfTimeInterval > 0 {
            startTimer(with: restOfTimeInterval)
        } else {
            timerDidEnd()
        }
        
    }
    
    // MARK: Private Methods
    
    // Calculate remaining time
    private func remainingTime() -> TimeInterval? {
        guard let timer = self.timer else { return nil }
        
        let fireDate = timer.fireDate
        let nowDate = NSDate()
        let remainingTime = -nowDate.timeIntervalSince(fireDate)
        return remainingTime
    }
    
    // Save Remaining TimeInterval
    private func saveRemainingTime() {
        let remainingTime = self.remainingTime()
        
        userDefaults.set(remainingTime, forKey: remainingTimeKey)
        userDefaults.set(Date(), forKey: appEndTimeKey)
        
    }
    
    // Rest of time interval from user defaults
    private func restOfTime() -> TimeInterval? {
        guard
            let restOfRemainingTime = userDefaults.value(forKey: remainingTimeKey) as? TimeInterval,
            let appEndTime = userDefaults.value(forKey: appEndTimeKey) as? Date
            else { return nil }
        
        let restOfAppEndTime = Date().timeIntervalSince(appEndTime)
        let newTime = restOfRemainingTime - restOfAppEndTime
        
        return newTime
    }

    
}
