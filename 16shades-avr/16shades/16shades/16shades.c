/*
*	 Original code by Jay Clegg 2008.
*	 Modifications by Dino Fizzotti, October 2013.
*    All rights reserved.
*
*    This program is free software: you can redistribute it and/or modify*    it under the terms of the GNU General Public License as published by*    the Free Software Foundation, either version 3 of the License, or*    (at your option) any later version.**    This program is distributed in the hope that it will be useful,*    but WITHOUT ANY WARRANTY; without even the implied warranty of*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the*    GNU General Public License for more details.**    You should have received a copy of the GNU General Public License*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*
*/


/*
[dinofizz] Dino Fizzotti: Including Jay's original comments here! Please check out his project page below
for more information. My comment additions will be prefixed with "[dinofizz]"

Peggy2-serial interface, Copyright 2008 by Jay Clegg.  All rights reserved.

This code is designed for a *modified* version of the Peggy 2.0 board sold by evilmadscience.com
The modification disconnects the pins for TX/RX from the LED driver chips and connects the
SDA/SDL pins in their place.

Please see http://www.planetclegg.com/projects/QC-Peggy.html for explanation of how all
this is supposed to work.

Credits goes to:
Windell H Oskay, (http://www.evilmadscientist.com/)
for creating the Peggy 2.0 kit, and getting 16 shades of gray working
Geoff Harrison (http://www.solivant.com/peggy2/),
for proving that interrupt driven display on the Peggy 2.0 was viable.
*/

// [dinofizz] I am using a 18.432 MHz crystal.
#define F_CPU 18432000UL
#define DD_MOSI PINB5
#define DD_SCK PINB7
#define DDR_SPI DDRB
#define STROBE_PIN PINB4

// [dinofizz] Some helper definitions which I originall found at http://www.ladyada.net/learn/proj1/blinky.html
#define output_low(port,pin) port &= ~(1<<pin)
#define output_high(port,pin) port |= (1<<pin)
#define set_input(portdir,pin) portdir &= ~(1<<pin)
#define set_output(portdir,pin) portdir |= (1<<pin)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <stdio.h>

// [dinofizz] Uncomment the line below if you want the timer interrupt to run at a much reduced
// speed, allowing you to put in some printf's for debugging purposes!
////#define DEBUG_SLOW

// [dinofizz] forward declaration for uartTx.
void uartTx(char data);

////////////////////////////////////////////////////////////////////////////////////////////
// FPS must be high enough to not have obvious flicker, low enough that serial loop has
// time to process one byte per pass.
// 75-78 seems to be about the absolute max for me (with this code),
// but compiler differences might make this maximum value larger or smaller.
// any lower than 60 and flicker becomes apparent.
// note: further code optimization might allow this number to
// be a bit higher, but only up to a point...
// it *must* result in a value for OCR0A  in the range of 1-255

#define FPS 70

// [dinofizz] NB: With w.r.t. my blinds, the "rows" specified below are actually the number
// of vertical blinds
#define NUM_ROWS 48
#define LEDS_PER_ROW 16
#define BITS_PER_LED 4
#define BYTES_PER_ROW (LEDS_PER_ROW * BITS_PER_LED) / 8 // [dinofizz] 8 bits in a byte
#define DISP_BUFFER_SIZE (BYTES_PER_ROW * NUM_ROWS)
#define MAX_BRIGHTNESS 15

////////////////////////////////////////////////////////////////////////////////////////////

void displayInit(void)
{
	set_output(DDRD, PIND2);
	
	PORTC = 0;
	DDRC = 0xFF;
	
	PORTA = 0;
	DDRA = 0xFF;
	// leave serial pins alone
	PORTD &=  (1<<PD1) | (1<<PD0);
	DDR_SPI = (1<<DD_MOSI)|(1<<DD_SCK)|(1<<STROBE_PIN);
	
	// [dinofizz] Set up and enable hardware SPI.
	SPCR = (1<<SPE) | (1<<MSTR);
	SPSR = (1<<SPI2X);

	// setup the interrupt.
	
	#ifdef DEBUG_SLOW
	TCCR1A = 0x00;
	TCCR1B = 0x02; // [dinofizz] lower this number the slower the interrupt
	//OCR1AH = 0x7A;
	//OCR1AL = 0x11;
	TIMSK1 = 0x01;
	TCNT1=0x0000;
	#else
	TCCR0A = (1<<WGM01); // clear timer on compare match
	TCCR0B = (1<<CS01); // timer uses main system clock with 1/8 prescale
	OCR0A  = (F_CPU >> 3) / NUM_ROWS / MAX_BRIGHTNESS / FPS; // Frames per second * 15 passes for brightness * 25 rows
	TIMSK0 = (1<<OCIE0A);	// call interrupt on output compare match
	#endif
}

