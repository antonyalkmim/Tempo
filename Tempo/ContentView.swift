//
//  ContentView.swift
//  Tempo
//
//  Created by Antony Nelson Daudt Alkmin on 22/04/24.
//

import AVFAudio
import SwiftUI

struct ContentView: View {

    @ObservedObject var countdownWatch = CountdownWatch()
    @State private var isTimerConfigurationVisible = false
    @State private var shakingTimes = 0

    var body: some View {

        VStack {
            HStack {
                Spacer()
                Button("", systemImage: "timer") {
                    isTimerConfigurationVisible = true
                }
                .font(.title)
                .foregroundColor(.green)
                .popover(
                    isPresented: $isTimerConfigurationVisible,
                    attachmentAnchor: .point(.center),
                    arrowEdge: .bottom
                ) {
                    TimerConfigurationView { timeInterval in
                        countdownWatch.setTimeInterval(timeInterval)
                        isTimerConfigurationVisible = false
                    }
                    .presentationCompactAdaptation(.none)
                }
            }
            Spacer()

            TimerView(date: countdownWatch.date)
                .modifier(Shake(animatableData: CGFloat(shakingTimes)))

            Spacer()
            HStack {
                Button {
                    countdownWatch.stop()
                } label: {
                    Spacer()
                    Image(systemName: "stop.fill")
                        .frame(height: 40)
                    Spacer()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                if countdownWatch.isPaused {
                    Button {
                        countdownWatch.resume()
                    } label: {
                        Spacer()
                        Image(systemName: "playpause.fill")
                            .frame(height: 40)
                        Spacer()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button {
                        countdownWatch.start()
                    } label: {
                        Spacer()
                        Image(systemName: "play.fill")
                            .frame(height: 40)
                        Spacer()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button {
                    countdownWatch.pause()
                } label: {
                    Spacer()
                    Image(systemName: "pause.fill")
                        .frame(height: 40)
                    Spacer()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(countdownWatch.isPaused)
            }
        }
        .padding()
        .onChange(of: countdownWatch.hashFinished, perform: { finished in
            if finished {
                withAnimation(.bouncy) {
                    shakingTimes = 12
                }
            }
        })
    }

}

struct TimerConfigurationView: View {

    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0

    private let onFinishSelectTimeInterval: (TimeInterval) -> Void

    init(
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        onFinishSelectTimeInterval: @escaping (TimeInterval) -> Void
    ) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.onFinishSelectTimeInterval = onFinishSelectTimeInterval
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Selecione o tempo:")
                .font(.headline)

            HStack {
                Picker("", selection: $hours) {
                    ForEach(0...59, id: \.self) {
                        Text("\($0)").id($0)
                    }
                }
                .pickerStyle(.wheel)
                Text(":")
                Picker("", selection: $minutes) {
                    ForEach(0...59, id: \.self) {
                        Text("\($0)").id($0)
                    }
                }
                .pickerStyle(.wheel)
                Text(":")
                Picker("", selection: $seconds) {
                    ForEach(0...59, id: \.self) {
                        Text("\($0)").id($0)
                    }
                }
                .pickerStyle(.wheel)
            }

            Button(action: {
                let interval = TimeInterval((hours * 60 * 60) + (minutes * 60) + seconds)
                onFinishSelectTimeInterval(interval)
            }, label: {
                Spacer()
                Text("OK")
                Spacer()
            })
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct TimerView: View {

    let date: Date

    var body: some View {
        HStack {
            Text(date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).withTimeZone(.gmt))
            Text(":")
                .font(.dsDigital(size: 60))
            Text(date, format: .dateTime.minute(.twoDigits).withTimeZone(.gmt))
            Text(":")
                .font(.dsDigital(size: 60))
            Text(date, format: .dateTime.second(.twoDigits).withTimeZone(.gmt))
        }
        .lineLimit(1)
        .font(.dsDigital(size: 300))
        .minimumScaleFactor(0.3)
        .foregroundColor(.green)
    }
}

class CountdownWatch: ObservableObject {

    @Published var date: Date = .init(timeIntervalSince1970: 0)
    @Published var isPaused = false
    @Published var hashFinished = false

    private var timeInterval: TimeInterval = 0
    private var timer = Timer()
    private var player: AVAudioPlayer?

    private var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = .gmt
        return calendar
    }()

    private func checkCountdownFinished() {
        let seconds = calendar.component(.second, from: date)
        let minutes = calendar.component(.minute, from: date)
        let hours = calendar.component(.hour, from: date)

        if seconds == 0, minutes == 0, hours == 0 {
            stop()
            playAlarm()
            hashFinished = true
            date = .init(timeIntervalSince1970: timeInterval)
        }
    }

    private func playAlarm() {
        print("playing")

        guard let soundFileURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: soundFileURL)
            player?.play()
        } catch {
            print("Could not play any sound", error)
        }
    }

    func setTimeInterval(_ timeInterval: TimeInterval) {
        stop()
        self.timeInterval = timeInterval
        date = .init(timeIntervalSince1970: timeInterval)
    }

    func start() {
        date = .init(timeIntervalSince1970: timeInterval)
        hashFinished = false
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self, !self.isPaused else { return }
            self.date = calendar.date(byAdding: .second, value: -1, to: self.date) ?? .now
            checkCountdownFinished()
        }
    }

    func stop() {
        timer.invalidate()
        isPaused = false
        date = .init(timeIntervalSince1970: 0)
        player?.stop()
    }
    
    func reset() {
        date = .now
        timer.invalidate()
        player?.stop()
    }

    func pause() {
        isPaused = true
        player?.stop()
    }

    func resume() {
        hashFinished = false
        isPaused = false
    }

}

#Preview {
    ContentView()
}
