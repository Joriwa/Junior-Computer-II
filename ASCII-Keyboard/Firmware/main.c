/*
 * main.c
 *
 *  Junior Computer ][ Keyboard Firmware
 *
 *  Distributed under the Creative Commons Attribution 4.0 International License
 *  (see https://creativecommons.org/licenses/by/4.0/)
 *
 *  Created: 1/12/2023 5:09:44 PM
 *  Author: Jörg Walke
 *
 *  https://www.old-computer-tech.net
 */ 

#include <xc.h>

#define F_CPU  8000000L

#include <util/delay.h>

// Defined PortD pin constants

#define CLS       0x01 // ClearScreen output
#define P0        0x02 // P0 configuration input
#define P1        0x04 // P1 configuration input
#define LOCK_LED  0x08 // CapsLock Locked LED output
#define RESET     0x10 // Reset input/output
#define STROBE    0x20 // Key Strobe output
#define CAPS_LOCK 0x40 // CapsLock key input

// Some key codes

#define _RESET  255
#define _ALT    254
#define _SHIFTR 253
#define _SHIFTL 252
#define _CTRL   251
#define _NONE   250
#define _HOME   249

// Modifier key masks

#define CTRL_KEYS  0x08
#define SHIFT_KEYS 0x30

// Miscellaneous constants

#define DEBOUNCE_TIME 10    // debounce time in ms for caps lock key
#define SETTLE_TIME   20    // time in us between key checks

#define TYPEMATIC_RATE 25  // standard typematic rate in chars/s
#define REPEAT_DELAY   500 // standard delay before autorepeat in ms

// Global variables

uint8_t  capsLock      = 0; // caps lock status
uint8_t  capsLockUp    = 1; // caps lock key up mutex

uint8_t  keyStates[8];      // current key state list
uint8_t  lastStates[8];		// last key state list
uint16_t debounceCount = 0; // counter for key debounce timer
uint16_t delayCount    = 0; // counter for repeat delay timer
uint16_t repeatCount   = 0; // counter for repeat timer
uint8_t  modifierKeys;      // all modifier keys (CTRL SHIFT_L SHIFT_R)
uint8_t  lastModifiers;     // saved last modifiers
uint8_t  modifier;		    // modifier value (00 = Normal, 01 = Shift, 10 = Ctrl, 11 Shift+Ctrl)
uint8_t  currentKey;        // current pressed key
uint8_t  lang;              // keyboard language

uint8_t  autoRepeat    = 0; // signal that auto repeat is on

uint32_t repeatValue;       // initial repeat timer counter value
uint32_t delayValue;        // initial delay before-auto-repeat-timer counter value

char    *NormalChar;
uint8_t *ShiftChar;


// English US Keyboard Table

// Table of normal (unshifted) ASCII codes

  
                               // SPC    '   CR CTRL  SHL  SHR    ´   UP 
char NormalChar_US[64] =         { 32,  39,  13, 251, 252, 253,  96,  11,
	                           //  BS HOME PRNT    \    [    ]  DEL DOWN
									8, 249,  20,  92,  91,  93, 127,  10,
							   //   .    l    p    -    =    0    ;    /    		
								   46, 108, 112,  45,  61,  48,  59,  47,
							   //   m    j    i    o    9    8    k    ,	   
								  109, 106, 105, 111,  57,  56, 107,  44,
							   //   b    g    y    u    7    6    h    n	  
								   98, 103, 121, 117,  55,  54, 104, 110,
							   //   c    d    r    t    5    4    f    v	   
								   99, 100, 114, 116,  53,  52, 102, 118,
							   //   z    a    w    e    3    2    s    x	   
								  122,  97, 119, 101,  51,  50, 115, 120,
							   //LEFT RIGHT ESC    q    1   F3   F2   F1  
								    8,  21,  27, 113,  49,  19,  18,  17 };
									
// Table of shifted ASCII codes

                               // SPC    "   CR CTRL  SHL  SHR    ~   UP