// [dinofizz] Remember, the "rows" in my case are the vertical blinds!
void setCurrentRow(uint8_t row, uint8_t spi_first, uint8_t spi_second)
{
	uint8_t portC = 0;
	uint8_t portA = 0;

	//uartTx(row);
	
	// [dinofizz] Conditionals to determine which demultiplexer is being currently used.
	// PORTC:0..3 is the first demultiplexor, for rows 0..15. It is enabled when PINA4 is LOW.
	// PORTC:4..7 is the middle demultiplexor, for rows 16..32. It is enabled when PINA5 is LOW.
	// PORTA:0..3 is the last demultiplexor, for rows 33..47. It is enabled when PINA6 is LOW.
	
	if (row <= 15) // Want PINA4 = LOW; PINA5 = PIN6 = HIGH
	{
		portA |= (1 << PINA5);
		portA |= (1 << PINA6);
		portC = row;
	}
	else if (row <= 31) // Want PINA5 = LOW; PINA4 = PIN6 = HIGH
	{
		portA |= (1 << PINA4);
		portA |= (1 << PINA6);
		portC = (row << 4);
	}
	else // Want PINA6 = LOW; PINA4 = PIN5 = HIGH
	{
		portA |= (1 << PINA4);
		portA |= (1 << PINA5);
		portA |= row;
	}

	// set row values.  Wait for xmit to finish.
	// Note: wasted cycles here, not sure what I could do with them,
	// but it seems a shame to waste 'em.
	SPDR = spi_first;
	//uartTx(spi3);
	while (!(SPSR & (1<<SPIF)))  { }
	SPDR = spi_second;
	//uartTx(spi4);
	while (!(SPSR & (1<<SPIF)))  { }

	// [dinofizz] flipping this strobe pin latches the LED driver outputs.
	PORTB |= (1<<STROBE_PIN);

	PORTC = portC;
	PORTA = portA;
	
	PORTB &= ~((1<<STROBE_PIN));
}

uint8_t frameBuffer[DISP_BUFFER_SIZE];
uint8_t *rowPtr;
uint8_t currentRow = 50;
uint8_t currentBrightness = 20;
uint8_t currentBrightnessShifted = 20;

#ifdef DEBUG_SLOW
SIGNAL(TIMER1_OVF_vect)
#else
SIGNAL(TIMER0_COMPA_vect)
#endif
{
	// there are 15 passes through this interrupt for each row per frame.
	// ( 15 * 16) = 240 times per frame. [dinofizz] edit to match my configuration.
	// during those 15 passes, a led can be on or off.
	// if it is off the entire time, the perceived brightness is 0/15
	// if it is on the entire time, the perceived brightness is 15/15
	// giving a total of 16 average brightness levels from fully on to fully off.
	// currentBrightness is a comparison variable, used to determine if a certain
	// pixel is on or off during one of those 15 cycles.   currentBrightnessShifted
	// is the same value left shifted 4 bits:  This is just an optimization for
	// comparing the high-order bytes.
	
	//uartTx(currentRow);
	//uartTx(currentBrightness);
	
	currentBrightnessShifted+=16; // equal to currentBrightness << 4
	
	if (++currentBrightness >= MAX_BRIGHTNESS)
	{
		currentBrightnessShifted=0;
		currentBrightness=0;
		if (++currentRow > (NUM_ROWS - 1))
		{
			currentRow =0;
			rowPtr = frameBuffer;
		}
		else
		{
			rowPtr += BYTES_PER_ROW;
		}
	}
	
	// rather than shifting in a loop I manually unrolled this operation
	// because I couldnt seem to coax gcc to do the unrolling it for me.
	// (if much more time is taken up in this interrupt, the serial service routine
	// will start to miss bytes)
	// This code could be optimized considerably further...
	
	uint8_t * ptr = rowPtr;
	uint8_t p, spi_first, spi_second;
	
	spi_first=spi_second=0;
	
	// pixel order is, from left to right on the display:
	//  low order bits, followed by high order bits
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_first|=1;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_first|=2;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_first|=4;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_first|=8;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_first|=16;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_first|=32;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_first|=64;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_first|=128;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_second|=1;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_second|=2;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_second|=4;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_second|=8;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_second|=16;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_second|=32;
	p = *ptr++;
	if ((p & 0x0f) > currentBrightness)  		spi_second|=64;
	if ((p & 0xf0) > currentBrightnessShifted)	spi_second|=128;
	
	setCurrentRow(currentRow, spi_second,spi_first);
}

