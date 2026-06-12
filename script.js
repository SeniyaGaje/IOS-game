const ROUND_LENGTH_MS = 10000;
const COMBO_WINDOW_MS = 500;
const TRAP_INTERVAL_MS = 2500;
const HIGH_SCORE_KEY = "tap-rush-high-score";

const scoreElement = document.getElementById("score");
const timerElement = document.getElementById("timer");
const highScoreElement = document.getElementById("highScore");
const comboElement = document.getElementById("combo");
const trapStateElement = document.getElementById("trapState");
const roundStateElement = document.getElementById("roundState");
const tapButton = document.getElementById("tapButton");
const tapHint = document.getElementById("tapHint");
const pointFeedback = document.getElementById("pointFeedback");
const gameOverPanel = document.getElementById("gameOverPanel");
const finalScoreElement = document.getElementById("finalScore");
const highScoreMessage = document.getElementById("highScoreMessage");
const playAgainButton = document.getElementById("playAgainButton");

let score = 0;
let highScore = Number(localStorage.getItem(HIGH_SCORE_KEY)) || 0;
let gameState = "ready";
let endTime = 0;
let timerId = null;
let trapTimerId = null;
let comboMultiplier = 1;
let lastTapAt = 0;
let trapState = "bonus";

function renderScore() {
  scoreElement.textContent = String(score);
  highScoreElement.textContent = String(highScore);
}

function renderCombo() {
  comboElement.textContent = `x${comboMultiplier}`;
}

function renderTimer(seconds) {
  timerElement.textContent = String(seconds);
}

function renderTrapState() {
  const isBonus = trapState === "bonus";

  trapStateElement.textContent = isBonus ? "Bonus" : "Penalty";
  trapStateElement.classList.toggle("penalty-text", !isBonus);
  tapButton.classList.toggle("is-bonus", isBonus);
  tapButton.classList.toggle("is-penalty", !isBonus);

  if (gameState === "running") {
    tapHint.textContent = isBonus ? "Bonus x2" : "Penalty -combo";
  }
}

function switchTrapState() {
  trapState = trapState === "bonus" ? "penalty" : "bonus";
  renderTrapState();
}

function startRound() {
  gameState = "running";
  endTime = Date.now() + ROUND_LENGTH_MS;
  roundStateElement.textContent = "Go";
  lastTapAt = 0;
  trapState = "bonus";
  renderTimer(10);
  renderTrapState();

  timerId = window.setInterval(updateTimer, 100);
  trapTimerId = window.setInterval(switchTrapState, TRAP_INTERVAL_MS);
  updateTimer();
}

function updateTimer() {
  const now = Date.now();
  const remainingMs = Math.max(0, endTime - now);
  const remainingSeconds = Math.ceil(remainingMs / 1000);

  renderTimer(remainingSeconds);

  if (lastTapAt > 0 && now - lastTapAt > COMBO_WINDOW_MS && comboMultiplier !== 1) {
    comboMultiplier = 1;
    renderCombo();
  }

  if (remainingMs <= 0) {
    finishRound();
  }
}

function finishRound() {
  if (gameState === "over") {
    return;
  }

  gameState = "over";
  window.clearInterval(timerId);
  window.clearInterval(trapTimerId);
  timerId = null;
  trapTimerId = null;
  renderTimer(0);

  tapButton.disabled = true;
  tapHint.textContent = "Time is up";
  roundStateElement.textContent = "Finished";
  finalScoreElement.textContent = String(score);

  if (score > highScore) {
    highScore = score;
    localStorage.setItem(HIGH_SCORE_KEY, String(highScore));
    highScoreMessage.textContent = "New high score!";
  } else if (score === highScore && score > 0) {
    highScoreMessage.textContent = "You matched your high score.";
  } else {
    highScoreMessage.textContent = "Try to beat your high score.";
  }

  renderScore();
  gameOverPanel.hidden = false;
  playAgainButton.focus();
}

function handleTap() {
  const now = Date.now();

  if (gameState === "over") {
    return;
  }

  if (gameState === "running" && now >= endTime) {
    finishRound();
    return;
  }

  if (gameState === "ready") {
    startRound();
  }

  if (lastTapAt > 0 && now - lastTapAt <= COMBO_WINDOW_MS) {
    comboMultiplier += 1;
  } else {
    comboMultiplier = 1;
  }

  lastTapAt = now;

  const points = trapState === "bonus" ? comboMultiplier * 2 : -comboMultiplier;
  score = Math.max(0, score + points);
  pointFeedback.textContent = `Last tap: ${points > 0 ? "+" : ""}${points}`;
  pointFeedback.classList.toggle("is-penalty", points < 0);
  pointFeedback.classList.toggle("is-bonus", points > 0);

  renderScore();
  renderCombo();

  tapButton.classList.add("is-pressed");
  window.setTimeout(() => {
    tapButton.classList.remove("is-pressed");
  }, 90);
}

function resetRound() {
  window.clearInterval(timerId);
  window.clearInterval(trapTimerId);
  timerId = null;
  trapTimerId = null;
  score = 0;
  gameState = "ready";
  endTime = 0;
  comboMultiplier = 1;
  lastTapAt = 0;
  trapState = "bonus";

  tapButton.disabled = false;
  tapHint.textContent = "First tap starts the clock";
  roundStateElement.textContent = "Ready";
  pointFeedback.textContent = "Last tap: 0";
  pointFeedback.classList.remove("is-bonus", "is-penalty");
  gameOverPanel.hidden = true;

  renderScore();
  renderCombo();
  renderTimer(10);
  renderTrapState();
  tapButton.focus();
}

tapButton.addEventListener("click", handleTap);
playAgainButton.addEventListener("click", resetRound);

renderScore();
renderCombo();
renderTrapState();
renderTimer(10);
