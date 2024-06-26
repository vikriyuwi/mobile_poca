import SwiftUI
import UserNotifications

class TimerManager: ObservableObject {
    @Published var timeString: String = "00:00"
    @Published var stepPomodoro:Int = 0
    
    @Published var durationWork:Double = 1500
    @Published var durationRest:Double = 300
    
    private var timer: Timer?
    private var endTime: Date?
    
    @Published var duration: TimeInterval = 0
    @Published var timerPhase: Int = 1
    
    @Published var remainingTime:TimeInterval = TimeInterval(30)
    @Published var orcaOffset:CGSize = CGSize(width: 0, height: 200)
    

    func start(duration: TimeInterval) {
        self.duration = duration
        endTime = Date().addingTimeInterval(duration)
        updateTimerString()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimerString()
        }
        scheduleNotification()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        timeString = formatTime(duration)
        endTime = nil
        removeNotification()
    }
    
    func startPomodoro() {
        // set timer manager
        if stepPomodoro % 2 == 1 {
            remainingTime = TimeInterval(durationWork)
            start(duration: TimeInterval(durationWork))
        } else {
            remainingTime = TimeInterval(durationRest)
            start(duration: TimeInterval(durationRest))
        }
    }
    
    func stopPomodoro() {
        // stop timer
        stop()
        
        // reset pomodoro
        stepPomodoro = 0
        timerPhase = 0
        
        // do animation
        withAnimation(Animation.spring(duration: 1)) {
            orcaOffset = CGSize(width: 0, height: 200)
        }
    }
    
    func nextPomodoro() {
        // stop timer
        stop()
        
        // add step pomodoro
        stepPomodoro += 1
        
        // start pomodoro with interval based on step pomodoro
        if stepPomodoro % 2 == 1 {
            // work step
            timerPhase = 1
            duration = TimeInterval(durationWork)
        } else {
            // rest step
            timerPhase = 2
            duration = TimeInterval(durationRest)
        }
        
        // do animation
        withAnimation(Animation.spring(duration: 1)) {
            orcaOffset = CGSize(width: 0, height: 200)
        }
    }
    
    func skipPhase() {
        // stop timer
        stop()
        
        timerPhase = 3
        
        // do animation
        withAnimation(Animation.spring(duration: 1)) {
            orcaOffset = CGSize(width: 0, height: 26)
        }
    }

    private func updateTimerString() {
        guard let endTime = endTime else { return }

        remainingTime = endTime.timeIntervalSinceNow
        
        if remainingTime <= 0 {
            timeString = "00:00"
            timerPhase = 3
            withAnimation(Animation.spring(duration: 1)) {
                orcaOffset = CGSize(width: 0, height: 26)
            }
            WKInterfaceDevice.current().play(.success)
            stop()
            // if stopped
        } else {
            timeString = formatTime(remainingTime)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Ended"
        content.body = "Your countdown timer has finished."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: "TimerNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleNotification2() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Ended"
        content.body = "Your countdown timer has finished."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(2), repeats: false)
        let request = UNNotificationRequest(identifier: "TimerNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    private func removeNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
}
