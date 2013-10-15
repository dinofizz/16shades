int fadeTemp = 0;

void fade()
{
  int backgroundCol = 0;
  if (fadeTemp == 16)
  {
    backgroundCol = 255;
    fadeTemp = 0;
  }
  else
  {
    fadeTemp++;
    backgroundCol = fadeTemp * 16;
  }

  //println(backgroundCol);
  background(backgroundCol);
  renderToPeggy(grabDisplay());
}
