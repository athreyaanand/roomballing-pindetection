import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;

import websockets.*;

WebsocketClient wsc;

JSONObject json;

Kinect2 kinect; 
PImage currentImage;

color trackColor; 
float threshold = 40;
float distThreshold = 30;
int pinCount = 0;
boolean runEnd = false;

ArrayList<Blob> blobs = new ArrayList<Blob>();

void setup() {
  size(1400, 750);
  
  trackColor = color(255, 0, 0);
  kinect = new Kinect2(this);
  kinect.initVideo();
  kinect.initDevice();
  
  currentImage = kinect.getVideoImage();
  image(currentImage, 0, 0);
  
  wsc = new WebsocketClient(this, "ws://143.215.107.222:8080");
}

void keyPressed() {
  if (key == 'a') {
    distThreshold += 5;
  } else if (key == 'z') {
    distThreshold -= 5;
  }
  if (key == 's') {
    threshold += 5;
  } else if (key == 'x') {
    threshold -= 5;
  }
}

void draw() {
  pinCount = 0;
  currentImage = kinect.getVideoImage();
  image(currentImage, 0, 0);

  blobs.clear();

  // Begin loop to walk through every pixel
  for (int x = 0; x < currentImage.width; x++ ) {
    for (int y = 0; y < currentImage.height; y++ ) {
      int loc = x + y * currentImage.width;
      // What is current color
      color currentColor = currentImage.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(trackColor);
      float g2 = green(trackColor);
      float b2 = blue(trackColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d < threshold*threshold) {

        boolean found = false;
        for (Blob b : blobs) {
          if (b.isNear(x, y)) {
            b.add(x, y);
            found = true;
            break;
          }
        }

        if (!found) {
          Blob b = new Blob(x, y);
          blobs.add(b);
        }
      }
    }
  }

  for (Blob b : blobs) {
    if (b.size() > 300) {
      pinCount++;
      b.show();
    }
  }
  
   if (runEnd) {
    json = new JSONObject();
    json.setString("type", "pinCount");
    json.setInt("pinCount", pinCount);
    wsc.sendMessage(json.toString());
    runEnd = false;
  }

  textAlign(RIGHT);
  fill(0);
  text("distance threshold: " + distThreshold, width-10, 25);
  text("color threshold: " + threshold, width-10, 50);
  text("PINS LEFT: " + pinCount, width-10, 75);
}

// Custom distance functions w/ no square root for optimization
float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void mousePressed() {
  // Save color where the mouse is clicked in trackColor variable
  int loc = mouseX + mouseY*currentImage.width;
  trackColor = currentImage.pixels[loc];
}

void webSocketEvent(String msg){
 println(msg);
 if (msg.contains("end")) {
   runEnd = true;
 }
}
