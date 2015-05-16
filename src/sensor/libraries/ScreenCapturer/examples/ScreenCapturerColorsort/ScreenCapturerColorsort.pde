import processing.video.*;
import com.onformative.screencapturer.*;

PImage video;

// How many pixels to skip in either direction
int increment = 1;

ScreenCapturer capturer;

void setup() {
  size(800, 400, P3D);
  capturer = new ScreenCapturer(800, 400, 30);
  noCursor();
}


void draw() {
  video = capturer.getImage();
    background(0);
    noStroke();

    int index = 0;
    for (int j = 0; j < video.height; j += increment) {
        int pixelColor = video.pixels[j*video.width + 100];

        int r = (pixelColor >> 16) & 0xff;
        int g = (pixelColor >> 8) & 0xff;
        int b = pixelColor & 0xff;
        print(r,g,b);
        print("\n");
        //if(r==242&&g==112&&b==025)print("Bird Found");
    }
}