uint8_t ShiftChar_US[64] =       { 32,  34,  13, 251, 252, 253, 126,  11,
		                       //  BS HOME PRNT    |    {    }  DEL DOWN
									8, 249,  20, 124, 123, 125, 127,  10,
							   //   >    L    P    _    +    )    :    ?
								   62,  76,  80,  95,  43,  41,  58,  63,
							   //   M    J    I    O    (    *    K    <
								   77,  74,  73,  79,  40,  42,  75,  60,
							   //   B    G    Y    U    &    ^    H    N
								   66,  71,  89,  85,  38,  94,  72,  78,
							   //   C    D    R    T    %    $    F    V
								   67,  68,  82,  84,  37,  36,  70,  86,
							   //   Z    A    W    E    #    @    S    X
								   90,  65,  87,  69,  35,  64,  83,  88,
							   //LEFT RIGHT ESC    Q    !   F3   F2   F1
								    8,  21,  27,  81,  33,  30,  29,  28 };
									

									
// German Keyboard Table

// Table of normal (unshifted) ASCII codes

                               // SPC    '   CR CTRL  SHL  SHR    ´   UP
char NormalChar_DE[64] =         { 32,  39,  13, 251, 252, 253,  96,  11,
	                           //  BS HOME PRNT    \    [    ]  DEL DOWN
	                                8, 249,  20,  92,  91,  93, 127,  10,
	                           //   .    l    p    -    =    0    ;    /
	                               46, 108, 112,  45,  61,  48,  59,  47,
	                           //   m    j    i    o    9    8    k    ,
	                              109, 106, 105, 111,  57,  56, 107,  44,
	                           //   b    g    z    u    7    6    h    n
	                               98, 103, 122, 117,  55,  54, 104, 110,
	                           //   c    d    r    t    5    4    f    v
	                               99, 100, 114, 116,  53,  52, 102, 118,
	                           //   y    a    w    e    3    2    s    x
	                              121,  97, 119, 101,  51,  50, 115, 120,
	                           //LEFT RIGHT ESC    q    1   F3   F2   F1
                                    8,  21,  27, 113,  49,  19,  18,  17 };

// Table of shifted ASCII codes

                               // SPC    "   CR CTRL  SHL  SHR    ~   UP
uint8_t ShiftChar_DE[64] =       { 32,  34,  13, 251, 252, 253, 126,  11,
	                           //  BS HOME PRNT    |    {    }  DEL DOWN
		                            8, 249,  20, 124, 123, 125, 127,  10,
	                           //   >    L    P    _    +    )    :    ?
	                               62,  76,  80,  95,  43,  41,  58,  63,
	                           //   M    J    I    O    (    *    K    <
	                               77,  74,  73,  79,  40,  42,  75,  60,
	                           //   B    G    Z    U    &    ^    H    N
	                               66,  71,  90,  85,  38,  94,  72,  78,
	                           //   C    D    R    T    %    $    F    V
	                               67,  68,  82,  84,  37,  36,  70,  86,
	                           //   Y    A    W    E    #    @    S    X
	                               89,  65,  87,  69,  35,  64,  83,  88,
	                           //LEFT RIGHT ESC    Q    !   F3   F2   F1
                                    8,  21,  27,  81,  33,  30,  29,  28 };

									
									
// *** Set typematic rate in chars/s
								
void SetTypematicRate(uint32_t typmaticRate) {
	
	repeatValue = 1000000/(8*SETTLE_TIME*typmaticRate)-48;
}

// Set auto repeat delay time in ms

void SetDelayTime(uint32_t delayTime) {
	
	delayValue = (delayTime*1000)/(8*SETTLE_TIME);
}

// *** Toggle CapsLock LED

void Toggle_LED() {
	
	if (capsLock) PORTD |= LOCK_LED;	// LED off
	else PORTD &= ~LOCK_LED;			// LED on
	capsLock = !capsLock;
}

// *** Reset keyboard to standard values;

void ResetKeyboard() {
	
	SetTypematicRate(TYPEMATIC_RATE);
	SetDelayTime(REPEAT_DELAY);
	currentKey = _NONE;
	for (uint8_t i = 0; i <= 7; i++) {
		keyStates[i]  = 0;
		lastStates[i] = 0;
	}
	// Read configuration jumpers
	
	if ((PIND & P0) == 0) lang  = 2;
	else lang = 0;
	if ((PIND & P1) == 0) lang |= 1;
	
	switch (lang)
	{
	case 0:
		NormalChar = NormalChar_US;
		ShiftChar  = ShiftChar_US;
		break;
	case 1:
	    NormalChar = NormalChar_DE;
	    ShiftChar  = ShiftChar_DE;
		break;
	case 2:
	  NormalChar = NormalChar_US;
	  ShiftChar  = ShiftChar_US;
	  break;
	case 3:
	  NormalChar = NormalChar_US;
	  ShiftChar  = ShiftChar_US;
	  break;
	}
	         
	
	PORTC  = 129;
}

