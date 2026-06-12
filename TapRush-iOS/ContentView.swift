import SwiftUI

private enum GameState {
    case ready
    case running
    case over
}

private enum TrapState {
    case bonus
    case penalty
}

struct ContentView: View {
    private let roundLength: TimeInterval = 10
    private let comboWindow: TimeInterval = 0.5
    private let trapInterval: TimeInterval = 2.5
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @AppStorage("tap-rush-high-score") private var highScore = 0

    @State private var score = 0
    @State private var finalScore = 0
    @State private var secondsRemaining = 10
    @State private var gameState: GameState = .ready
    @State private var endTime = Date()
    @State private var resultMessage = "Try to beat your high score."
    @State private var isPressed = false
    @State private var comboMultiplier = 1
    @State private var lastTapTime: Date?
    @State private var trapState: TrapState = .bonus
    @State private var nextTrapSwitchTime = Date()
    @State private var lastPoints = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.07),
                    Color(red: 0.09, green: 0.09, blue: 0.08),
                    Color(red: 0.07, green: 0.08, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                scoreBar

                Spacer(minLength: 12)

                VStack(spacing: 18) {
                    Text(statusText)
                        .font(.caption.weight(.black))
                        .tracking(2)
                        .foregroundStyle(.green)
                        .textCase(.uppercase)

                    Text("Tap Rush")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                        .foregroundStyle(.white)

                    Text("Tap quickly to build combo. Green gives double points, grey takes points away.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text(lastTapText)
                        .font(.headline.weight(.black))
                        .foregroundStyle(lastTapColor)
                        .frame(minHeight: 24)

                    Button(action: handleTap) {
                        VStack(spacing: 8) {
                            Text("TAP")
                                .font(.system(size: 68, weight: .black, design: .rounded))
                                .tracking(2)

                            Text(tapHint)
                                .font(.footnote.weight(.bold))
                                .multilineTextAlignment(.center)
                                .opacity(0.72)
                        }
                        .foregroundStyle(Color(red: 0.03, green: 0.07, blue: 0.04))
                        .frame(width: 255, height: 255)
                        .background(
                            Circle()
                                .fill(buttonGradient)
                        )
                        .shadow(color: buttonDepthColor, radius: 0, x: 0, y: isPressed ? 6 : 16)
                        .shadow(color: .black.opacity(0.38), radius: 26, x: 0, y: isPressed ? 14 : 24)
                        .scaleEffect(isPressed ? 0.97 : 1)
                        .offset(y: isPressed ? 9 : 0)
                        .animation(.spring(response: 0.16, dampingFraction: 0.75), value: isPressed)
                    }
                    .buttonStyle(.plain)
                    .disabled(gameState == .over)
                    .opacity(gameState == .over ? 0.6 : 1)
                    .accessibilityLabel("Tap button")
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(red: 0.10, green: 0.11, blue: 0.12).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

                Spacer(minLength: 12)
            }
            .padding()

            if gameState == .over {
                gameOverOverlay
            }
        }
        .onReceive(timer) { now in
            updateTimer(now: now)
        }
    }

    private var scoreBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatBox(title: "Score", value: "\(score)")
                StatBox(title: "Time", value: "\(secondsRemaining)s", valueColor: .yellow)
                StatBox(title: "High Score", value: "\(highScore)")
            }

            HStack(spacing: 10) {
                StatBox(title: "Combo", value: "x\(comboMultiplier)", valueColor: .green)
                StatBox(title: "Button", value: trapTitle, valueColor: trapTextColor)
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.green)
                    .textCase(.uppercase)

                Text("Time is up")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final score: \(finalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(resultMessage)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 28)

                Button("Play Again", action: resetRound)
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(Color(red: 0.09, green: 0.03, blue: 0.02))
                    .background(Color(red: 1.0, green: 0.44, blue: 0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(24)
            .frame(maxWidth: 390)
            .background(Color(red: 0.13, green: 0.15, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .padding()
        }
    }

    private var statusText: String {
        switch gameState {
        case .ready:
            return "Ready"
        case .running:
            return "Go"
        case .over:
            return "Finished"
        }
    }

    private var tapHint: String {
        switch gameState {
        case .ready:
            return "First tap starts the clock"
        case .running:
            return trapState == .bonus ? "Bonus x2" : "Penalty -combo"
        case .over:
            return "Time is up"
        }
    }

    private var trapTitle: String {
        trapState == .bonus ? "Bonus" : "Penalty"
    }

    private var trapTextColor: Color {
        trapState == .bonus ? .green : Color(red: 0.78, green: 0.80, blue: 0.82)
    }

    private var buttonGradient: RadialGradient {
        if trapState == .bonus {
            return RadialGradient(
                colors: [
                    Color(red: 0.66, green: 1.0, blue: 0.72),
                    Color(red: 0.31, green: 0.83, blue: 0.42),
                    Color(red: 0.08, green: 0.59, blue: 0.23)
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 250
            )
        }

        return RadialGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 0.98),
                Color(red: 0.65, green: 0.68, blue: 0.71),
                Color(red: 0.38, green: 0.42, blue: 0.45)
            ],
            center: .topLeading,
            startRadius: 12,
            endRadius: 250
        )
    }

    private var buttonDepthColor: Color {
        if trapState == .bonus {
            return Color(red: 0.05, green: 0.39, blue: 0.15)
        }

        return Color(red: 0.25, green: 0.27, blue: 0.30)
    }

    private var lastTapText: String {
        let sign = lastPoints > 0 ? "+" : ""
        return "Last tap: \(sign)\(lastPoints)"
    }

    private var lastTapColor: Color {
        if lastPoints > 0 {
            return .green
        }

        if lastPoints < 0 {
            return Color(red: 0.78, green: 0.80, blue: 0.82)
        }

        return .secondary
    }

    private func handleTap() {
        let now = Date()

        guard gameState != .over else {
            return
        }

        if gameState == .running && now >= endTime {
            finishRound()
            return
        }

        if gameState == .ready {
            startRound(now: now)
        }

        if let lastTapTime = lastTapTime, now.timeIntervalSince(lastTapTime) <= comboWindow {
            comboMultiplier += 1
        } else {
            comboMultiplier = 1
        }

        lastTapTime = now

        let points = trapState == .bonus ? comboMultiplier * 2 : -comboMultiplier
        score = max(0, score + points)
        lastPoints = points

        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            isPressed = false
        }
    }

    private func startRound(now: Date = Date()) {
        gameState = .running
        endTime = now.addingTimeInterval(roundLength)
        nextTrapSwitchTime = now.addingTimeInterval(trapInterval)
        trapState = .bonus
        lastTapTime = nil
        secondsRemaining = Int(roundLength)
    }

    private func updateTimer(now: Date) {
        guard gameState == .running else {
            return
        }

        let remaining = max(0, endTime.timeIntervalSince(now))
        secondsRemaining = Int(ceil(remaining))

        if let lastTapTime = lastTapTime, now.timeIntervalSince(lastTapTime) > comboWindow, comboMultiplier != 1 {
            comboMultiplier = 1
        }

        if now >= nextTrapSwitchTime {
            trapState = trapState == .bonus ? .penalty : .bonus
            nextTrapSwitchTime = now.addingTimeInterval(trapInterval)
        }

        if remaining <= 0 {
            finishRound()
        }
    }

    private func finishRound() {
        guard gameState != .over else {
            return
        }

        gameState = .over
        secondsRemaining = 0
        finalScore = score

        if score > highScore {
            highScore = score
            resultMessage = "New high score!"
        } else if score == highScore && score > 0 {
            resultMessage = "You matched your high score."
        } else {
            resultMessage = "Try to beat your high score."
        }
    }

    private func resetRound() {
        score = 0
        finalScore = 0
        secondsRemaining = Int(roundLength)
        gameState = .ready
        endTime = Date()
        resultMessage = "Try to beat your high score."
        isPressed = false
        comboMultiplier = 1
        lastTapTime = nil
        trapState = .bonus
        nextTrapSwitchTime = Date()
        lastPoints = 0
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.10, green: 0.11, blue: 0.12).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