////////////////////////////////////////////////////////////////////////////////////////////
// Serial IO routines
////////////////////////////////////////////////////////////////////////////////////////////


// must be 1 or zero. U2X gets set to this.
#define USART_DOUBLESPEED   1
#define _USART_MULT  (USART_DOUBLESPEED ? 8L : 16L )
#define CALC_UBBR(baudRate, xtalFreq) (  (xtalFreq / (baudRate * _USART_MULT))  - 1 )

void uartInit(unsigned int ubbrValue)
{
	// set baud rate
	UBRR0H = (unsigned char) (ubbrValue>>8);
	UBRR0L = (unsigned char) ubbrValue;
	
	//UBRR0 = 9;
	// Enable 2x speed
	if (USART_DOUBLESPEED)
	{
		UCSR0A = (1<<U2X0);
	}

	// Async. mode, 8N1
	UCSR0C = /* (1<<URSEL0)| */(0<<UMSEL00)|(0<<UPM00)|(0<<USBS0)|(3<<UCSZ00)|(0<<UCPOL0);

	UCSR0B = (1<<RXEN0)|(1<<TXEN0)|(0<<RXCIE0)|(0<<UDRIE0);
}

// send a byte thru the USART
void uartTx(char data)
{
	// wait for port to get free
	while (!(UCSR0A & (1<<UDRE0))) { }
	UDR0 = data;
}

// get one byte from usart (will wait until a byte is in buffer)
uint8_t uartRxGetByte(void)
{
	while (!(UCSR0A & (1<<RXC0))) { } // wait for char
	//unsigned char temp = UDR0;
	//uartTx(temp);
	return UDR0;
}

// check to see if byte is ready to be read with uartRx
uint8_t uartRxHasChar(void)
{
	return  (UCSR0A & (1<<RXC0)) ? 1 : 0;
}


////////////////////////////////////////////////////////////////////////////////////////////
// MAIN LOOP: service the serial port and stuff bytes into the framebuffer
////////////////////////////////////////////////////////////////////////////////////////////

void serviceSerial(void)
{
	uint8_t *ptr = frameBuffer;
	int state = 0;
	int counter = 0;
	while (1)
	{
		uint8_t c = uartRxGetByte();
		
		// very simple state machine to look for 6 byte start of frame
		// marker and copy bytes that follow into buffer
		if (state < 6)
		{

			// must wait for 0xdeadbeef to start frame.
			// note, I look for two more bytes after that, but
			// they are reserved for future use.
			
			if (state == 0 && c == 0xde)
			{
				state++;
			}
			else if (state ==1 && c == 0xad) state++;
			else if (state ==2 && c == 0xbe) state++;
			else if (state ==3 && c == 0xef) state++;
			else if (state ==4 && c == 0x01) state++;
			else if (state ==5 && c == 0x02)  // [dinofizz] added this check for '2' during debugging
			{
				state++;
				counter = 0;
				ptr = frameBuffer;
				// [dinofizz] debug LED I have to indicate I recieved a frame header (for debugging).
				output_high(PORTD,PIND2);
			}
			else state = 0; // error: reset to look for start of frame
		}
		else
		{
			// inside of a frame, so save each byte to buffer
			*ptr++ = c;
			counter++;
			if (counter >= DISP_BUFFER_SIZE)
			{
				// buffer filled, so reset everything to wait for next frame
				//counter = 0;
				//ptr = frameBuffer;
				state = 0;
			}
		}
	}
}


int main(void)
{
	uartInit(CALC_UBBR(230400, F_CPU));
	displayInit();
	
	uint8_t *ptr = frameBuffer;

	// [dinofizz] fills the frame so that the display is all "on" at startup.
	for (int i =0; i < DISP_BUFFER_SIZE; i++)
	{
		*ptr++ = 0xFF;
	}
	
	sei();
	serviceSerial();  // never returns
	return 0; // keep compiler happy
}