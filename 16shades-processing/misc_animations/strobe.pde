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