// *** Check if incoming reset

void CheckReset() {
	
	if ((PIND & RESET) == 0) {
		_delay_ms(250);
		Toggle_LED();
		ResetKeyboard();
		_delay_ms(250);
		Toggle_LED();
		while ((PIND & RESET) == 0); // wait until reset line is HIGH
	}
}

// *** Initialize the keyboard

void InitKeyboard() {
	
	DDRA  = 0x00; // keyboard rows are all inputs
	PORTA = 0xFF; // enable all pull up resistors for row lines input
	DDRC  = 0xFF; // ASCII output port
	DDRD  = 0x29; // 6:CAPS_LOCK = I; 5:~STRB = O; 4:~RES = I/O; 3:LOCK_LED = O; 2:P1 = I; 1:P0 = I; 0:CLS = O
	PORTD = 0xFE;
	ResetKeyboard();
}

// *** Check if Caps Lock key is pressed

void CheckCapsLock() {
	
	if (capsLockUp) {
		if ((PIND & CAPS_LOCK) == 0) { // Caps Lock down
			_delay_ms(DEBOUNCE_TIME);
			Toggle_LED();
			capsLockUp = 0; // lock mutex
			autoRepeat = 0; // switch auto repeat off
		}
	}
	else {
		if (PIND & CAPS_LOCK) { // Caps Lock up
			_delay_ms(DEBOUNCE_TIME);
			capsLockUp = 1; // unlock mutex
		}
	}
}

// *** Set RESET line LOW for 250ms

void SignalReset() {
	
	DDRD  |= RESET;  // set pin 4 as output
	PORTD &= ~RESET; // set pin 4 LOW
	_delay_ms(250);
	PORTD |= RESET;  // set pin 4 HIGH
	DDRD &= ~RESET;  // set pin 4 as input
	delayCount = 0;
}

// *** Set CLS/HOME line HIGH for 25ms

void SignalCLS() {
	
	PORTD |= CLS;
	_delay_ms(25);
	PORTD &= ~CLS;
	delayCount = 0;
}

// *** Set Strobe LOW for 2us

void SignalStrobe() {
	
	PORTC = PORTC & 0x7F;  // reset bit7 to 0
	_delay_us(5);		   
	PORTC = PORTC | 0x80;  // set bit 7 to 1. Rising edge of bit7 is used by the Junior Computer ][ as data_avail flag
	_delay_us(2);          // data settle time
	PORTD &= ~STROBE;      // reset strobe to 0
	_delay_us(2);
	PORTD |= STROBE;	   // set strobe to 1	
}

// *** Send ASCII character to parallel port

void SendASCII(uint8_t code, uint8_t state) {
	
	if (state) {
		if (code == _RESET) SignalReset();
		else if (code < _NONE) {
			if (code == _HOME) {
				SignalCLS();
				code = 1;
			}
			PORTC = code | 0x80; // set ASCII code to output port and set MSB
			SignalStrobe();
		}
	}
	else PORTC = code | 0x80;    // set ASCII code to output port and set MSB
}

// *** Convert key matrix code into ASCII code

uint8_t GetASCII(uint8_t code) {
	
    uint8_t asciiCode = _NONE;
	if (code > 127) return asciiCode;
	switch (modifier) {
		case 0: asciiCode = NormalChar[code]; // get normal ASCII code
		    if (capsLock == 1 && asciiCode >= 97 && asciiCode <= 122) asciiCode -= 32; // if caps lock then make lower case letters upper case
			break;
		case 1: asciiCode = ShiftChar[code];  // get shifted ASCII code
		    if (capsLock == 1 && asciiCode >= 65 && asciiCode <= 90) asciiCode += 32; // if caps lock then make upper case letters lower case
			break;
		case 2:
		case 3: asciiCode = NormalChar[code]; // get normal ASCII code
		    if (asciiCode == 127 && modifier == 3) asciiCode = _RESET;     // Ctrl+Shift+Del pressed -> send RESET
			else if (asciiCode >= 96 && asciiCode <= 127) asciiCode -= 96; // generate control codes
			else if (asciiCode ==  8) asciiCode = 6;                       // left arrow becomes horizontal back tab
			else if (asciiCode == 10) asciiCode = 12;                      // down arrow becomes page down
			else if (asciiCode == 11) asciiCode = 24;                      // up arrow becomes page up
			else if (asciiCode == 21) asciiCode = 9;                       // right arrow becomes horizontal tab
			else if (asciiCode < 127) asciiCode = _NONE;			       // ignore all other chars
			break;
	}
	return asciiCode;
}

