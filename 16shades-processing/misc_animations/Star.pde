Star[] stars;
int numStars = 500;
int sizeStars = 10;

void setupStars()
{
  stars = new Star[numStars];
  
  for (int i = 0; i < numStars; i++)
  {
    stars[i] = new Star(sizeStars, int(random(255)), animationWidth, animationHeight);
  }
}

class Star
{
  int starX;
  int starY;
  int starSize;
  int starBrightness;
  int maxWidth;
  int maxHeight;
  boolean gettingBrighter = true;

  public Star(int _size, int _brightness, int _maxWdith, int _maxHeight)
  {
    maxWidth = _maxWdith;
    maxHeight = _maxHeight;  
    starX = int(random(maxWidth));
    starY = int(random(maxHeight));
    starSize = _size;
    starBrightness = _brightness;
  }
  
  void drawStar()
  { 
    if (gettingBrighter)
    {
      starBrightness++;
    }
    else
    {
      starBrightness--;
    }
  
    if (starBrightness == 255)
    {
      gettingBrighter = false;
    }  
    
    if (starBrightness == 0)
    {
      starBrightness = int(random(128, 255));
      starX = int(random(maxWidth));
      starY = int(random(maxHeight));
      gettingBrighter = true;
    }
    fill(starBrightness);
    ellipse(starX, starY, starSize, starSize);
  }
}
