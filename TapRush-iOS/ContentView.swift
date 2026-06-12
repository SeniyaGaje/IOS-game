import SwiftUI

private enum GameState {
    case ready
    case running
    case over
}

struct ContentView: View {
    private let roundLength: TimeInterval = 10
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @AppStorage("tap-rush-high-score") private var highScore = 0

    @State private var score = 0
    @State private var finalScore = 0
    @State private var secondsRemaining = 10
    @State private var gameState: GameState = .ready
    @State private var endTime = Date()
    @State private var resultMessage = "Try to beat your high score."
    @State private var isPressed = false

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

                    Text("Tap the button as many times as you can before the 10-second timer ends.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

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
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.66, green: 1.0, blue: 0.72),
                                            Color(red: 0.31, green: 0.83, blue: 0.42),
                                            Color(red: 0.08, green: 0.59, blue: 0.23)
                                        ],
                                        center: .topLeading,
                                        startRadius: 12,
                                        endRadius: 250
                                    )
                                )
                        )
                        .shadow(color: Color(red: 0.05, green: 0.39, blue: 0.15), radius: 0, x: 0, y: isPressed ? 6 : 16)
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
        HStack(spacing: 10) {
            StatBox(title: "Score", value: "\(score)")
            StatBox(title: "Time", value: "\(secondsRemaining)s", valueColor: .yellow)
            StatBox(title: "High Score", value: "\(highScore)")
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
            return "Keep tapping"
        case .over:
            return "Time is up"
        }
    }

    private func handleTap() {
        guard gameState != .over else {
            return
        }

        if gameState == .running && Date() >= endTime {
            finishRound()
            return
        }

        if gameState == .ready {
            startRound()
        }

        score += 1

        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            isPressed = false
        }
    }

    private func startRound() {
        gameState = .running
        endTime = Date().addingTimeInterval(roundLength)
        secondsRemaining = Int(roundLength)
    }

    private func updateTimer(now: Date) {
        guard gameState == .running else {
            return
        }

        let remaining = max(0, endTime.timeIntervalSince(now))
        secondsRemaining = Int(ceil(remaining))

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
