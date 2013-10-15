/**
 Original credit to Jay Clegg : http://www.planetclegg.com/projects/VideoPeggyMisc.html
 
 I have edited and modifed his script to suit my own LED matrix configuration,
 and also included some other test animations.
 
 The comments are a mixture of Jay's, mine and comments from reference literature for
 Processing and the minim library.
 
 PREREQUISITES:
 To run the spectrum() method you will need the minim library:
 http://code.compartmental.net/tools/minim/
 
 You will also need an mp3 in the project folder. The file I was using was called "Sunset.mp3".
 You will get a null pointer exception on the minim.loadFile statement if you do not have
 an appropriately named mp3 file in the project directory.
 */

import processing.serial.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;  
AudioPlayer audioPlayer;
FFT fftLin;
FFT fftLog;
Serial peggyPort;

int rows = 48;
int ledsPerRow = 16;
int bytesPerRow = 8;

PImage peggyImage = new PImage(rows, ledsPerRow);
byte [] peggyFrame = new byte[bytesPerRow*rows];

// The peggyStartFrame is a sequence of bytes which signals to the the microcontroller
// that a new frame is to be recieved.
byte [] peggyStartFrame = new byte[] { 
  (byte)0xde, (byte)0xad, (byte)0xbe, (byte)0xef, 1, 2
};

// The following constants are used for the Bounce animation.
int size = 100;       // Width of the shape
float xpos, ypos;    // Starting position of shape    

float xspeed = 10.1;  // Speed of the shape
float yspeed = 12.2;  // Speed of the shape

int xdirection = 1;  // Left or Right
int ydirection = 1;  // Top to Bottom

boolean playAudio = false;
boolean sendToSerial = true;

int animationWidth = 1200;
int animationHeight = 400;

void setup() 
{  
  size(animationWidth, animationHeight);
  noStroke();
  frameRate(5);
  smooth();

  //setupBounce();
  //setupSpectrum();
  setupStars();

  if (sendToSerial)
  {
    // The serial identifier ("COM5" in my case) is different for different OS's.  
    peggyPort = new Serial(this, "COM5", 230400);
  }

  // Initially just create a black background and send this to the display.
  background(0);
  renderToPeggy(grabDisplay());
}

void stop()
{  
  audioPlayer.close();
  minim.stop();
  super.stop();
}

// this method creates a PImage that is a copy 
// of the current processing display.
// Its very crude and inefficient, but it works.
PImage grabDisplay()
{
  PImage img = createImage(width, height, ARGB);
  loadPixels();
  arraycopy(pixels, 0, img.pixels, 0, width * height);
  return img;
}

// render a PImage to the Peggy by transmitting it serially.  
// If it is not already sized to 25x25, this method will 
// create a downsized version to send...
void renderToPeggy(PImage srcImg)
{
  int idx = 0;

  PImage destImg = peggyImage;
  if (srcImg.width != rows || srcImg.height != ledsPerRow)
    destImg.copy(srcImg, 0, 0, srcImg.width, srcImg.height, 0, 0, destImg.width, destImg.height);
  else
    destImg = srcImg;

  // iterate over the image, pull out pixels and 
  // build an array to serialize to the peggy
  // I (dinofizz) have modified this from Jay's original implementation, as the 
  // start and end points of my display are in a different configuration
  // with respect to his rows and columns. 
  for (int x = (rows - 1); x >= 0; x--)
  {
    byte val = 0;
    for (int y = (ledsPerRow - 1); y >= 0; y--)
    {
      color c = destImg.get(x, y); 
      int br = ((int)brightness(c)) >> 4;

      if (y % 2 == 0)   
      {             
        val = (byte) (((br << 4) | val) & 0xFF);
        peggyFrame[idx++]= val;
        val = 0;
      }
      else
      {        
        val = (byte) ((br | val) & 0xFF);
      }
    }
  }

  if (sendToSerial)
  {
    peggyPort.write(peggyStartFrame);  
    peggyPort.write(peggyFrame);
  }
}

// Simple delay method. Saves initial time, waits until difference between current time and
// initial time is greater or equal to the specified number of milliseconds.
void delayMilliseconds(int milliseconds)
{
  int initialTime = millis();
  while ( (millis () - initialTime) <= milliseconds) {
  }
}

void drawNothing()
{
  background(0);
  renderToPeggy(grabDisplay());
  noLoop();
}

void draw() 
{
  //fade();
  //drawNothing();
  //xpressYourSelf();
  //bounce();
  //spectrum();
  fill(255);

  //ellipse(100, 100, 30, 30);
  
  background(0);
  for (int i = 0; i < numStars; i++)
  {   
    stars[i].drawStar();
  }
  renderToPeggy(grabDisplay());
}