// *** Send key code to configured output port

void SendKeyCode(uint8_t key, uint8_t state) {
	
	if (state) currentKey = key;
	else if (key == currentKey) currentKey = _NONE;
	uint8_t asciiCode = GetASCII(currentKey);
	SendASCII(asciiCode,state); // send ASCII code to parallel port
}

// *** Check if any modifier key (Ctrl/Shift) is pressed, else return key state for current column

uint8_t CheckKeys(uint8_t col) {
	
	uint8_t keys = keyStates[col];
	if (col == 0) {							   // all modifier keys are in column 0
		modifier = 0;
		if (keys & SHIFT_KEYS) modifier = 1;   // any shift key pressed?
		if (keys & CTRL_KEYS)  modifier |= 2;  // any control key pressed?
		lastModifiers = modifierKeys;          // save last modifier state
		modifierKeys  = (keys >> 3) & 7;	   // get single modifier key status
		keys          &= 0xC7;				   // remove modifier keys from result
		lastModifiers ^= modifierKeys;		   // check for differences
		if (lastModifiers) {                   // any modifier key changed?
			if (lastModifiers & 1) SendKeyCode(_CTRL,   modifierKeys & 1);
			if (lastModifiers & 2) SendKeyCode(_SHIFTL, modifierKeys & 2);
			if (lastModifiers & 4) SendKeyCode(_SHIFTR, modifierKeys & 4);
		}
	}
	return keys;
}

// *** Scan keyboard matrix

void ScanKeys() {

	uint8_t keyState, changedKeys;
	for (uint8_t col = 0; col <= 7; col++) { // move a 0 bit through all column lines
		DDRB  = 1 << col;    // set all other columns as input to prevent short
		PORTB = ~(1 << col); // set current column to low
		_delay_us(SETTLE_TIME);
		keyState = ~PINA;
		if (keyState != keyStates[col]) { // any key has changed
			keyStates[col] = keyState;    // store new key state
			debounceCount  = 63;          // reset debounce timer to a total of 8*SETTLE_TIME*63 microseconds
			delayCount     = delayValue;  // reset delay counter
			autoRepeat     = 0;           // switch auto repeat off
		}
	}
	if (debounceCount == 1) {                    // no more keys has changed and debounce timer is over. Read the pressed keys.
		for (uint8_t col = 0; col <= 7; col++) { // move through all column lines
			keyState    = CheckKeys(col);
			changedKeys = keyState ^ lastStates[col];
			if (changedKeys) {                           // is any key in column changed?
				lastStates[col] = keyState;
				for (uint8_t row = 0; row <= 7; row++) { // check all rows if any is changed
					if (changedKeys & (1 << row)) {      // key at row/col is changed
						keyState = keyState & (1 << row);
						uint8_t key = 8*col+row;
						SendKeyCode(key,keyState);
					}
				}
			}
		}
	}
	else if ((currentKey != _NONE) && (debounceCount == 0)) { // start delay counter before auto repeat
		if (delayCount == 1) { // start auto repeat function
			autoRepeat  = 1;
			repeatCount = repeatValue;
		} 
		if (delayCount) delayCount--;
	}
	if (debounceCount) debounceCount--;
}

// *** Main loop

int main(void) {
	
	InitKeyboard();
    while(1) { 
		CheckReset();
		CheckCapsLock();
		ScanKeys();
		if (autoRepeat) {
			if (repeatCount) repeatCount--;
			else {
				repeatCount = repeatValue;
				if (currentKey < _NONE) SignalStrobe();
			}
		}
    }
}