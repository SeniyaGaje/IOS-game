const ROUND_LENGTH_MS = 10000;
const HIGH_SCORE_KEY = "tap-rush-high-score";

const scoreElement = document.getElementById("score");
const timerElement = document.getElementById("timer");
const highScoreElement = document.getElementById("highScore");
const roundStateElement = document.getElementById("roundState");
const tapButton = document.getElementById("tapButton");
const tapHint = document.getElementById("tapHint");
const gameOverPanel = document.getElementById("gameOverPanel");
const finalScoreElement = document.getElementById("finalScore");
const highScoreMessage = document.getElementById("highScoreMessage");
const playAgainButton = document.getElementById("playAgainButton");

let score = 0;
let highScore = Number(localStorage.getItem(HIGH_SCORE_KEY)) || 0;
let gameState = "ready";
let endTime = 0;
let timerId = null;

function renderScore() {
  scoreElement.textContent = String(score);
  highScoreElement.textContent = String(highScore);
}

function renderTimer(seconds) {
  timerElement.textContent = String(seconds);
}

function startRound() {
  gameState = "running";
  endTime = Date.now() + ROUND_LENGTH_MS;
  roundStateElement.textContent = "Go";
  tapHint.textContent = "Keep tapping";
  renderTimer(10);

  timerId = window.setInterval(updateTimer, 100);
  updateTimer();
}

function updateTimer() {
  const remainingMs = Math.max(0, endTime - Date.now());
  const remainingSeconds = Math.ceil(remainingMs / 1000);

  renderTimer(remainingSeconds);

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
  timerId = null;
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
  if (gameState === "over") {
    return;
  }

  if (gameState === "running" && Date.now() >= endTime) {
    finishRound();
    return;
  }

  if (gameState === "ready") {
    startRound();
  }

  score += 1;
  renderScore();

  tapButton.classList.add("is-pressed");
  window.setTimeout(() => {
    tapButton.classList.remove("is-pressed");
  }, 90);
}

function resetRound() {
  window.clearInterval(timerId);
  timerId = null;
  score = 0;
  gameState = "ready";
  endTime = 0;

  tapButton.disabled = false;
  tapHint.textContent = "First tap starts the clock";
  roundStateElement.textContent = "Ready";
  gameOverPanel.hidden = true;

  renderScore();
  renderTimer(10);
  tapButton.focus();
}

tapButton.addEventListener("click", handleTap);
playAgainButton.addEventListener("click", resetRound);

renderScore();
renderTimer(10);
