import processing.video.*;

// Global variables for visual elements
ArrayList<Planet> planets;
Star[] stars;
Sun sun;
MissionPanel missionPanel;
int currentPlanet;
float activityTimer;
boolean inputComplete;
String inputBuffer;
float rocketX, rocketY;
float angle;
float t;
boolean transitioning;

// Camera variables
Capture cam;
boolean readyToCapture = false;
boolean showCaptureMessage = false;
int captureMessageTimer = 0;
String captureMessage = "";

// Constants
final color[] PLANET_COLORS = {
  color(255, 100, 100),  // Red - for high energy activities
  color(100, 255, 100),  // Green - for creative activities
  color(100, 100, 255),  // Blue - for calm activities
  color(255, 200, 100),  // Orange - for collaborative work
  color(255, 100, 255),  // Purple - for reflection
  color(100, 255, 255)   // Cyan - for assessment
};

final float BASE_ORBIT_SPEED = 0.001;
final float ADDITIONAL_ORBIT_SPEED = 0.0005;
final int MAX_ACTIVITIES = 8;

// Star class for background effect
class Star {
  float x, y;
  float brightness;
  float twinkleSpeed;
  
  Star() {
    x = random(width);
    y = random(height);
    brightness = random(100, 255);
    twinkleSpeed = random(0.02, 0.05);
  }
  
  void display() {
    float twinkle = sin(frameCount * twinkleSpeed) * 50;
    fill(255, 255, 0, brightness + twinkle);
    noStroke();
    ellipse(x, y, 2, 2);
  }
}

// Sun class with photo integration
class Sun {
  float x, y;
  float size;
  float pulseAngle;
  PImage photo;
  
  Sun(float x, float y) {
    this.x = x;
    this.y = y;
    this.size = 160;
    this.pulseAngle = 0;
    this.photo = null;
  }
  
  void display() {
    pulseAngle += 0.05;
    float currentSize = size + sin(pulseAngle) * 5;
    
    // Sun glow
    for (int i = 4; i > 0; i--) {
      fill(255, 200, 0, 50/i);
      noStroke();
      ellipse(x, y, currentSize + i*20, currentSize + i*20);
    }
    
    // Sun core
    fill(255, 200, 0);
    ellipse(x, y, currentSize, currentSize);
    
    if (photo != null) {
      imageMode(CENTER);
      PGraphics mask = createGraphics(photo.width, photo.height);
      mask.beginDraw();
      mask.background(0);
      mask.fill(255);
      mask.noStroke();
      mask.ellipse(mask.width/2, mask.height/2, currentSize - 10, currentSize - 10);
      mask.endDraw();
      photo.mask(mask);
      image(photo, x, y, currentSize - 10, currentSize - 10);
    }
  }
  
  void setPhoto(PImage newPhoto) {
    photo = newPhoto.copy();
    photo.resize(int(size), int(size));
  }
}

// Planet class with photo integration
class Planet {
  float orbitRadius;
  float orbitSpeed;
  float orbitAngle;
  float size;
  color planetColor;
  String activity;
  float duration;
  PImage photo;
  
  Planet(float orbitRadius, float orbitSpeed, float startAngle, float size, 
         color planetColor, String activity, float duration) {
    this.orbitRadius = orbitRadius;
    this.orbitSpeed = orbitSpeed;
    this.orbitAngle = startAngle;
    this.size = size;
    this.planetColor = planetColor;
    this.activity = activity;
    this.duration = duration;
    this.photo = null;
  }
  
  void orbit() {
    orbitAngle += orbitSpeed;
  }
  
  float getX() {
    return width/2 + cos(orbitAngle) * orbitRadius;
  }
  
  float getY() {
    return height/2 + sin(orbitAngle) * orbitRadius;
  }
  
