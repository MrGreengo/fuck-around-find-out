import ddf.minim.*;
import processing.video.*;

// Game states
enum GameState { START, ACTIVE, GAME_OVER }
GameState state = GameState.START;

// Audio setup
Minim minim;
AudioInput mic;
float clapThreshold = 0.01;
long lastClapTime = 0;

// Camera setup
Capture cam;
PImage[] playerImages = new PImage[5];
PImage[] gridPatterns = new PImage[5];
boolean readyToCapture = false;
int lastCaptureTime = 0;
int captureDelay = 500;
String cameraStatus = "";

// Grid and ball management
ArrayList<Ball> balls;
float gridSpacing = 70;  // Increased spacing for larger balls
float nextX = gridSpacing/2;
float nextY;
int gridWidth = 10;

// Game settings
int gameDuration = 5000; // 5 seconds
int startTime;
color startColor = color(0, 255, 0);
color endColor = color(255, 0, 0);
int[] highScores = {0, 0, 0, 0, 0};
boolean newHighScore = false;

void setup() {
    size(1400, 800);  // Increased window size
    
    // Initialize audio
    minim = new Minim(this);
    mic = minim.getLineIn(Minim.MONO, 512);
    
    // Initialize game objects
    balls = new ArrayList<Ball>();
    nextY = height - gridSpacing/2;
    
    textAlign(CENTER, CENTER);
    textSize(24);
    
    // Initialize arrays
    playerImages = new PImage[5];
    gridPatterns = new PImage[5];
    
    println("Game initialized - Clap threshold: " + clapThreshold);
    
    // Initialize camera
    String[] cameras = Capture.list();
    if (cameras.length > 0) {
        try {
            cam = new Capture(this, 640, 480, cameras[0]);
            cam.start();
            cameraStatus = "Camera ready";
        } catch (Exception e) {
            cameraStatus = "Camera error: " + e.getMessage();
            cam = null;
        }
    } else {
        cameraStatus = "No camera found";
    }
}

void draw() {
    background(0);
    
    // Update camera if available
    if (cam != null && cam.available()) {
        cam.read();
        readyToCapture = true;
    }
    
    // Always draw high scores
    drawHighScores();
    
    switch(state) {
        case START:
            drawStartScreen();
            break;
        case ACTIVE:
            updateGame();
            break;
        case GAME_OVER:
            drawGameOverScreen();
            break;
    }
}

void drawStartScreen() {
    fill(255);
    text("CLAP CHAMPION\nPress SPACE to start!\n\nMake noise to create circles!\nTry to fill the grid in 5 seconds.", 
         width/2, height/2);
}

void updateGame() {
    float volume = mic.left.level();
    
    // Debug information
    fill(255);
    textSize(14);
    text("Volume: " + nf(volume, 0, 3), 70, 50);
    text("Threshold: " + nf(clapThreshold, 0, 3), 70, 70);
    text("Balls: " + balls.size(), 70, 90);
    textSize(24);
    
    if (volume > clapThreshold && millis() - lastClapTime > 80) {
        lastClapTime = millis();
        registerClap(volume);
    }
    
    // Draw all balls
    for (Ball ball : balls) {
        ball.display();
    }
    
    // Draw countdown bar
    drawCountdownBar();
}

void drawGameOverScreen() {
    boolean isInHighScores = checkHighScore(balls.size());
    
    if (isInHighScores && cam != null) {
        // Center the camera preview
        if (cam.available()) {
            cam.read();
        }
        
        // Draw camera preview in the center
        pushMatrix();
        translate(width/2 - 160, height/2 - 120);
        if (cam.width > 0 && cam.height > 0) {
            image(cam, 0, 0, 320, 240);
            noFill();
            stroke(255);
            rect(0, 0, 320, 240);
        }
        popMatrix();
        
        // Status indicator
        boolean timeReady = (millis() - lastCaptureTime > captureDelay);
        boolean fullyReady = readyToCapture && timeReady;
        
        fill(fullyReady ? color(0, 255, 0) : color(255, 0, 0));
        noStroke();
        ellipse(width/2 + 150, height/2 - 110, 10, 10);
        
        fill(255);
        textSize(20);
        text(fullyReady ? "Camera Ready" : "Wait...", width/2 + 150, height/2 - 90);
        
        fill(255);
        textAlign(CENTER, CENTER);
        text("New High Score: " + balls.size() + "\nPress ENTER when green light is on to take photo\nPress SPACE to play again", 
             width/2, height/6);
             
        textSize(30);
        fill(200);
        text(cameraStatus, width/2, height/2 + 140);
    } else {
        fill(255);
        textAlign(CENTER, CENTER);
        text("Score: " + balls.size() + "\nTry again!\nPress SPACE to play again", 
             width/2, height/2);
    }
}

boolean checkHighScore(int score) {
    for (int highScore : highScores) {
        if (score >= highScore) {
            return true;
        }
    }
    return false;
}

void registerClap(float intensity) {
    // Map intensity to size, with a minimum size
    float newSize = max(20, map(intensity, clapThreshold, 1, 20, 50));
    color newColor = color(random(255), random(255), random(255));
    
    // Only add ball if within grid bounds and not overlapping high scores
    if (nextY > gridSpacing/2 && nextX < width - 350) {
        balls.add(new Ball(nextX, nextY, newSize, newColor, balls.size() + 1));
        
        nextX += gridSpacing;
        if (nextX > gridSpacing/2 + (gridWidth-1) * gridSpacing) {
            nextX = gridSpacing/2;
            nextY -= gridSpacing;
        }
    }
}

