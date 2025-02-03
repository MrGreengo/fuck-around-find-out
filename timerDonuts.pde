// Processing code for a circular (doughnut) visualization of each class period.
// Each period is shown as a ring that fills as time passes.
// Completed periods turn gray, future periods remain dim, and the active period animates.

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

  int totalDuration() {
    return (endHour * 60 + endMin) - (startHour * 60 + startMin);
  }

  int minutesElapsed(int currentTimeInMinutes) {
    // Returns how many minutes have passed in this period so far
    // If the period hasn't started yet, this will be negative.
    int start = startHour * 60 + startMin;
    return currentTimeInMinutes - start;
  }
}

Period[] periods;

void setup() {
  size(1300, 800);
  // Define periods (example schedule, adjust as needed):
  periods = new Period[] {
    new Period(7, 10, 7, 30, color(200, 200, 200), "Arrival"),
    new Period(7, 30, 8, 25, color(255, 150, 150), "Period 1"),
    new Period(8, 25, 9, 20, color(255, 200, 150), "Period 2"),
    new Period(9, 20, 10, 15, color(255, 255, 150), "Period 3"),
    new Period(10, 15, 11, 10, color(150, 255, 150), "Period 4"),
    new Period(11, 10, 12, 5, color(150, 255, 255), "Period 5"),
    new Period(12, 5, 13, 0, color(150, 150, 255), "Period 6"),
    new Period(13, 0, 13, 55, color(200, 150, 255), "Period 7"),
    new Period(13, 55, 14, 10, color(200, 200, 200), "Dismissal")
  };
  smooth();
  textAlign(CENTER, CENTER);
}

void draw() {
  background(0);

  // Calculate current time in minutes
  int h = hour();
  int m = minute();
  int currentTimeInMin = h * 60 + m;

  // Settings for drawing the rings
  float ringDiameter = 100;
  float ringSpacing = 140;
  float centerY = height/2;

  // Draw each period as a donut/circle
  for (int i = 0; i < periods.length; i++) {
    Period p = periods[i];
    int pStart = p.startHour * 60 + p.startMin;
    int pEnd = p.endHour * 60 + p.endMin;
    int duration = pEnd - pStart;

    // fraction of the period that has elapsed
    float fraction = (float)(currentTimeInMin - pStart) / (float)duration;

    // Constrain fraction between 0 and 1
    fraction = constrain(fraction, 0, 1);

    // Position of the ring's center
    float centerX = 80 + i * ringSpacing;

    // Draw background ring (thick stroke)
    strokeWeight(20);
    noFill();

    // Decide ring color logic
    // If fraction < 0, period hasn't started
    // If fraction between 0 and 1, period is active
    // If fraction >= 1, period is finished
    if ((currentTimeInMin < pStart)) {
      // Future period (not started)
      stroke(100); // dim gray ring
      arc(centerX, centerY, ringDiameter, ringDiameter, 0, TWO_PI);

      // Outline the ring with the period color at lower alpha if desired
      stroke(p.col, 100);
      arc(centerX, centerY, ringDiameter, ringDiameter, 0, TWO_PI);

      // Label
      fill(255);
      textSize(20);
      text(p.name, centerX, centerY);
    } else if (currentTimeInMin >= pEnd) {
      // Period completed
      stroke(180); // light gray ring
      arc(centerX, centerY, ringDiameter, ringDiameter, 0, TWO_PI);

      // Label
      fill(255);
      textSize(20);
      text("Done", centerX, centerY);
    } else {
      // Active period
      // Draw base ring in gray
      stroke(80);
      arc(centerX, centerY, ringDiameter, ringDiameter, 0, TWO_PI);

      // Draw filled portion in period color
      stroke(p.col);
      float startAngle = -HALF_PI; // Start at top
      float endAngle = startAngle + fraction * TWO_PI;
      arc(centerX, centerY, ringDiameter, ringDiameter, startAngle, endAngle);

      // Label: minutes left
      int minutesElapsed = max(0, currentTimeInMin - pStart);
      int minutesLeft = duration - minutesElapsed;
      fill(255);
      textSize(20);
      text(minutesLeft + " min\n" + p.name, centerX, centerY);
    }
  }

  // Draw the current time at bottom
  fill(255);
  textSize(20);
  text(nf(h, 2) + ":" + nf(m, 2), width/2, height - 30);
}