  void display() {
    // Draw orbit path
    noFill();
    stroke(100, 100, 100, 100);
    ellipse(width/2, height/2, orbitRadius * 2, orbitRadius * 2);
    
    float x = getX();
    float y = getY();
    
    // Planet base
    fill(planetColor);
    noStroke();
    ellipse(x, y, size, size);
    
    // Display photo if available
    if (photo != null) {
      imageMode(CENTER);
      PGraphics mask = createGraphics(photo.width, photo.height);
      mask.beginDraw();
      mask.background(0);
      mask.fill(255);
      mask.noStroke();
      mask.ellipse(mask.width/2, mask.height/2, size - 10, size - 10);
      mask.endDraw();
      photo.mask(mask);
      image(photo, x, y, size - 10, size - 10);
    }
    
    // Activity label
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text(activity + "\n(" + formatTime(duration) + ")", x, y + size/2 + 20);
  }
  
  void setPhoto(PImage newPhoto) {
    photo = newPhoto.copy();
    photo.resize(int(size), int(size));
  }
}

// Mission Panel class for displaying schedule
class MissionPanel {
  float x, y, w, h;
  color panelColor;
  
  MissionPanel(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.panelColor = color(40, 44, 52);
  }
  
  void display(ArrayList<Planet> planets, int currentPlanet, float activityTimer) {
    // Panel background
    fill(panelColor);
    stroke(0, 255, 255, 100);
    strokeWeight(2);
    rect(x, y, w, h, 10);
    
    // Header
    fill(0, 255, 255);
    textSize(24);
    textAlign(LEFT, TOP);
    text("Missions to Complete", x + 20, y + 20);
    
    // Divider
    stroke(0, 255, 255, 100);
    line(x + 20, y + 55, x + w - 20, y + 55);
    
    // Activity list
    float yOffset = y + 80;
    textSize(18);
    
    for (int i = 0; i < planets.size(); i++) {
      Planet planet = planets.get(i);
      String timeStr = formatTime(planet.duration);
      String activityText = planet.activity + " (" + timeStr + ")";
      
      if (i < currentPlanet) {
        // Completed
        fill(0, 255, 0);
        text("✓ " + activityText, x + 20, yOffset);
      } else if (i == currentPlanet) {
        // Current
        fill(255, 255, 0);
        text("► " + activityText, x + 20, yOffset);
        
        // Progress bar
        float progress = activityTimer / planet.duration;
        drawProgressBar(x + 20, yOffset + 25, w - 40, 5, progress);
      } else {
        // Upcoming
        fill(150);
        text("○ " + activityText, x + 20, yOffset);
      }
      
      yOffset += 45;
    }
  }
  
  void drawProgressBar(float x, float y, float w, float h, float progress) {
    noStroke();
    fill(40, 44, 52);
    rect(x, y, w, h);
    fill(0, 255, 255);
    rect(x, y, w * progress, h);
  }
}

void setup() {
  size(1300, 800);
  setupCamera();
  reset();
}

void setupCamera() {
  String[] cameras = Capture.list();
  if (cameras.length > 0) {
    try {
      cam = new Capture(this, 640, 480, cameras[0]);
      cam.start();
    } catch (Exception e) {
      println("Error starting camera: " + e.getMessage());
    }
  }
}

void reset() {
  planets = new ArrayList<Planet>();
  stars = new Star[150];
  for (int i = 0; i < stars.length; i++) {
    stars[i] = new Star();
  }
  
  sun = new Sun(width/2, height/2);
  missionPanel = new MissionPanel(20, 20, 300, height - 40);
  
  currentPlanet = 0;
  activityTimer = 0;
  inputComplete = false;
  inputBuffer = "";
  transitioning = true;
  t = 0;
  angle = 0;
  
  rocketX = width/2;
  rocketY = height/2;
}

void draw() {
  // Update camera if available
  if (cam != null && cam.available()) {
    cam.read();
    readyToCapture = true;
  }
  
  background(0);
  
  // Draw stars
  for (Star star : stars) {
    star.display();
  }
  
  sun.display();
  
  if (!inputComplete) {
    displayInputPrompt();
    return;
  }
  
  // Draw completed paths
  drawCompletedPaths();
  
  // Update and display planets
  for (Planet planet : planets) {
    planet.orbit();
    planet.display();
  }
  
  // Display mission panel
  missionPanel.display(planets, currentPlanet, activityTimer);
  
  // Update rocket and timer
  if (currentPlanet < planets.size()) {
    updateRocketAndTimer();
    drawRocket();
  } else {
    displayCompletionMessage();
  }
  
  // Display capture message if active
  if (showCaptureMessage) {
    if (millis() - captureMessageTimer < 5000) {
      fill(0, 255, 0);
      textAlign(CENTER, BOTTOM);
      textSize(24);
      text(captureMessage, width/2, height - 20);
    } else {
      showCaptureMessage = false;
    }
  }
}

