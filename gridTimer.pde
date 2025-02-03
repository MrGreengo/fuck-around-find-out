class Period {
  int startHour, startMin, endHour, endMin;
  color col;
  String name;
  
  Period(int sh, int sm, int eh, int em, color c, String n) {
    startHour = sh;
    startMin = sm;
    endHour = eh;
    endMin = em;
    col = c;
    name = n;
  }
  
  boolean containsMinute(int totalMinutes) {
    int start = startHour * 60 + startMin;
    int end = endHour * 60 + endMin;
    return totalMinutes >= start && totalMinutes < end;
  }
  
  int minutesUntilEnd(int currentTimeInMinutes) {
    return (endHour * 60 + endMin) - currentTimeInMinutes;
  }
}

Period[] periods;
int TOTAL_MINUTES = 420;  // 7 hours
float SQUARE_SIZE;
int GRID_SIZE = 21;

// Animation variables
float fadeAlpha = 0;
int lastMinute = -1;
float pulseSize = 0;
float[] ripples = new float[3];  // Multiple ripples
float[] rippleAlphas = new float[3];  // Alpha values for each ripple

void setup() {
  size(800, 800);
  SQUARE_SIZE = width / GRID_SIZE;
  
  // Initialize ripples
  for (int i = 0; i < ripples.length; i++) {
    ripples[i] = 0;
    rippleAlphas[i] = 255;
  }
  
  // Initialize periods with different colors for morning schedule
  periods = new Period[] {
    new Period(7, 10, 7, 30, color(200, 200, 200), "Arrival"), // Gray
    new Period(7, 30, 8, 25, color(255, 150, 150), "Period 1"), // Red
    new Period(8, 25, 9, 20, color(255, 200, 150), "Period 2"), // Orange
    new Period(9, 20, 10, 15, color(255, 255, 150), "Period 3"), // Yellow
    new Period(10, 15, 11, 10, color(150, 255, 150), "Period 4"), // Green
    new Period(11, 10, 12, 5, color(150, 255, 255), "Period 5"), // Cyan
    new Period(12, 5, 13, 0, color(150, 150, 255), "Period 6"), // Blue
    new Period(13, 0, 13, 55, color(200, 150, 255), "Period 7"), // Purple
    new Period(13, 55, 14, 10, color(200, 200, 200), "Dismissal") // Gray
  };
}

void draw() {
  background(0);  // Black background
  
  // Get current time
  int h = hour();
  int m = minute();
  
  // Update pulse animation
  pulseSize = sin(frameCount * 0.1) * 0.15;
  
  // Check for minute change to trigger animation
  if (m != lastMinute) {
    fadeAlpha = 255;
    lastMinute = m;
  }
  
  // Update fade animation
  if (fadeAlpha > 0) {
    fadeAlpha -= 8;
  }
  
  // Current time in minutes since midnight
  int currentTimeInMinutes = h * 60 + m;
  
  // Find current period and minutes until end
  Period currentPeriod = null;
  int minutesUntilEnd = 0;
  for (Period p : periods) {
    if (p.containsMinute(currentTimeInMinutes)) {
      currentPeriod = p;
      minutesUntilEnd = p.minutesUntilEnd(currentTimeInMinutes);
      break;
    }
  }
  
  // Update ripple animations if in last 5 minutes of a period
  if (currentPeriod != null && minutesUntilEnd <= 5) {
    for (int i = 0; i < ripples.length; i++) {
      ripples[i] += 2;
      rippleAlphas[i] -= 3;
      
      if (rippleAlphas[i] <= 0) {
        ripples[i] = 0;
        rippleAlphas[i] = 255;
      }
    }
  }
  
  // Draw grid of squares
  for (int i = 0; i < TOTAL_MINUTES; i++) {
    int row = i / GRID_SIZE;
    int col = i % GRID_SIZE;
    
    float x = col * SQUARE_SIZE;
    float y = row * SQUARE_SIZE;
    
    // Calculate what time this square represents (adjusted for 7:10 start)
    int squareHour = 7 + ((i + 10) / 60);  // Start at 7:10
    int squareMinute = (i + 10) % 60;
    int squareTimeInMinutes = squareHour * 60 + squareMinute;
    
    // Find which period this minute belongs to
    color squareColor = color(0);
    for (Period p : periods) {
      if (p.containsMinute(squareTimeInMinutes)) {
        squareColor = p.col;
        break;
      }
    }
    
    // Draw ripple effects for current minute if in last 5 minutes
    if (squareTimeInMinutes == currentTimeInMinutes && 
        currentPeriod != null && 
        minutesUntilEnd <= 5) {
      for (int r = 0; r < ripples.length; r++) {
        noFill();
        stroke(255, 0, 0, rippleAlphas[r]);
        rectMode(CENTER);
        rect(x + SQUARE_SIZE/2, y + SQUARE_SIZE/2, 
             SQUARE_SIZE * (1 + ripples[r]), 
             SQUARE_SIZE * (1 + ripples[r]));
        rectMode(CORNER);
      }
    }
    
    // Set square appearance based on time
    if (squareTimeInMinutes < currentTimeInMinutes) {
      // Past minutes are clearly white with period-colored border
      fill(255);  // Bright white for completed minutes
      stroke(squareColor);
      strokeWeight(2);  // Slightly thicker border for better visibility
    } else if (squareTimeInMinutes == currentTimeInMinutes) {
      // Current minute pulses with green border
      fill(squareColor);
      stroke(0, 255, 0);
      strokeWeight(3);
    } else {
      // Future minutes show period color
      fill(squareColor);
      stroke(30);  // Darker border for unreached minutes
      strokeWeight(1);
    }
    
    // Draw the square
    float size = squareTimeInMinutes == currentTimeInMinutes ? 
                 SQUARE_SIZE * (0.9 + pulseSize) : 
                 SQUARE_SIZE * 0.9;
    float xPos = x + (SQUARE_SIZE - size) / 2;
    float yPos = y + (SQUARE_SIZE - size) / 2;
    rect(xPos, yPos, size, size);
    strokeWeight(1);
  }
  
  // Draw large minutes remaining display
  if (currentPeriod != null) {
    // Draw semi-transparent background box
    fill(0, 180);
    noStroke();
    rect(width/2 - 150, height/2 - 100, 300, 200);
    
    // Display minutes remaining in large text
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(80);
    text(minutesUntilEnd, width/2, height/2 - 20);
    textSize(24);
    text("minutes remaining in", width/2, height/2 + 30);
    fill(currentPeriod.col);
    text(currentPeriod.name, width/2, height/2 + 60);
  }
  
  // Display current time
  fill(255);
  textSize(20);
  textAlign(CENTER);
  String timeString = nf(h, 2) + ":" + nf(m, 2);
  text(timeString, width/2, height - 40);
}
