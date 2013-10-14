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

void setup() 
{  
  size(1200, 400);
  noStroke();
  frameRate(30);
  smooth();
  
  // Set the starting position of the shape
  xpos = width/2;
  ypos = height/2;  

  minim = new Minim(this);
  audioPlayer = minim.loadFile("Sunset.mp3", 2048);
  audioPlayer.loop();
  // create an FFT object that has a time-domain buffer the same size as audioPlayer's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be 1024. 
  // see the online tutorial for more info.
  fftLin = new FFT(audioPlayer.bufferSize(), audioPlayer.sampleRate());
  // calculate the averages by grouping frequency bands linearly. use 30 averages.
  fftLin.linAverages(30);
  fftLog = new FFT(audioPlayer.bufferSize(), audioPlayer.sampleRate());
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fftLog.logAverages(22, 3);
  rectMode(CORNERS);

  // The serial identifier ("COM5" in my case) is different for different OS's.  
  peggyPort = new Serial(this, "COM5", 230400);

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

  peggyPort.write(peggyStartFrame);  
  peggyPort.write(peggyFrame);
}

// Simple delay method. Saves initial time, waits until difference between current time and
// initial time is greater or equal to the specified number of milliseconds.
void delayMilliseconds(int milliseconds)
{
  int initialTime = millis();
  while ( (millis () - initialTime) <= milliseconds) {
  }
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


int temp = 0;

void fade()
{
  int backgroundCol = 0;
  if (temp == 16)
  {
    backgroundCol = 255;
    temp = 0;
  }
  else
  {
    temp++;
    backgroundCol = temp * 16;
  }

  println(backgroundCol);
  background(backgroundCol);
  renderToPeggy(grabDisplay());
}

void strobe(int numToggles, int toggleLength)
{  
  boolean toggle = false;

  for (int i = numToggles; i > 0; i--)
  {
    delayMilliseconds(toggleLength);
    background(255);
    renderToPeggy(grabDisplay()); 
    delayMilliseconds(toggleLength);
    background(0);
    renderToPeggy(grabDisplay());
  }
}

void xpressYourSelf()
{  
  if (keyPressed)
  { 
    // Waits for user to press 'l' key - I was trying to match it up with the music!
    println(key);
    if (key == 'l' || key == 'L') 
    {
      background(0);
      fill(255);

      for (int i = 0; i < 80; i++)  
      {  
        textSize(500);
        text("LIFE", 10, 355, 10);
        renderToPeggy(grabDisplay());
      }

      for (int i = 255; i >= 0; i = i - 10)  
      {  
        textSize(500);
        fill(i);
        text("LIFE", 10, 355, 10);    
        renderToPeggy(grabDisplay());
      }
      background(0);  
      renderToPeggy(grabDisplay());

      delayMilliseconds(1000);    

      background(0);  
      fill(255);
      textSize(400);
      text("LIVE", 10, 355);
      renderToPeggy(grabDisplay());

      delayMilliseconds(200);      

      background(0);  
      fill(255);
      textSize(400);
      text("ONCE", 10, 355);
      renderToPeggy(grabDisplay());

      delayMilliseconds(200);

      background(0);
      renderToPeggy(grabDisplay());

      delayMilliseconds(2000);

      for (int i = 0; i < 10; i++)  
      {
        background(0);  
        fill(255);
        textSize(330);
        text("XPRESS", 10, 330);
        renderToPeggy(grabDisplay());
      }
      for (int i = 0; i < 10; i++)  
      {
        background(0);  
        fill(255);
        textSize(330);
        text("YOUR", 50, 330);
        renderToPeggy(grabDisplay());
      }
      for (int i = 0; i < 20; i++)  
      {
        background(0);  
        fill(255);
        textSize(330);
        text("SELF", 50, 330);
        renderToPeggy(grabDisplay());
      }
      for (int i = 255; i >= 0; i = i - 50)  
      {  
        textSize(500);
        fill(i);
        textSize(330);
        text("SELF", 50, 330);    
        renderToPeggy(grabDisplay());
      }
      background(0);  
      renderToPeggy(grabDisplay());

      for (int i = 0; i < 20; i++)  
      {
        background(0);
        fill(255);
        textSize(440);
        text("YEAH", 10, 330);
        renderToPeggy(grabDisplay());
      }
      for (int i = 0; i < 20; i++)  
      {
        background(255);
        fill(0);
        textSize(440);
        text("YEAH", 10, 330);
        renderToPeggy(grabDisplay());
      }

      strobe(30, 100);     
      background(0); 
      renderToPeggy(grabDisplay());
    }
  }
}

void drawNothing()
{
  background(0);
  renderToPeggy(grabDisplay());
  noLoop();
}

void spectrum()
{
  background(0);
  // perform a forward FFT on the samples in audioPlayer's mix buffer
  // note that if audioPlayer were a MONO file, this would be the same as using audioPlayer.left or audioPlayer.right
  fftLin.forward(audioPlayer.mix);

  // draw the logarithmic averages
  fftLog.forward(audioPlayer.mix);
  int a = fftLog.avgSize()/2;
  int w = int(width/a);
  for (int i = 0; i < a; i++)
  {
    // draw a rectangle for each average, multiply the value by 5 so we can see it better
    rect(i*w, height, i*w + w, height - fftLog.getAvg(i));
  }
  renderToPeggy(grabDisplay());
}

void draw() 
{
  //fade();
  //drawNothing();
  //xpressYourSelf();
  //bounce();
  spectrum();
  
  // noLoop();
}