void drawCountdownBar() {
    float elapsedTime = millis() - startTime;
    float progress = elapsedTime / gameDuration;
    color barColor = lerpColor(startColor, endColor, progress);
    
    fill(barColor);
    noStroke();
    rect(0, 0, width * (1 - progress), 20);
    
    if (progress >= 1) {
        updateHighScores(balls.size());
        state = GameState.GAME_OVER;
    }
}

void captureGridPattern() {
    PGraphics pg = createGraphics(400, 300);
    pg.beginDraw();
    pg.background(0);
    
    // Calculate the play area width (excluding high score area)
    float playAreaWidth = width - 350;
    float scaleX = 400.0 / playAreaWidth;
    float scaleY = 300.0 / height;
    
    for (Ball ball : balls) {
        pg.fill(ball.c);
        pg.noStroke();
        pg.ellipse(ball.x * scaleX, ball.y * scaleY, ball.size * scaleX, ball.size * scaleY);
        
        pg.fill(255);
        pg.textAlign(CENTER, CENTER);
        pg.textSize(ball.size/2);
        pg.text(str(ball.number), ball.x * scaleX, ball.y * scaleY);
    }
    
    pg.endDraw();
    
    for (int i = 0; i < highScores.length; i++) {
        if (balls.size() == highScores[i]) {
            gridPatterns[i] = pg.get();
            println("Grid pattern stored at index: " + i);
            break;
        }
    }
}

void drawHighScores() {
    float startX = width - 300;
    float labelY = 20;
    float startY = 100;
    
    textSize(18);
    textAlign(CENTER, CENTER);
    fill(255);
    text("HIGH SCORES", startX, labelY);
    
    for (int i = 0; i < highScores.length; i++) {
        float yPos = startY + i * 90;
        
        fill(255);
        textAlign(RIGHT, CENTER);
        String scoreText = "#" + (i+1) + ": " + highScores[i];
        text(scoreText, startX + 30, yPos);
        
        // Draw player photo area
        stroke(255);
        fill(0);
        rect(startX - 90, yPos - 30, 80, 60);
        
        if (playerImages[i] != null) {
            image(playerImages[i], startX - 85, yPos - 25, 70, 50);
            noFill();
            stroke(255);
            rect(startX - 85, yPos - 25, 70, 50);
        }
        
        // Draw grid pattern area (reduced width)
        stroke(255);
        fill(0);
        rect(startX + 50, yPos - 30, 120, 60);
        
        if (gridPatterns[i] != null) {
            image(gridPatterns[i], startX + 55, yPos - 25, 110, 50);
            noFill();
            stroke(255);
            rect(startX + 55, yPos - 25, 110, 50);
        }
    }
}

void updateHighScores(int newScore) {
    newHighScore = false;
    
    for (int i = 0; i < highScores.length; i++) {
        if (newScore > highScores[i]) {
            // Shift lower scores down
            for (int j = highScores.length - 1; j > i; j--) {
                highScores[j] = highScores[j - 1];
                if (playerImages[j-1] != null) {
                    playerImages[j] = playerImages[j-1].copy();
                }
                if (gridPatterns[j-1] != null) {
                    gridPatterns[j] = gridPatterns[j-1].copy();
                }
            }
            highScores[i] = newScore;
            newHighScore = true;
            break;
        }
    }
}

void keyPressed() {
    switch(state) {
        case START:
            if (key == ' ') {
                state = GameState.ACTIVE;
                startTime = millis();
                balls.clear();
                nextX = gridSpacing/2;
                nextY = height - gridSpacing/2;
            }
            break;
            
        case GAME_OVER:
            if (key == ENTER && checkHighScore(balls.size()) && cam != null) {
                int currentTime = millis();
                boolean timeReady = (currentTime - lastCaptureTime > captureDelay);
                
                if (readyToCapture && timeReady) {
                    cameraStatus = "Capturing...";
                    
                    try {
                        PImage capturedImage = createImage(cam.width, cam.height, RGB);
                        capturedImage.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width, cam.height);
                        
                        for (int i = 0; i < highScores.length; i++) {
                            if (balls.size() == highScores[i]) {
                                playerImages[i] = capturedImage;
                                captureGridPattern();
                                cameraStatus = "Photo and grid pattern captured!";
                                newHighScore = false;
                                lastCaptureTime = currentTime;
                                readyToCapture = false;
                                break;
                            }
                        }
                    } catch (Exception e) {
                        cameraStatus = "Error during capture: " + e.getMessage();
                    }
                }
            } else if (key == ' ') {
                state = GameState.START;
            }
            break;
    }
}

void captureEvent(Capture c) {
    readyToCapture = true;
}

class Ball {
    float x, y, size;
    color c;
    int number;
    
    Ball(float x, float y, float s, color c, int number) {
        this.x = x;
        this.y = y;
        this.size = s;
        this.c = c;
        this.number = number;
    }
    
    void display() {
        // Only display if the ball is within the play area
        if (x < width - 350) {
            fill(c);
            noStroke();
            ellipse(x, y, size, size);
            
            fill(0);
            textAlign(CENTER, CENTER);
            textSize(size/1.5);
            text(str(number), x+2, y+2);
            
            fill(255);
            textSize(size/1.5);
            text(str(number), x, y);
        }
    }
}

void stop() {
    minim.stop();
    super.stop();
}
