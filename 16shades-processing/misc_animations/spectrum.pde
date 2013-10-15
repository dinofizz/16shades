void setupSpectrum()
{
  minim = new Minim(this);
  audioPlayer = minim.loadFile("Sunset.mp3", 2048);
  if (playAudio)
  {
    audioPlayer.loop();
  }
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
}

void spectrum()
{
  background(0);
  // perform a forward FFT on the samples in audioPlayer's mix buffer
  // note that if audioPlayer were a MONO file, this would be the same as using audioPlayer.left or audioPlayer.right
  fftLin.forward(audioPlayer.mix);

  // draw the logarithmic averages
  fftLog.forward(audioPlayer.mix);

  // I have chosen to halve the spectrum width, as the interesting pieces
  // are much closer to the lower frequencies IMHO.
  int spectrumSize = fftLog.avgSize()/2;
  int w = int(width/spectrumSize);
  for (int i = 0; i < spectrumSize; i++)
  {
    // draw a rectangle for each average, multiply the value by 5 so we can see it better
    rect(i*w, height, i*w + w, height - fftLog.getAvg(i));
  }
  renderToPeggy(grabDisplay());
}
