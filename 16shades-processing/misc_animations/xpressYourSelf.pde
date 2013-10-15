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