void displayInputPrompt() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Solar System Class Schedule - Created by Kramer - What missions will you achieve today?", width/2, 100);
  text("Enter activities as: activity(minutes), activity(minutes), ...\n" +
       "Example: warmup(5), vocabulary(15), practice(20), review(10)\n" +
       "Press ENTER when done\n" + "Add photos to the sun by pressing S, to the planets by pressing the numbers 1-9", width/2, height/2 +200);
  textSize(20);
  text(inputBuffer, width/2, height/2 + 300);
}

void updateRocketAndTimer() {
  Planet targetPlanet = planets.get(currentPlanet);
  
  if (transitioning) {
    t += 0.02;
    float startX = (currentPlanet == 0) ? width/2 : planets.get(currentPlanet-1).getX();
    float startY = (currentPlanet == 0) ? height/2 : planets.get(currentPlanet-1).getY();
    rocketX = lerp(startX, targetPlanet.getX(), t);
    rocketY = lerp(startY, targetPlanet.getY(), t);
    
    if (t >= 1) {
      transitioning = false;
      t = 0;
      angle = 0;
    }
  } else {
    angle += 0.02;
    rocketX = targetPlanet.getX() + cos(angle) * 50;
    rocketY = targetPlanet.getY() + sin(angle) * 50;
    
    activityTimer += 1.0/frameRate;
    
    // Display remaining time
    fill(255);
    textSize(32);
    float timeLeft = targetPlanet.duration - activityTimer;
    text(formatTime(timeLeft), width/2, 50);
    
    if (activityTimer >= targetPlanet.duration) {
      currentPlanet++;
      transitioning = true;
      activityTimer = 0;
    }
  }
}

void drawRocket() {
  pushMatrix();
  
  float targetX = 0;
  float targetY = 0;
  
  Planet targetPlanet = planets.get(currentPlanet);
  if (!transitioning) {
    targetX = targetPlanet.getX() + cos(angle + 0.1) * 50;
    targetY = targetPlanet.getY() + sin(angle + 0.1) * 50;
  } else {
    targetX = targetPlanet.getX();
    targetY = targetPlanet.getY();
  }
  
  float dx = targetX - rocketX;
  float dy = targetY - rocketY;
  float rocketAngle = atan2(dy, dx);
  
  translate(rocketX, rocketY);
  rotate(rocketAngle + PI/2);
  
  // Draw rocket
  fill(255);
  rect(-10, -20, 20, 40);
  triangle(-10, -20, 10, -20, 0, -35);
  fill(200);
  triangle(-10, 20, -25, 20, -10, 0);
  triangle(10, 20, 25, 20, 10, 0);
  
  // Engine fire
  fill(255, 140, 0);
  beginShape();
  vertex(-8, 20);
  vertex(8, 20);
  vertex(0, random(35, 45));
  endShape(CLOSE);
  
  popMatrix();
}

void drawCompletedPaths() {
  if (currentPlanet == 0) return;
  
  stroke(255, 0, 0);
  strokeWeight(2);
  
  for (int i = 0; i < currentPlanet; i++) {
    float startX = (i == 0) ? width/2 : planets.get(i-1).getX();
    float startY = (i == 0) ? height/2 : planets.get(i-1).getY();
    float endX = planets.get(i).getX();
    float endY = planets.get(i).getY();
    
    // Draw dotted line segments
    float spacing = 10;
    float totalDist = dist(startX, startY, endX, endY);
    int numDots = int(totalDist / spacing);
    
    for (int j = 0; j < numDots; j++) {
      float t = j / float(numDots);
      if (j % 2 == 0) {
        float x1 = lerp(startX, endX, t);
        float y1 = lerp(startY, endY, t);
        float x2 = lerp(startX, endX, t + 1.0/numDots);
        float y2 = lerp(startY, endY, t + 1.0/numDots);
        line(x1, y1, x2, y2);
      }
    }
  }
}

