/* Processing button control sample originally seen in
   Processing: A Programming Handbook 
   for Visual Designers and Artists
   by Casey Reas and Ben Fry
   2007 MIT Press
*/
class Button {
  final int pressDelay = 500; // milliseconds
  int x, y; // The x- and y-coordinates
  int width; // Dimension (width and height)
  int height;
  color baseGray; // Default gray value
  color overGray; // Value when mouse is over the button
  color pressGray; // Value when mouse is over and pressed
  boolean over = false; // True when the mouse is over
  int pressState = 0;
  int pressTime;

  Button(int xp, int yp, int w, int h, color b, color o, color p) {
    x = xp;
    y = yp;
    width = w;
    height = h;
    baseGray = b;
    overGray = o;
    pressGray = p;
  }
  
  // Updates the over field every frame
  void update() {
    if ((mouseX >= x) && (mouseX <= x + width) &&
        (mouseY >= y) && (mouseY <= y + height)) {
      over = true;
    } else {
      over = false;
    }
  }

  boolean press() {
    if (over == true) {
      pressState = 1;
      return true;
    } else {
      return false;
    }
  }

  void release() {
    pressState = 0;
  }

  void display() {
    if (pressState > 0) {
      fill(pressGray);
    } else if (over == true) {
      fill(overGray);
    } else {
      fill(baseGray);
    }
    stroke(255);
    rect(x, y, width, height);
  }
  
  boolean isPressed()
  {
    switch (pressState)
    {
      case 0:
        return false;
      case 1:
        pressTime = millis();
        pressState = 2;
        return true;
      case 2:
        if (millis() - pressTime > pressDelay)
        {
          pressState = 3;
        }
        return false;
      case 3:
        return true;
    }
    return false;
 }
}
