void setupBounce()
{
  // Set the starting position of the shape
  xpos = width/2;
  ypos = height/2;  
}

// Draw's an ellipse bouncing around the display
void bounce()
{
  background(10);

  // Update the position of the shape
  xpos = xpos + ( xspeed * xdirection );
  ypos = ypos + ( yspeed * ydirection );

  // Test to see if the shape exceeds the boundaries of the screen
  // If it does, reverse its direction by multiplying by -1
  if (xpos >= width-size || xpos <= 0) {
    xdirection *= -1;
  }
  if (ypos >= height-size || ypos <= 0) {
    ydirection *= -1;
  }

  // Draw the shape
  ellipse(xpos+size/2, ypos+size/2, size, size);

  int diff = 100;

  renderToPeggy(grabDisplay());
}
