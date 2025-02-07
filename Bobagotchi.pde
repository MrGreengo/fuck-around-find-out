// Game states and variables
String currentWeather = "Sunny";
String currentMindState = "Seeking to relax";
float happiness = 100;
float hunger = 0;
String userInput = "";
String message = "";
long lastWeatherChange;
long lastMindStateChange;
long lastWeatherHappinessGrace;
long lastMindStateHappinessGrace;
boolean isWeatherGracePeriod = false;
boolean isMindStateGracePeriod = false;
boolean hasSunglasses = false;

// Array of possible weather conditions and mind states
String[] weatherConditions = {"Sunny", "Raining", "Snowing", "Nighttime"};
String[] mindStates = {"Seeking to relax", "Feeling creative", "Wanting to learn", "Bob has a job interview"};

void setup() {
  size(600, 600);
  textAlign(LEFT);
  lastWeatherChange = millis();
  lastMindStateChange = millis();
  lastWeatherHappinessGrace = millis();
  lastMindStateHappinessGrace = millis();
}

void draw() {
  background(220);
  updateGameStates();
  updateHappinessAndHunger();
  displayStats();
  drawFace();
  displayInput();
  checkGameOver();
}

void updateGameStates() {
  // Update weather every 30 seconds (changed from 60)
  if (millis() - lastWeatherChange >= 30000) {
    currentWeather = weatherConditions[int(random(weatherConditions.length))];
    lastWeatherChange = millis();
    lastWeatherHappinessGrace = millis();
    isWeatherGracePeriod = true;
    hasSunglasses = false;
  }
  
  // Update mind state every 20 seconds (changed from 45)
  if (millis() - lastMindStateChange >= 20000) {
    currentMindState = mindStates[int(random(mindStates.length))];
    lastMindStateChange = millis();
    lastMindStateHappinessGrace = millis();
    isMindStateGracePeriod = true;
  }
}

void updateHappinessAndHunger() {
  // Weather grace period check (10 seconds - changed from 20)
  if (isWeatherGracePeriod && millis() - lastWeatherHappinessGrace >= 10000) {
    isWeatherGracePeriod = false;
  }
  
  // Mind state grace period check (5 seconds - changed from 10)
  if (isMindStateGracePeriod && millis() - lastMindStateHappinessGrace >= 5000) {
    isMindStateGracePeriod = false;
  }
  
  // Update happiness - 40 per minute (doubled from 20)
  if (!isWeatherGracePeriod && !isMindStateGracePeriod) {
    happiness = max(0, happiness - (40.0/60.0)/frameRate);
  }
  
  // Update hunger - 20 per minute (doubled from 10)
  hunger = min(100, hunger + (20.0/60.0)/frameRate);
  
  // Extra happiness depletion when hungry - 10 per minute (doubled from 5)
  if (hunger >= 50) {
    happiness = max(0, happiness - (10.0/60.0)/frameRate);
  }
}

void drawFace() {
  // Draw face in the right side of the screen
  float faceX = 450;
  float faceY = 200;
  float faceSize = 100;
  
  // Head
  fill(255);
  stroke(0);
  ellipse(faceX, faceY, faceSize, faceSize);
  
  // Eyes
  if (hunger >= 100) {
    // X eyes when hunger maxes out
    stroke(0);
    line(faceX - 25, faceY - 15, faceX - 15, faceY - 5);
    line(faceX - 25, faceY - 5, faceX - 15, faceY - 15);
    line(faceX + 15, faceY - 15, faceX + 25, faceY - 5);
    line(faceX + 15, faceY - 5, faceX + 25, faceY - 15);
  } else if (hasSunglasses) {
    // Sunglasses
    fill(0);
    noStroke();
    rect(faceX - 25, faceY - 15, 15, 10);
    rect(faceX + 10, faceY - 15, 15, 10);
    stroke(0);
    line(faceX - 10, faceY - 10, faceX + 10, faceY - 10);
  } else {
    // Normal eyes
    fill(0);
    noStroke();
    ellipse(faceX - 20, faceY - 10, 10, 10);
    ellipse(faceX + 20, faceY - 10, 10, 10);
  }
  stroke(0);
  
  // Mouth - curves based on happiness
  noFill();
  float mouthCurve = map(happiness, 0, 100, -20, 20);
  beginShape();
  vertex(faceX - 30, faceY + 10);
  quadraticVertex(faceX, faceY + 10 + mouthCurve, faceX + 30, faceY + 10);
  endShape();
}

void displayStats() {
  fill(0);
  textSize(16);
  
  // Display current states
  text("Weather: " + currentWeather, 20, 30);
  text("Bob's State: " + currentMindState, 20, 60);
  
  // Display stats
  text("Happiness: " + nf(happiness, 0, 1), 20, 90);
  text("Hunger: " + nf(hunger, 0, 1), 20, 120);
  
  // Display Bob's possible things
  text("Bob's Things:", 20, 160);
  text("- tacos", 40, 190);
  text("- coat", 40, 210);
  text("- pillow", 40, 230);
  text("- umbrella", 40, 250);
  text("- tie", 40, 270);
  text("- boombox", 40, 290);
  text("- sunglasses", 40, 310);
  text("- piano", 40, 330);
  text("- book", 40, 350);
  
  // Display message
  fill(0, 102, 153);
  text(message, 20, 380);
}

String getWeatherNeed() {
  switch(currentWeather) {
    case "Snowing": return "coat";
    case "Nighttime": return "pillow";
    case "Raining": return "umbrella";
    case "Sunny": return "sunglasses";
    default: return "unknown";
  }
}

String getMindNeed() {
  switch(currentMindState) {
    case "Seeking to relax": return "boombox";
    case "Feeling creative": return "piano";
    case "Wanting to learn": return "book";
    case "Bob has a job interview": return "tie";
    default: return "unknown";
  }
}

void displayInput() {
  // Draw input box
  fill(255);
  rect(20, 500, 560, 40);
  fill(0);
  text("Give Bob: " + userInput, 30, 525);
}

void keyPressed() {
  if (key == ENTER || key == RETURN) {
    processInput();
  } else if (key == BACKSPACE && userInput.length() > 0) {
    userInput = userInput.substring(0, userInput.length() - 1);
  } else if (key != CODED) {
    userInput += key;
  }
}

void processInput() {
  String input = userInput.toLowerCase().trim();
  
  if (input.equals("tacos")) {
    hunger = max(0, hunger - 40);
    message = "You gave Bob tacos! Hunger decreased.";
  } else if (input.equals("sunglasses") && currentWeather.equals("Sunny")) {
    hasSunglasses = true;
    happiness = 100;
    message = "You gave Bob his sunglasses!";
  } else if ((input.equals(getWeatherNeed()) && !input.equals("sunglasses")) || input.equals(getMindNeed())) {
    happiness = 100;
    message = "You gave Bob his " + input + "!";
  } else {
    message = "Bob doesn't need that right now.";
  }
  
  userInput = "";  // Clear input
}

void checkGameOver() {
  if (happiness <= 0 || hunger >= 100) {
    background(0);
    fill(255);
    textSize(32);
    textAlign(CENTER);
    text("Game Over!", width/2, height/2);
    noLoop();
  }
}
