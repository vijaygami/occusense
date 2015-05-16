import com.onformative.screencapturer.*;

ScreenCapturer capturer;
void setup() {
  size(800, 400);
  capturer = new ScreenCapturer(width, height, 30);
}

void draw() {
  image(capturer.getImage(), 0, 0);
}