void displayCompletionMessage() {
  fill(255);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Lesson Complete!\nPress ESC to create new schedule", width/2, height/2);
}

void keyPressed() {
  if (key == ESC) {
    key = 0;  // Prevent window from closing
    reset();
    return;
  }
  
  if (!inputComplete) {
    if (key == ENTER || key == RETURN) {
      if (validateAndCreatePlanets(inputBuffer.trim())) {
        inputComplete = true;
      }
    } else if (key == BACKSPACE && inputBuffer.length() > 0) {
      inputBuffer = inputBuffer.substring(0, inputBuffer.length()-1);
    } else if (key != CODED && inputBuffer.length() < 100) {
      inputBuffer += key;
    }
  } else {
    // Handle photo capture when timer is running
    if (key == 's' || key == 'S') {
      if (readyToCapture) {
        capturePhoto(sun);
       
      }
    } else if (key >= '1' && key <= '9') {
      int planetIndex = int(key) - 49;
      if (planetIndex < planets.size() && readyToCapture) {
        capturePhoto(planets.get(planetIndex));
        
      }
    }
  }
}

void capturePhoto(Object target) {
  PImage captured = createImage(cam.width, cam.height, RGB);
  captured.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width, cam.height);
  
  if (target instanceof Sun) {
    ((Sun)target).setPhoto(captured);
  } else if (target instanceof Planet) {
    ((Planet)target).setPhoto(captured);
  }
  
  readyToCapture = false;
}

void showCaptureMessage(String message) {
  captureMessage = message;
  captureMessageTimer = millis();
  showCaptureMessage = true;
}

boolean validateAndCreatePlanets(String input) {
  if (input.trim().length() == 0) {
    showCaptureMessage("Please enter at least one activity!");
    return false;
  }
  
  String[] activities = split(input, ',');
  if (activities.length > MAX_ACTIVITIES) {
    showCaptureMessage("Maximum " + MAX_ACTIVITIES + " activities allowed!");
    return false;
  }
  
  // Validate all activities first
  for (String activity : activities) {
    if (!validateActivity(activity.trim())) {
      return false;
    }
  }
  
  // If validation passed, create planets
  createPlanetsFromInput(input);
  return true;
}

boolean validateActivity(String activity) {
  String[] parts = match(activity, "(.*?)\\((\\d+)\\)");
  if (parts == null || parts.length != 3) {
    showCaptureMessage("Invalid format! Use: activity(minutes)");
    return false;
  }
  
  String name = parts[1].trim();
  if (name.length() == 0) {
    showCaptureMessage("Activity name cannot be empty!");
    return false;
  }
  
  try {
    int minutes = Integer.parseInt(parts[2]);
    if (minutes <= 0 || minutes > 120) {
      showCaptureMessage("Duration must be between 1 and 120 minutes!");
      return false;
    }
  } catch (NumberFormatException e) {
    showCaptureMessage("Invalid duration!");
    return false;
  }
  
  return true;
}

void createPlanetsFromInput(String input) {
  String[] activities = split(input, ',');
  float baseRadius = min(width, height)/9;
  float radiusStep = 45;
  
  for (int i = 0; i < activities.length; i++) {
    String activity = activities[i].trim();
    String[] parts = match(activity, "(.*?)\\((\\d+)\\)");
    
    String name = parts[1].trim();
    float duration = float(parts[2]) * 60;  // Convert to seconds
    
    float orbitRadius = baseRadius + (i * radiusStep);
    float orbitSpeed = BASE_ORBIT_SPEED + (ADDITIONAL_ORBIT_SPEED * (activities.length - i));
    float startAngle = TWO_PI * i / activities.length;
    
    planets.add(new Planet(
      orbitRadius,
      orbitSpeed,
      startAngle,
      100,  // Planet size
      PLANET_COLORS[i % PLANET_COLORS.length],
      name,
      duration
    ));
  }
}

String formatTime(float seconds) {
  int minutes = int(seconds / 60);
  int secs = int(seconds % 60);
  return nf(minutes, 2) + ":" + nf(secs, 2);
}
