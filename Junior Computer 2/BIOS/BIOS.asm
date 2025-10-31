;{ASSEMBLER=A65}

; ******************************************************************************
; Junior Computer ][ BIOS Version 1.1.6
; by Joerg Walke
;
; first implementation 28.12.2021
; updated 24.10.2025
; by Joerg Walke
;
; Assembled With A65
;
; 20.03.2023
; A bug in the disassembler code was fixed by the
; German Classic Computing forum user jet2bue. See version history
;
; 01.08.2023
; A bug in SD_WR_BLK was fixed. The bug was found by German Classic Computing
; forum user Dietrich Lausberg. See version history
;
; 29.04.2024
; SPI & IRQ optimization by Dietrich Lausberg
;
; 26.05.24
; Changes in Fast SPI by Dietrich Lausberg
;
; ******************************************************************************
; To Do: (maybe in this order)
;
;  Paper Tape Reader Driver
;  ...and many more...
; ******************************************************************************

VERMAIN   	EQU     '1'    		; BIOS main version
VERPSUB    	EQU     '1'    		; BIOS primary sub version
VERSSUB		EQU	'6'		; BIOS secondary sub version

RETURN_VECT     EQU     $0001           ; return vector to monitor caller
RESET     	EQU  	$1C1D       	; original junior monitor reset vector

; Buffers **********************************************************************

STRBUF	  	EQU   	$1400    	; input string buffer at $1400

RBUFF     	EQU   	$1500    	; xmodem receive buffer at $1500

; Card Base Addresses **********************************************************

IOBASE		EQU	$14		; pointer to IO card base
IOBASEL		EQU	$14		; always $00
IOBASEH		EQU	$15		; K2 = $08, K3 = $0C, K4 = $10

FGCBASE	        EQU	$16		; pointer to Floppy-/Graphics-Controller card base
FGCBASEL	EQU	$16		; always $00
FGCBASEH	EQU	$17		; (K2 = $08, K3 = $0C,) should always K4 = $10

CARD3BASE	EQU	$18		; reserved (controller base)
CARD3BASEL	EQU	$18		; always $00
CARD3BASEH	EQU	$19		; K2 = $08, K3 = $0C, K4 = $10

; ******************************************************************************

FDC_MOTOR       EQU     $C1             ; current motor status

; ******************************************************************************

TICKCNT         EQU     $DA             ; current tick counter

; SPI/SD-Card Reader Variables *************************************************

SD_TYPE		EQU	$DB		; SD Card Type

; ACIA And Terminal Variables **************************************************

PSTR      	EQU   	$EA      	; output string Pointer
PSTRL     	EQU   	$EA      	; lower address byte of output string pointer
PSTRH     	EQU   	$EB      	; upper address byte of output string pointer
WBUF      	EQU   	$EC      	; ACIA character output buffer

; ******************************************************************************

DEVID		EQU	$03		; temp device id

; Device Driver Variables ******************************************************

PDEV		EQU	$DE		; device descriptor pointer
PDEVL    	EQU   	$DE      	; device descriptor pointer lo byte
PDEVH    	EQU   	$DF      	; device descriptor pointer hi byte

; XModem Transfer Variables ****************************************************

CRCL      	EQU   	$DC      	; CRC lo byte
CRCH      	EQU   	$DD     	; CRC hi byte

RETRYL    	EQU   	$DE      	; retry counter lo byte
RETRYH    	EQU   	$DF      	; retry counter hi byte

BLKEND      	EQU     $E0		; block end flag
BFLAG     	EQU   	$E1      	; block flag
BLKNO     	EQU   	$E2      	; block number
ERRCNT    	EQU   	$E3      	; error counter 10 is the limit

; Disassembler Variables *******************************************************

OPCODE		EQU	$E0		; current opcode
LINECNT		EQU	$E1		; number of disassembled lines
ADRMODE		EQU	$E2		; addressing mode
IBYTES		EQU	$E3		; instruction byte count

; I2C Variables ****************************************************************

I2C_DATA	EQU	$E0		; current I2C data byte

; TTY Variables ****************************************************************

BAUDRATE  	EQU   	$E0    		; current baud rate

; Tape Reader/Writer Variables *************************************************

CHECKSUM	EQU	$DC		; file checksum
OUTBYTE		EQU	$DD		; data byte read/written from/to tape

EQUFLAG		EQU	$E1		; file name equal flag

KEY_SENSE	EQU	$E5		; datasette key sense flag
BITCNT		EQU	$ED		; current read bit count

; SD-Card Command Buffer *******************************************************

SD_CMD		EQU	$DE		; CMD Byte
SD_PB3      	EQU   	$DF   		; Parameter Byte 3
SD_PB2		EQU   	$E0   		; Parameter Byte 2
SD_PB1      	EQU   	$E1   		; Parameter Byte 1
SD_PB0		EQU	$E2   		; Parameter Byte 0
SD_CRC		EQU	$E3   		; CRC Byte

BLKBUF		EQU	$DC             ; pointer to block buffer
BLKBUFL		EQU	$DC             ; lower byte of block buffer pointer
BLKBUFH		EQU	$DD             ; upper byte of block buffer pointer

; Pointer to Logical Block Address *********************************************

PLBA		EQU	$E6		; LBA pointer
PLBAL		EQU	$E6		; LBA pointer low byte
PLBAH		EQU	$E7		; LBA pointer high byte

; VIA2 Variables ***************************************************************

VIA_STATUS 	EQU	$E4 		; current VIA2 PortB output status

; Hex Monitor Variables ********************************************************

ASCL	  	EQU   	$E6     	; ASCII list start address low
ASCH      	EQU   	$E7     	; ASCII list start address high

STOL      	EQU   	$E8     	; store address Low
STOH      	EQU   	$E9     	; store address High

NUML      	EQU   	$F8     	; low number byte
NUMH	  	EQU   	$F9	 	; high number byte
ADRL      	EQU   	$FA     	; last address Low
ADRH      	EQU   	$FB     	; last address High
TEMP      	EQU   	$FC     	; temp storage
YSAV      	EQU   	$FD     	; Y register storage
PDBCNT    	EQU   	$FE     	; number of printed data bytes
MODE      	EQU   	$FF     	; current edit mode

PSAV            EQU     $EE

; Number String ****************************************************************

DIG0      	EQU   	$F8     	; 10^0 digit
DIG1	  	EQU   	$F9	 	; 10^1 digit
DIG2      	EQU   	$FA     	; 10^2 digit

; CPU Register Save ************************************************************

PCL		EQU	$EF		; program counter Low
PCH		EQU	$F0		; program counter High
PREG		EQU	$F1		; processor status register
SPUSER		EQU	$F2		; stack pointer
ACC		EQU	$F3		; accumulator
YREG		EQU	$F4		; y-register
XREG		EQU	$F5		; x-register

; Clock Variables **************************************************************

DIVCHAR		EQU	$F2             ; current divider char (. or / for date : for time)

; ACIA Registers ***************************************************************

DATA_REG  	EQU   	$1600    	; ACIA Data Register
STAT_REG  	EQU   	$1601    	; ACIA Status Register
COMM_REG  	EQU   	$1602    	; ACIA Command Register
CTRL_REG  	EQU   	$1603    	; ACIA Control Register

; RIOT RAM Area ****************************************************************

IO_INFO         EQU     $1A00           ; Initialization info call for IO card

KEY_HANDLER     EQU     $1A24           ; character input handler
NKEY_HANDLER    EQU     $1A26           ; no character input handler
DEVLIST		EQU	$1A28		; start of device driver list

STDBEEP		EQU	$1A66		; current standard beep routine
DEVIN		EQU	$1A68		; current opened device input routine
DEVOUT		EQU	$1A6A		; current opened device output routine
DEVCMD		EQU	$1A6C		; current opened device command routine
STDIN		EQU	$1A6E		; current standard input routine
STDOUT		EQU	$1A70		; current standard output routine
STDCMD		EQU	$1A72		; current standard command routine
STDINDEV  	EQU   	$1A74    	; absolut standard input device id
STDOUTDEV  	EQU   	$1A75    	; absolut standard output device id
STDPRINTDEV	EQU	$1A76		; absolutstandard printer device id
STOACC		EQU	$1A77		; last accumulator before interrupt

; Interrupt Vectors ************************************************************

BRKUSR		EQU	$1A78		; address of user BREAK vector
NMIVECT		EQU     $1A7A           ; address of NMI vector
IRQUSR  	EQU   	$1A7C    	; address of user IRQ vector
IRQVECT  	EQU   	$1A7E    	; address of main IRQ vector

; Timer Register ***************************************************************

CNTA	  	EQU	$1A94	 	; CLK/1T no interrupt
CNTB	  	EQU	$1A95	 	; CLK/8T no interrupt
CNTC	  	EQU	$1A96	 	; CLK/64T no interrupt
CNTD	  	EQU	$1A97    	; CLK/1024T no interrupt

CNTIRQ		EQU	$1A9F		; Timer Interrupt Register

; Port Register ****************************************************************

PAD		EQU     $1A80		; Port A Data Register
PADD		EQU	$1A81		; Port A Data Direction Register
PBD		EQU	$1A82		; Port B Data Register
PBDD		EQU	$1A83		; Port B Data Direction Register

WRDC		EQU	$1A85		; Write = set positive edge detection, no int.
					; Read = get Edge Control Interrupt Register

; IO Base Addresses ************************************************************

K2		EQU	$0800		; Base address of IO select K2
K3		EQU	$0C00		; Base address of IO select K3
K4		EQU	$1000		; Base address of IO select K4

; PIA Register Indices *********************************************************

PIA_PORTA       EQU     $0C             ; Port A input/output register
PIA_PORTB       EQU     $0D             ; Port B input/output register
PIA_PORTC       EQU     $0E             ; Port C input/output register
PIA_CONTROL     EQU     $0F             ; Control/Setup register

; VIA 1 Register Indices *******************************************************

VIA_PORTB     	EQU  	$00  		; Port B input/output register
VIA_PORTA     	EQU  	$01  		; Port A input/output register
VIA_DDRB   	EQU  	$02		; Port B data direction register
VIA_DDRA   	EQU  	$03		; Port A data direction register
VIA_T1CL   	EQU  	$04		; Timer 1 counter low byte register
VIA_T1CH   	EQU  	$05		; Timer 1 counter high byte register
VIA_T1LL   	EQU  	$06		; Timer 1 latched counter low byte register
VIA_T1LH   	EQU  	$07		; Timer 1 latched counter high byte register
VIA_T2CL   	EQU  	$08		; Timer 2 counter low byte register
VIA_T2CH   	EQU  	$09		; Timer 2 counter high byte register
VIA_SR     	EQU  	$0A		; Shift register
VIA_ACR    	EQU  	$0B		; Auxilary control register
VIA_PCR    	EQU  	$0C		; Periheral control register
VIA_IFR    	EQU  	$0D		; Interrupt flag register
VIA_IER    	EQU  	$0E		; Interrupt enable register
VIA_PANOHS 	EQU  	$0F

; VIA 2 Register Indices *******************************************************

PORTB     	EQU  	$10  		; Port B input/output register
PORTA     	EQU  	$11  		; Port A input/output register
DDRB   		EQU  	$12		; Port B data direction register
DDRA   		EQU  	$13		; Port A data direction register
T1CL   		EQU  	$14		; Timer 1 counter low byte register
T1CH   		EQU  	$15		; Timer 1 counter high byte register
T1LL   		EQU  	$16		; Timer 1 latched counter low byte register
T1LH   		EQU  	$17		; Timer 1 latched counter high byte register
T2CL   		EQU  	$18		; Timer 2 counter low byte register
T2CH   		EQU  	$19		; Timer 2 counter high byte register
SR     		EQU  	$1A		; Shift register
ACR    		EQU  	$1B		; Auxilary control register
PCR    		EQU  	$1C		; Peripheral control register
IFR    		EQU  	$1D		; Interrupt flag register
IER    		EQU  	$1E		; Interrupt enable register
PANOHS 		EQU  	$1F

; Pointer To Programming Language Name *****************************************

LANGKEY		EQU     $DFF0
LANGNAME	EQU	LANGKEY+1

; Constants ********************************************************************

CENTURY		EQU	$20		; the 20th century. change to travel in time

DATEDIV		EQU	'.'		; divider char for date string
TIMEDIV		EQU	':'		; divider char for time string

PROMPT    	EQU     '*'    		; prompt character
ADIV      	EQU     '-'    		; address divider
BS        	EQU     $08    		; backspace key
CR        	EQU     $0D    		; carriage return
LF	  	EQU     $0A    		; line feed
CAN		EQU     $18		; Cancel
ESC       	EQU     $1B    		; ESC
SPC		EQU     $20		; space char

SOH       	EQU     $01    		; start of header
EOT       	EQU     $04    		; end of text
ACK       	EQU     $06    		; acknowledged
NAK       	EQU     $15    		; not acknowledged

; Tape Reader/Writer Constants *************************************************

SYNCMARK	EQU	$2E		; synchronisation mark
NAMEMARK	EQU	$A0		; start of name mark
ADDRMARK	EQU	$A1		; start of address mark
FILEMARK	EQU	$1F		; start of file mark

RPTIME		EQU	49		; read point time   49x8uS     = 392uS
LPTIME		EQU	190		; long pulse time   190uS+50uS = 240uS
SPTIME		EQU	60		; short pulse time  60uS+50uS  = 120uS

; Device Driver Constants ******************************************************

KBD_MAGIC_NUM   EQU	129             ; magic number of keyboard ROM

COM_DEV	        EQU	$10             ; COM devices base ID
STORAGE_DEV	EQU	$20             ; STORAGE devices base ID

NULL_ID		EQU	$00             ; the NULL device

TTY1_ID		EQU	COM_DEV+0       ; TTY 1 device ID
PRINTER1_ID	EQU	COM_DEV+1       ; Printer 1 device ID
PRINTER2_ID	EQU	COM_DEV+2       ; Printer 2 device ID
KEYBD1_ID	EQU	COM_DEV+3       ; Keyboard 1 device ID (ASCII Keyboard)
KEYBD2_ID	EQU	COM_DEV+4       ; Keyboard 2 device ID (PS/2 Keyboard)
VDP1_ID         EQU     COM_DEV+5       ; Video Display Processor device ID

XMODEM1_ID	EQU	STORAGE_DEV+0   ; XModem device ID
TAPE1_ID	EQU	STORAGE_DEV+1   ; Tape 1 device ID
FDD1_ID         EQU     STORAGE_DEV+2   ; Floppy drive 1 device ID
FDD2_ID         EQU     STORAGE_DEV+3   ; Floppy drive 2 device ID
SDC1_ID		EQU	STORAGE_DEV+4   ; SD-Card device ID
HDD1_ID		EQU	STORAGE_DEV+5   ; Harddisk 1 device ID
HDD2_ID		EQU	STORAGE_DEV+6   ; Harddisk 2 device ID

; Device Command Constants *****************************************************

CMD_INIT	EQU	0               ; Init device
CMD_IDENTIFY	EQU	1               ; Identify device
CMD_NORMAL	EQU	2               ; Set normal text
CMD_INVERSE	EQU	3               ; Set inverse text
CMD_FLASH	EQU	4               ; Set blinking text
CMD_HOME	EQU	5               ; Set cursor to home position
CMD_CLRLINE	EQU	6               ; Clear line at cursor
CMD_CLRSCRN	EQU	7               ; Clear screen
CMD_MOVE_TO     EQU     8               ; Set pen position X,Y
CMD_SETCURSOR	EQU	8               ; Set cursor position X,Y
CMD_CRSR_ONOFF  EQU     9               ; Turn cursor on or off
CMD_COLOR       EQU     10              ; Set pixel color
CMD_TEXT_COLOR  EQU     11              ; Set text color
CMD_BACK_COLOR  EQU     12              ; Set background color
CMD_STD_PALETTE EQU     13              ; Reset to standard color palette
CMD_MODE        EQU     15              ; Set text/graphics modes

CMD_SETSTARTADR	EQU	16              ; Set start address [X:Y]
CMD_SETENDADR	EQU	17              ; Set end address [X:Y]

CMD_LOAD	EQU	32              ; Load data byte from device
CMD_SAVE	EQU	33              ; Save data byte to device
CMD_READ	EQU	34              ; Read data block from device
CMD_WRITE	EQU	35              ; Write data block to device
CMD_BOOT        EQU     36              ; Boot from device
CMD_READ_BUF	EQU	37              ; Read data block from device to standard buffer
CMD_WRITE_BUF	EQU	38              ; Write data block to device from standard buffer

CMD_PUT_PIXEL   EQU     $50             ; Draw pixel
CMD_AND_PIXEL   EQU     $51
CMD_OR_PIXEL    EQU     $52
CMD_XOR_PIXEL   EQU     $53
CMD_NOT_PIXEL   EQU     $54
CMD_T_PUT_PIXEL EQU     $58
CMD_T_AND_PIXEL EQU     $59
CMD_T_OR_PIXEL  EQU     $5A
CMD_T_XOR_PIXEL EQU     $5B
CMD_T_NOT_PIXEL EQU     $5C

CMD_DRAW_RECT   EQU     $60             ; framed rectangle
CMD_AND_RECT    EQU     $61
CMD_OR_RECT     EQU     $62
CMD_XOR_RECT    EQU     $63
CMD_NOT_RECT    EQU     $64
CMD_T_DRAW_RECT EQU     $68
CMD_T_AND_RECT  EQU     $69
CMD_T_OR_RECT   EQU     $6A
CMD_T_XOR_RECT  EQU     $6B
CMD_T_NOT_RECT  EQU     $6C

CMD_DRAW_LINE   EQU     $70             ; Draw line
CMD_AND_LINE    EQU     $71
CMD_OR_LINE     EQU     $72
CMD_XOR_LINE    EQU     $73
CMD_NOT_LINE    EQU     $74
CMD_T_DRAW_LINE EQU     $78
CMD_T_AND_LINE  EQU     $79
CMD_T_OR_LINE   EQU     $7A
CMD_T_XOR_LINE  EQU     $7B
CMD_T_NOT_LINE  EQU     $7C

CMD_DRAW_BAR    EQU     $80             ; filled rectangle
CMD_AND_BAR     EQU     $81
CMD_OR_BAR      EQU     $82
CMD_XOR_BAR     EQU     $83
CMD_NOT_BAR     EQU     $84
CMD_T_DRAW_BAR  EQU     $88
CMD_T_AND_BAR   EQU     $89
CMD_T_OR_BAR    EQU     $8A
CMD_T_XOR_BAR   EQU     $8B
CMD_T_NOT_BAR   EQU     $8C

; SD Command Constants *********************************************************

CMD0		EQU	$40		; Reset SD-Card
CMD1		EQU	CMD0 + 1	; Initialize MMC/SDC
CMD8		EQU	CMD0 + 8	; Check voltage range
CMD13		EQU	CMD0 + 13	;
CMD16		EQU	CMD0 + 16	; Change block size
CMD17		EQU	CMD0 + 17	; Read single block
CMD24		EQU	CMD0 + 24	; Write single block
CMD55		EQU	CMD0 + 55	; Application command prefix
CMD58		EQU	CMD0 + 58	; Get OCR
ACMD41		EQU	CMD0 + 41	; Initialize SDC

DATA_TOKEN	EQU	$FE             ; SD-Card Data Token

; Block Device Constants *******************************************************

MOUNT_TABLE     EQU     $0400           ; Table of mounted devices
BOOT_PART       EQU     MOUNT_TABLE     ; Boot Medium Descriptor
BLOCK_BUF	EQU	$0600           ; Block Device Block Buffer
MBR             EQU     BLOCK_BUF       ; Master Boot Block Code
PART0		EQU	$07BE		; Partition 0 start
PART0_RS	EQU	PART0 + 8 	; Partition 0 relative sector field
PART0_SIZE	EQU	PART0 + 16	; Partition 0 sector size field

BOOTBLK_TAG     EQU     $07FE           ; Address of Boot Block Tag ($55 $AA)

; Miscellanious Constants ******************************************************

I2C_RTC_ADR	EQU	$68		; I2C address of DS1307 Real Time Clock


FGC_BASE        EQU     $1000
FDC_OPT_REG     EQU     FGC_BASE+3
FDC_MOTOR1_REG  EQU     FGC_BASE+4
FDC_MOTOR2_REG  EQU     FGC_BASE+5
FGC_INFO        EQU     FGC_BASE+$10
FGC_SET_PAGE    EQU     FGC_BASE+$13
FGC_FDC_CMD     EQU     FGC_BASE+$17
FGC_VPU_CMD     EQU     FGC_BASE+$1F
FGC_VPU_OUT     EQU     FGC_BASE+$27

VPU_PORT1       EQU     FGC_BASE+$09    ; VPU Port 1
VPU_REG0        EQU     $80             ; VPU register 0
VPU_REG15       EQU     VPU_REG0+15     ; VPU status register pointer
VPU_STAT0       EQU     0               ; VPU status register 0


; TEMP *************************************************************************

PPORTLOAD	EQU	$2000		; jump location for test code
PPORTSAVE	EQU	$2003		; jump location for test code


; ******************************************************************/***********
; //////////////////////////////////////////////////////////////////////////////
; ******************************************************************************

		ORG 	$E000       	; start address of Monitor

; ******************************************************************************
; //////////////////////////////////////////////////////////////////////////////
; ******************************************************************************

MON_COLD_START	JMP  	MAINSTART	; jump to monitor cold start
MON_WARM_START	JMP	MONINP		; jump to monitor warm start

; **** Switch To RAM Page (B000..DFFF) *****************************************

; ******************************************************************************

SWITCH_TO_RAM	LDY	#$20		; load index to RAM annunciator
		BNE	SWITCH		; branch always

; **** Switch To ROM Page (B000..DFFF) *****************************************

; ******************************************************************************

SWITCH_TO_ROM	LDY	#$30		; load index to ROM annunciator
SWITCH		LDA	(IOBASE),Y	; trigger annunciator address
		RTS

; **** Set Standard In/Out Routine ID ******************************************

; Input: A - ID Of Standard IO Device

; ******************************************************************************

SET_STDIOID	JSR	DEV_OPEN

; **** Set Standard In/Out Routine *********************************************

; Input: X - Low Byte Of Standard Device Descriptor
;	 Y - High Byte Of Standard Device Descriptor

; ******************************************************************************

SET_STDIO	JSR	SET_STDIN
		JMP	SET_STDOUT0

; **** Set Standard Out Routine ID *********************************************

; Input: A - ID Of Standard Output Device

; ******************************************************************************

SET_STDOUTID	JSR	DEV_OPEN

; **** Set Standard Out Routine ************************************************

; Input: X - Low Byte Of Standard Out Device Descriptor
;	 Y - High Byte Of Standard Out Device Descriptor

; ******************************************************************************

SET_STDOUT	STX	PDEVL
		STY	PDEVH
SET_STDOUT0	LDY	#$04
		LDX	#$00
SET_STDOUT1	LDA	(PDEV),Y
		STA	STDOUT,X
		INY
		INX
		CPX	#$04
		BNE	SET_STDOUT1
		RTS

; **** Set Standard In Routine ID **********************************************

; Input: A - ID Of Standard Input Device

; ******************************************************************************

SET_STDINID	JSR	DEV_OPEN


; **** Set Standard In Routine *************************************************

; Input: X - Low Byte Of Standard In Device Descriptor
;	 Y - High Byte Of Standard In Device Descriptor

; ******************************************************************************

SET_STDIN	STX	PDEVL
		STY	PDEVH
		LDY	#$02
		LDA	(PDEV),Y
		STA	STDIN
		INY
		LDA	(PDEV),Y
		STA	STDIN+1
         	RTS

; **** Write Binary Routine ****************************************************

; Input: A - Output Byte to Standard Out

; ******************************************************************************

BOUT		JMP	(STDOUT)

; **** Read Character Routine **************************************************

; Output: A - character read from standard in

; ******************************************************************************

CIN		JSR	CGET		; call standard in. Character available?
		BCC	CIN		; no, repeat
		RTS

; **** Get Character (no wait) Routine *****************************************

; Output: A - character read from standard in
;         C - 1 char get, 0 no char get

; ******************************************************************************

CGET            JMP     CHAR_GET

; **** Write LF Character Routine **********************************************

; ******************************************************************************

LFOUT		LDA  	#LF        	; write a LF
					; fall through to COUT

; **** Write Character Routine *************************************************

; Input: A - character to write

; ******************************************************************************

COUT 		JSR     BOUT
                CMP  	#CR        	; character was a CR?
		BEQ  	LFOUT      	; yes, also write LF
		RTS

; **** Write CR/LF To Terminal *************************************************

; ******************************************************************************

CROUT		LDA	#CR		; write a CR
		BNE	COUT

; **** Write Single Space Char To Terminal *************************************

; ******************************************************************************

SPCOUT		LDA	#$20		; write a Space char
		BNE	BOUT

; **** Read String Routine *****************************************************

; Output:  (PSTRL, PSTRH) - pointer to CR terminated string data

; ******************************************************************************

STRIN           LDX  	#$02		; initialize character index
BACKSPACE       DEX
		BEQ  	STRIN		; if line empty, restart
NEXTCHR         JSR  	CIN        	; get next character from input buffer
		STA  	STRBUF,X   	; store character in string buffer
		CMP  	#CR		; is it a CR?
                BEQ  	ENDSTRIN	; yes, exit
                JSR  	COUT		; echo character
		CMP  	#BS        	; backspace key?
		BEQ  	BACKSPACE  	; yes
                INX             	; advance string index
                BNE  	NEXTCHR    	; more then 255 characters? No, read next char
                LDA  	#CR        	; yes, auto new line and stop reading
		STA  	STRBUF,X   	; store CR in string buffer
ENDSTRIN        JMP  	COUT       	; send CR

; **** Write String Routine ****************************************************

; Input:  (PSTRL, PSTRH) - pointer to null terminated string data

; ******************************************************************************

STROUT		LDY  	#$00       	; index y is 0

; **** Write String From Index Routine *****************************************

; Input:  (PSTRL, PSTRH) - pointer to null terminated string data
;	  Y              - start index into string data

; ******************************************************************************

WRSTR		LDA  	(PSTR),Y   	; load char at string pos y
		BEQ  	ENDSTROUT  	; exit, if NULL char
		JSR  	COUT       	; write character
		INY             	; next index
		JMP  	WRSTR
ENDSTROUT	RTS

; **** Print A Byte In Hexadecimal *********************************************

; Input: A - data byte to print in hex

; ******************************************************************************

HEXOUT          PHA             	; save A for lower hex digit
                LSR  	A
                LSR  	A
                LSR  	A
                LSR  	A
                JSR  	HEXDIG		; write upper hex digit
                PLA             	; write lower hex digit
					; fall through to HEXDIG

; **** Print A Single Hexadecimal Digit ****************************************

; Input: A - data nibble in Bit 0-3 to print in hex

; ******************************************************************************

HEXDIG          AND     #$0F    	; mask lower digit
                ORA     #'0'    	; add 48
                CMP     #'9'+1  	; decimal digit?
                BCC     PRHEX   	; yes, print it
                ADC     #6      	; add offset for letter digit
PRHEX		JMP     BOUT

; **** Print A Byte As Decimal Number ******************************************

; Input: A - number 00..FF (0..255)

; ******************************************************************************

NUMOUT		JSR	DEC2STR
		LDX	#2
NEXTNUMOUT	LDA	DIG0,X
		JSR	BOUT
		DEX
		BPL	NEXTNUMOUT
		RTS

; **** Clear Screen Routine ****************************************************

; ******************************************************************************

CLRSCRN		LDA	#CMD_CLRSCRN

; **** Call Standard Print Command Routine *************************************

; Input : A - command byte
;         X - command data byte low
;         Y - command data byte high

; ******************************************************************************

CMDPRINT	JMP	(STDCMD)

; **** Call Opened Device Command Routine **************************************

; Input : A - command byte
;         X - command data byte low
;         Y - command data byte high

; ******************************************************************************

CMDDEV		JMP	(DEVCMD)

; **** Convert a Byte To Decimal String ****************************************

; Input:  A - number 00..FF (0..255)
; Output; DIG0 (10^0), DIG1 (10^1), DIG2 (10^2)

; ******************************************************************************

DEC2STR		LDX	#48
		STX	DIG0		; initialize digit counter 0 to '0'
		STX	DIG1		; initialize digit counter 1 to '0'
		STX	DIG2		; initialize digit counter 2 to '0'
GETDIG2	CMP	#100			; is A >= 100?
		BCC	GETDIG1		; no, convert next digit
		SBC	#100		; yes, subract 100 from A
		INC	DIG2		; and increment digit counter 2
		BNE	GETDIG2		; branch always
GETDIG1	CMP	#10			; is A >= 10?
		BCC	GETDIG0		; no, convert next digit
		SBC	#10		; yes, subract 10 from A
		INC	DIG1		; and increment digit counter 1
		BNE	GETDIG1		; branch always
GETDIG0	ADC	DIG0			; add digit counter 0 to remainder in A
		STA	DIG0		; and store it back to digit counter 0
		RTS

; **** Print Tab Routine *******************************************************

; Input: A - number of space characters to print

; ******************************************************************************

TAB		STA  	TEMP
		LDA  	#SPC		; load SPC char
PRINTTAB	JSR  	COUT		; write SPC
		DEC   	TEMP
                BNE   	PRINTTAB   	; all spaces written? No, repeat
		RTS

; **** Read Hex Number From Input String ***************************************

; Input:  Y - current input string position to read from
; Output: (NUML, NUMH) - last 8 digits of read hex number

; ******************************************************************************

HEXINPUT	LDX   	#$00
		STX   	NUML       	; clear input value
		STX   	NUMH
NEXTDIGIT       LDA   	STRBUF,Y   	; get next input char
		CMP   	#'0'
		BCC   	NOTHEX     	; char < '0'? Yes, no hex digit
		CMP   	#':'
		BCC   	NUMDIGIT   	; char is in '0'..'9'
		AND   	#$DF	 	; uppercase chars only
HEXDIGIT	CMP   	#'A'
		BCC   	NOTHEX     	; char < 'A'? Yes, no hex digit
		CMP   	#'G'
		BCS   	NOTHEX     	; char > 'F'? Yes, no hex digit
		SBC   	#'A'-11	 	; char 'A'..'F' to value 10..16
NUMDIGIT        ASL   	A
		ASL   	A
		ASL   	A
		ASL   	A		; digit shifted to upper nibble
		LDX   	#$04      	; load shift loop counter
SHIFT		ASL   	A		; shift msb in C
		ROL   	NUML
		ROL   	NUMH
		DEX
		BNE   	SHIFT	 	; 4 times shifted? No, repeat
		INY		 	; increment string index
		BNE   	NEXTDIGIT	; branch always
NOTHEX		RTS

; **** Read String From Input Buffer *******************************************

; Input:  Y - current input string position to read from
; Output: C = 1, string found C = 0, string not found
;         PSTRL = low byte of string pointer
;	  PSTRH = high byte of string pointer

; ******************************************************************************

STRINPUT	CLC
NEXTSTRCHAR	LDA  	STRBUF,Y   	; get next input char
		INY
		CMP  	#' '
		BEQ  	NEXTSTRCHAR 	; ignore spaces
		CMP  	#CR
		BEQ  	ENDSTRING 	; end of input line, no filename found
		CMP	#'"'
		BNE	ENDSTRING
		LDX	#$00
		SEC
READSTRING	LDA  	STRBUF,Y   	; get next input char
		CMP	#CR
		BEQ	ENDSTRING
		CMP	#'"'
		BEQ	ENDSTRING
		STA	RBUFF,X		; char to buffer
		INY
		INX
		BNE	READSTRING	; read next char of filename
ENDSTRING	LDA	#$00
		STA	RBUFF,X		; terminate filename string with NULL

; **** Set String Pointer To Read Buffer ***************************************

; Output: X - low byte of string pointer
;	  Y - high byte of string pointer

; ******************************************************************************

SETSTRBUFF	LDX	#LOW RBUFF	; set string pointer to filename buffer
		LDY	#HIGH RBUFF
SETSTRBUFF0	STX	PSTRL
		STY	PSTRH
		RTS

; **** Delay Routine ***********************************************************

; Input: A - milliseconds to wait

; ******************************************************************************

DELAY           STA  	CNTD
		BNE	LOOPDELAY

; **** Short Delay Routine *****************************************************

; Input: A - microseconds to wait

; ******************************************************************************

SHORTDELAY	TAY
SHORTDELAY1	STY  	CNTA		; set counter
LOOPDELAY	BIT  	CNTIRQ		; check if counter reached 0
		BPL  	LOOPDELAY	; no, check again
		RTS

; **** Check ESC Routine *******************************************************

; Output: C = 1 ESC pressed, 0 ESC not pressed
; Beep if ESC pressed

; ******************************************************************************

CHKESC		JSR     CGET            ; key pressed?
		BCC	NOTESC		; no
		CMP     #ESC		; ESC pressed?
		BEQ	BEEP		; yes, exit and beep.
		CLC			; no, clear carry flag
NOTESC		RTS

; **** System Beep Routine *****************************************************

; ******************************************************************************

BEEP		JMP	(STDBEEP)	; call standard BEEP routine

; **** Simple Beep Routine *****************************************************

; ******************************************************************************

DOBEEP		LDA	PBDD		; save port b data direction register
		PHA
		LDX     #$60		; repeat 60 times
		LDA     #$21
		TAY
		STA     PBDD		; turn speaker on
BEEPLOOP	STY     PBD		; set PB0 high
		LDA     #$01
		JSR     DELAY		; delay of ~1ms
		DEY
		STY	PBD		; set PB0 low
		LDA	#$01
		JSR	DELAY		; delay of ~1ms
		LDY	#$21
		DEX
		BNE	BEEPLOOP	; not finished, repeat
		PLA
		STA	PBDD		; restore port b data direction register
		SEC
		RTS

; ******************************************************************************
; REAL TIME CLOCK ROUTINES ALIASES
; ******************************************************************************

; **** Print Date And Time *****************************************************

; ******************************************************************************

PRINT_DATETIME	JMP	PRINTDATETIME

; **** Print Time *************************************************************

; ******************************************************************************

PRINT_TIME	JMP	PRINTTIME

; **** Print Date **************************************************************

; ******************************************************************************

PRINT_DATE	JMP	PRINTDATE

; **** Print Date Including Day Of Week ****************************************

; ******************************************************************************

PRINT_FULLDATE	JMP	PRINTFULLDATE

; **** Set Date And Time *******************************************************

; ******************************************************************************

SET_DATETIME	JMP	SETDATETIME

; **** Set Time ****************************************************************

; ******************************************************************************

SET_TIME	JMP	SETTIME

; **** Set Date ****************************************************************

; ******************************************************************************

SET_DATE	JMP	SETDATE

; **** Add Device Driver *******************************************************

; Input:   X - device descriptor pointer low
;          Y - device descriptor pointer high
; Output - C = 1 Success, C = 0 Error
;          A = Device ID (0F = Too Many Devices, FF = Unknown Device Type)

; ******************************************************************************

ADD_DEVICE	JMP	DEV_ADD

; **** Open Device For Read/Write **********************************************

; Input:  A - device id
; Output: C = 1 Success, C = 0 Error
;         X - device descriptor pointer low
;         Y - device descriptor pointer high

; ******************************************************************************

OPEN_DEVICE	JMP	DEV_OPEN

; **** Reset Standard I/O To First Screen Device *******************************

; ******************************************************************************

RESET_STDIO	LDA	STDINDEV	; open base In device
		JSR	SET_STDINID	; and set it as standard input
		LDA	STDOUTDEV	; open base Out device
		JMP	SET_STDOUTID	; and set it as standard output

; **** Read Joystick Port ******************************************************

; Output: A - button state (Bit 0 = Button 1, Bit 1 = Button 2, Bit 2 = Button 3)
;         X - horizontal joystick position 0 = Center, -1 ($FF) = Left, 1 = Right
;         Y - vertical joystick position 0 = Center, -1 ($FF) = Up, 1 = Down
;         C = 0 - No joystick port available; C = 1 - Joystickport available

; ******************************************************************************

READ_JOYSTICK   JMP     READ_JOY_PORT

; **** Decode Joystick Data ****************************************************

; Output: A - button state (Bit 0 = Button 1, Bit 1 = Button 2, Bit 2 = Button 3)
;         X - horizontal joystick position 0 = Center, -1 ($FF) = Left, 1 = Right
;         Y - vertical joystick position 0 = Center, -1 ($FF) = Up, 1 = Down

; ******************************************************************************

DECODE_JOYSTICK JMP     DECODE_JOY_PORT

; **** Mute All Sound Chip Channels ********************************************

; ******************************************************************************

SOUND_MUTE_ALL  JMP     SOUND_MUTEALL

; **** Mute A Sound Chip Channel ***********************************************

; Input: A - Channel # (0..3)

; ******************************************************************************

SOUND_MUTE_CHAN JMP     SOUND_MUTE

; **** Set Attenuation For A Sound Chip Channel ********************************

; Input: A - Channel # (0..3)
; 	 X - Attenuation Level 0..15 (0dB, 2dB, 4dB ... OFF)

; ******************************************************************************

SOUND_SET_ATN   JMP     SOUND_SETATN

; **** Set Periodic Noise ******************************************************

; Input: X - Noise Shift Rate

; ******************************************************************************

SOUND_P_NOISE   JMP     SOUND_PNOISE

; **** Set White Noise *********************************************************

; Input: X - Noise Shift Rate

; ******************************************************************************

SOUND_W_NOISE   JMP     SOUND_WNOISE

; **** Set Noise ***************************************************************

; Input: A - 0 = Periodic Noise  1 = White Noise
;	 X - Noise Shift Rate

; ******************************************************************************

SOUND_SET_NOISE JMP     SOUND_SETNOISE

; **** Set Sound Frequency in HZ ***********************************************

; Input: A - Channel (0..2)
;	 X - Frequency Low Bits 7..0
;	 Y - Frequency High Bits 9..8

; ******************************************************************************

SOUND_SET_FREQ  JMP     SOUND_SETFREQ

; ******************************************************************************
; INTERNAL
; ******************************************************************************

; **** Extended Read-Character Handler *****************************************

CHAR_GET        JSR     READ_STD_IN
                BCC     NO_CHAR_GET
                JMP     (KEY_HANDLER)
NO_CHAR_GET     JMP     (NKEY_HANDLER)
READ_STD_IN     JMP	(STDIN)

; ******************************************************************************
; TTY DEVICE DRIVER
; ******************************************************************************

; **** Terminal Command Routine ************************************************

; Input : A - command byte
;         X - command data byte low
;         Y - command data byte high

; ******************************************************************************

TTY_CMD		CMP	#9
		BCS	END_TTY_CMD
		STY	YSAV
		ASL	A
		TAY
		LDA	TTY_CMD_TABLE,Y
		STA	PSTRL
		LDA	TTY_CMD_TABLE+1,Y
		STA	PSTRH
		LDY	YSAV
		JMP     (PSTR)
END_TTY_CMD	RTS

TTY_CMD_TABLE	DW	TTY_INIT,TTY_IDENTIFY,TTY_NORMAL,TTY_INVERSE,TTY_FLASH
		DW	TTY_HOME,TTY_CLRLINE,TTY_CLRSCRN,TTY_SETCURSOR

; **** Initialize TTY Device ***************************************************

; ******************************************************************************

TTY_INIT	LDA  	#$00
		STA  	BAUDRATE   	; initialize baud rate variable
		LDA  	#$0B       	; set ACIA to
         	STA  	COMM_REG	; no parity, no receiver echo, RTS low, no IRQ, DTR low
		LDX  	#$19		; start with 1 stop bit, 8 data bits, 2400 bps as the current baud rate
NEXTBAUD	STX  	CTRL_REG	; set the baud rate
		JSR  	TTY_IDENTIFY	; send identify string to terminal
		LDA  	#40
		JSR  	DELAY		; wait for ~64ms
		LDA  	STAT_REG
		AND  	#$08		; ACIA input register full?
		BEQ  	NOESC	 	; no, go on
		LDA  	DATA_REG    	; read data register from ACIA
		CMP  	#ESC	 	; is it a ESC char
		BNE  	NOESC	 	; no, go on
		STX  	BAUDRATE    	; and store it
		LDX  	#$1F	 	; detection finished
NOESC           INX  			; try next baud rate
		CPX  	#$20
		BCC  	NEXTBAUD   	; tried all baud rates?
		RTS

; **** Identify TTY Device *****************************************************

; ******************************************************************************

TTY_IDENTIFY    LDY  	#ESCGID-STRINGP	; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Set Normal Text *********************************************************

; ******************************************************************************

TTY_NORMAL      LDY  	#ESCNORM-STRINGP; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Set Inverse Text ********************************************************

; ******************************************************************************

TTY_INVERSE     LDY  	#ESCINV-STRINGP ; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Set Blinking Text *******************************************************

; ******************************************************************************

TTY_FLASH       LDY  	#ESCBLNK-STRINGP; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Set Cursor To Home Position *********************************************

; ******************************************************************************

TTY_HOME        LDY  	#ESCHOME-STRINGP; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Clear Line **************************************************************

; ******************************************************************************

TTY_CLRLINE     LDA	#$0D
		JSR	BOUT
		LDY  	#ESCCLL-STRINGP	; load sequence index
		BNE  	PRINTESC   	; jump always

; **** Clear Screen And Set Cursor To Home Position ****************************

; ******************************************************************************

TTY_CLRSCRN     LDY  	#ESCCLS-STRINGP	; load sequence index
					; fall through to PRINTESC

; **** VT100 ESC Sequence Loader ***********************************************

; ******************************************************************************

PRINTESC        JSR	TTY_ESCCODE
		JSR	LOADSTRING
		JMP  	WRSTR

; **** VT100 ESC Start Code ****************************************************

; ******************************************************************************

TTY_ESCCODE	LDA	#$1B
		JSR	BOUT
		LDA	#'['
		JMP	BOUT

; **** Set Cursor Location *****************************************************

; Input: X - x position of cursor.  Y - y position of cursor

; ******************************************************************************

TTY_SETCURSOR	TXA
		PHA
		JSR	TTY_ESCCODE
		TYA
		JSR	NUMOUT
		LDA	#';'
		JSR	BOUT
		PLA
		JSR	NUMOUT
		LDA	#'H'
		JMP	BOUT

; ******************************************************************************
; LOW LEVEL REAL TIME CLOCK CODE
; ******************************************************************************

; **** Set Day Of Week *********************************************************

; Input: A - Day Of Week 1 (MON) - 7 (SUN)

; ******************************************************************************

WRITEDOW	STA	ACC
		LDA	#$03
		JSR	SETRTCADR
		LDA	ACC
		JSR	I2C_SEND	; set day of week
		JMP	I2C_STOP

; **** Get Day Of Week *********************************************************

; Output: A - Day Of Week 1 (MON) - 7 (SUN)

; ******************************************************************************

READDOW		LDA	#$03
		JSR	READCLOCK
		TYA
		RTS

; **** Write Time **************************************************************

; Input: A - HOUR 	in BCD ($00-$23)
;	 X - MINUTE 	in BCD ($00-$59)
;	 Y - SECOND	in BCD ($00-$59)

; ******************************************************************************

WRITETIME	STA	ACC
		STX	XREG
		STY	YREG
WRITETIME2	LDA	#$00		; start at register 0
		JSR	WRITECLOCK	; write time bytes to clock registers
		LDA	#$08		; set address pointer to ram
		JSR	SETRTCADR
		LDA	#$65		; time set mark
		JSR	I2C_SEND
		JMP	I2C_STOP

; **** Write Date **************************************************************

; Input: A - YEAR 	in BCD ($00-$99)
;	 X - MONTH 	in BCD ($01-$12)
;	 Y - DAY	in BCD ($01-$31)

; ******************************************************************************

WRITEDATE	STA	ACC
		STX	XREG
		STY	YREG
WRITEDATE2	LDA	#$04		; start at register 4
		JSR	WRITECLOCK	; write date bytes to clock register
		LDA	#$09		; set address pointer to ram
		JSR	SETRTCADR
		LDA	#$02		; date set mark
		JSR	I2C_SEND
		JMP	I2C_STOP

; **** Write Data To Clock *****************************************************

; ******************************************************************************

WRITECLOCK	JSR	SETRTCADR
		LDA	YREG
		JSR	I2C_SEND	; set second or day
		LDA	XREG
		JSR	I2C_SEND	; set minute or month
		LDA	ACC
		JSR	I2C_SEND	; set hour or year
		JMP	I2C_STOP

; **** Read Time ***************************************************************

; Output: A - HOUR 	in BCD ($00-$23)
;	  X - MINUTE 	in BCD ($00-$59)
;	  Y - SECOND	in BCD ($00-$59)

; ******************************************************************************

READTIME	LDA	#$00
		BEQ	READCLOCK

; **** Read Date ***************************************************************

; Output: A - YEAR 	in BCD ($00-$99)
; 	  X - MONTH 	in BCD ($01-$12)
; 	  Y - DAY	in BCD ($01-$31)


; ******************************************************************************

READDATE	LDA	#$04
		BNE	READCLOCK

; **** Read Data From Clock ****************************************************

; ******************************************************************************

READCLOCK	JSR	SETRTCADR	; set read pointer
		JSR	I2C_START	; send start condition
		LDA	#I2C_RTC_ADR	; the I2C address
		JSR	I2C_READ_DEV	; send device id and set read mode
		JSR	I2C_RCV		; receive first data byte
		STA	YREG		; and store it
		JSR	I2C_ACK		; send acknowlege
		JSR	I2C_RCV		; receive second data byte
		STA	XREG		; and store it
		JSR	I2C_ACK		; send acknowlege
		JSR	I2C_RCV		; receive third data byte
		STA	ACC		; and store it
		JSR	I2C_NACK	; no more data
		JSR	I2C_STOP	; stop communication
		LDA	ACC		; load third data byte into A
		LDX	XREG		; load second data byte into X
		LDY	YREG		; load first data byte into Y
		RTS

; **** Set RTC Address Read/Write Pointer **************************************

; Input: A - Register Address

; ******************************************************************************

SETRTCADR	PHA			; save register address onto stack
		JSR	I2C_START	; send start condition
		LDA	#I2C_RTC_ADR	; the I2C device address
		JSR	I2C_WRITE_DEV	; send device address and write bit
		PLA			; restore register address
		JMP	I2C_SEND	; send register address

; ******************************************************************************
; START OF DATA INPUT/OUTPUT CODE
; ******************************************************************************

; ******************************************************************************
; START OF VIA1 INPUT/OUTPUT CODE
; ******************************************************************************

; **** Write To VIA1 Register **************************************************

; Input:  Y - Destination Register index (VIA_PORTA,VIA_DDRA...)
;	  A - Data to be written into the Register

; ******************************************************************************

WRITE_VIA	STA	(IOBASE),Y
		RTS

; **** Read From VIA1 Register *************************************************

; Input:  Y - Source Register index (VIA_PORTA,VIA_DDRA...)
; Output: A - Read Data from the Register

; ******************************************************************************

READ_VIA	LDA	(IOBASE),Y
		RTS


; ******************************************************************************
; START OF I2C CODE
; ******************************************************************************

; **** Send I2C Start Condition ************************************************

; ******************************************************************************

I2C_START	LDY	#DDRB
		LDA	#%01011110	; SDA = 1; SCL = 1
		STA	(IOBASE),Y
		LDA	#%11011110	; SDA = 0; SCL = 1
		STA	(IOBASE),Y
		LDA	#%11011111	; SDA = 0; SCL = 0
		STA	(IOBASE),Y
		RTS

; **** Send I2C Stop Condition *************************************************

; ******************************************************************************

I2C_STOP	LDY	#DDRB
		LDA	#%11011111	; SDA = 0; SCL = 0
		STA	(IOBASE),Y
		LDA	#%11011110	; SDA = 0; SCL = 1
		STA	(IOBASE),Y
		LDA	#%01011110	; SDA = 1; SCL = 1
		STA	(IOBASE),Y
		RTS

; **** Send I2C Acknowledged ***************************************************

; ******************************************************************************

I2C_ACK		LDY	#DDRB
		LDA	#%11011111	; SDA = 0; SCL = 0
		STA	(IOBASE),Y
		LDA	#%11011110	; SDA = 0; SCL = 1
		STA	(IOBASE),Y
		LDA	#%11011111	; SDA = 0; SCL = 0
		STA	(IOBASE),Y
		RTS

; **** Send I2C Not Acknowledged ***********************************************

; ******************************************************************************

I2C_NACK	LDY	#DDRB
		LDA	#%01011111	; SDA = 1; SCL = 0
		STA	(IOBASE),Y
		LDA	#%01011110	; SDA = 1; SCL = 1
		STA	(IOBASE),Y
		LDA	#%01011111	; SDA = 1; SCL = 0
		STA	(IOBASE),Y
		RTS

; **** Read I2C Device *********************************************************

; Input:  A - Device Address
; Output: C - 0 = not acknowledged, 1 = acknowledged

; ******************************************************************************

I2C_READ_DEV	SEC			; set carry flag
		ROL	A		; shift device address one bit left and rotate C in LSB. LSB = 1 = read
		BNE	I2C_SEND	; and send it

; **** Write I2C Device ********************************************************

; Input:  A - Device Address
; Output: C - 0 = not acknowledged, 1 = acknowledged

; ******************************************************************************

I2C_WRITE_DEV	ASL	A		; shift device address one bit left. LSB is now 0 = write
					; directly fallthrough to I2C_SEND

; **** Send a Byte to I2C Device ***********************************************

; Input:  A - Data Byte
; Output: C - 0 = not acknowledged, 1 = acknowledged

; ******************************************************************************

I2C_SEND	STA	I2C_DATA
		LDX	#$08		; send 8 bits
		LDY	#DDRB
SENDLOOP	ASL	I2C_DATA	; get next bit into C flag
		BCS	SENDH		; is it a 1 bit?
		LDA	#%11011111	; no, SDA = 0; SCL = 0
		BNE	SETBIT		; branch always
SENDH		LDA	#%01011111	; yes, SDA = 1; SCL = 0
SETBIT		STA	(IOBASE),Y
		AND	#%11111110	; SDA = X; SCL = 1
		STA	(IOBASE),Y
		ORA	#%00000001	; SDA = X, SCL = 0
		STA	(IOBASE),Y
		DEX
		BNE	SENDLOOP

I2C_ACK?	LDY	#DDRB

		LDA	#%01011111	; SDA = 1; SCL = 0
		STA	(IOBASE),Y

		LDA	#%01011110	; SDA = 1; SCL = 1
		STA	(IOBASE),Y
		LDY	#PORTB
		LDA	(IOBASE),Y	; get SDA
		BPL	ISACK		; SDA = 1 ?
		CLC			; no, not acknowledeged
		BCC	CLKDOWN
ISACK		SEC			; yes, acknowledeged
CLKDOWN		LDY	#DDRB
		LDA	#%01011111	; SCL = 0
		STA	(IOBASE),Y
		RTS

; **** Receive a Byte from I2C Device ******************************************

; Output: A - Data Byte

; ******************************************************************************

I2C_RCV		LDX	#$09
RCVLOOP		LDY	#DDRB
		LDA	#%01011111	; SDA = 1; SCL = 0
		STA	(IOBASE),Y
		DEX
		BEQ	RCVEND		; all eight bits received?
		LDA	#%01011110	; SDA = 1; SCL = 1
		STA	(IOBASE),Y
		LDY	#PORTB
		LDA	(IOBASE),Y	; get SDA
		ASL	A		; and shift it into C
		ROL	I2C_DATA	; shift byte buffer one bit left. C goes into LSB
		JMP	RCVLOOP
RCVEND		LDA	I2C_DATA	; load data into A
		RTS

; ******************************************************************************
; START OF SOUND GENERATOR CODE
; ******************************************************************************

; **** Send A Command Byte To The Sound Chip ***********************************

; Input: A - Data Byte

; ******************************************************************************

SOUND_SENDBYTE	STY	YSAV		; save current Y register
		LDY	#PORTA
		STA	(IOBASE),Y	; set data
		LDY	#PORTB
		LDA	#%11111101	; Set sound WE low
		AND	VIA_STATUS
		STA	(IOBASE),Y	; enable sound data write
		LDA	VIA_STATUS	; set sound WE high
		STA	(IOBASE),Y	; disable sound data write
		LDY	YSAV		; restore Y register
		RTS

; **** Mute All Sound Chip Channels ********************************************

; ******************************************************************************

SOUND_MUTEALL	LDY	#$03		; channels 0..3 to mute
NEXTCHANNEL	TYA
		JSR	SOUND_MUTE	; mute current channel
		DEY			; next channel
		BPL	NEXTCHANNEL	; loop if not all four channels done
		RTS

; **** Mute A Sound Chip Channel ***********************************************

; Input: A - Channel # (0..3)

; ******************************************************************************

SOUND_MUTE	LDX	#$0F		; set attenuation level to maximum
					; fall through to set attenuation level

; **** Set Attenuation For A Sound Chip Channel ********************************

; Input: A - Channel # (0..3)
; 	 X - Attenuation Level 0..15 (0dB, 2dB, 4dB ... OFF)

; ******************************************************************************

SOUND_SETATN	STX	TEMP		; store attenuation level in TEMP variable
		CLC			; clear carry flag
		ROR	A		; and rotate channel number to bit 5 and 6
		ROR	A
		ROR	A
		ROR	A
		ORA	TEMP		; combine channel number with attenuation value
		ORA	#$90		; and also set bit 7 and 4
		JMP	SOUND_SENDBYTE	; send complete command byte to the sound chip

; **** Set Periodic Noise ******************************************************

; Input: X - Noise Shift Rate

; ******************************************************************************

SOUND_PNOISE	LDA	#$00
		BEQ	SET_NOISE

; **** Set White Noise *********************************************************

; Input: X - Noise Shift Rate

; ******************************************************************************

SOUND_WNOISE	LDA	#$01

; **** Set Noise ***************************************************************

; Input: A - 0 = Periodic Noise  1 = White Noise
;	 X - Noise Shift Rate

; ******************************************************************************

SOUND_SETNOISE	ASL	A
		ASL	A
SET_NOISE	STX	TEMP
		ORA	TEMP
		ORA	#$F0
		JMP	SOUND_SENDBYTE	; send complete command byte to the sound chip

; **** Set Sound Frequency in HZ ***********************************************

; Input: A - Channel (0..2)
;	 X - Frequency Low Bits 7..0
;	 Y - Frequency High Bits 9..8

; *****************************************************************************

SOUND_SETFREQ	CLC			; clear carry flag
		ROR	A		; and rotate channel number to bit 5 and 6
		ROR	A
		ROR	A
		ROR	A
		ORA	#$80		; set high bit
		STA	TEMP		; and store it in TEMP variable
		TXA			; load frequency low bits into A
		AND	#$0F		; we first want to send the lower 4 bits
		ORA	TEMP		; combined it with the channel number
		JSR	SOUND_SENDBYTE	; send complete first command byte to the sound chip
		TYA			; load frequency high bits into A
		STX	TEMP		; store frequency low bits to TEMP variable
		LDX	#$04		; we need four bits shifted
LOOP_NXT	ASL	TEMP		; shift highest bit of low frequency to Carry flag
		ROL	A		; and shift it into the high frequency bits
		DEX			; decrement counter
		BNE	LOOP_NXT	; do we need more shifts?
		JMP	SOUND_SENDBYTE	; send complete second command byte to the sound chip

; ******************************************************************************
; ***************************** MAIN MONITOR ***********************************
; ******************************************************************************

; **** Auto Terminal And Baud Rate Detection Routine ***************************

; ******************************************************************************

INITVECT        LDX	#LOW  NMI	; set NMI service routine
                LDY	#HIGH NMI
		STX	NMIVECT
		STY	NMIVECT+1
		LDX	#LOW  IRQ
		LDY	#HIGH IRQ
		JSR     SETIRQVECT      ; set IRQ service routine
		LDX	#LOW  NMI	; set standard IRQ and BRK user service routines
		LDY	#HIGH NMI
		STX	BRKUSR
                STY	BRKUSR+1
                STX	IRQUSR
		STY	IRQUSR+1
                RTS
                
; ******* OLD ******************************************************************

;INITVECT        LDX	#LOW  NMI	; set NMI service routine
;                LDY	#HIGH NMI
;		 STX	NMIVECT
;		 STY	NMIVECT+1
;		 JSR    SETIRQVECT      ; set IRQ service routine
;		 LDX	#LOW  IRQ
;		 LDY	#HIGH IRQ
;		 JSR	SETIRQVECT
;		 STX	IRQUSR
;		 STY	IRQUSR+1
;		 LDX	#LOW  BREAK	; set BRK service routine
;		 LDY	#HIGH BREAK
;		 STX	BRKUSR
;                STY	BRKUSR+1
;                RTS
                
; ******************************************************************************

MAINSTART       SEI			; disable Interrupts
                LDX     #$FF
		TXS			; initialize stack pointer
		CLD			; set binary mode

                LDA     #LOW _HANDLER_  ; low address to empty event handler (RTS)
                STA     KEY_HANDLER     ; init character input handler low address
                STA     NKEY_HANDLER    ; init no character input handler low address
                LDA     #HIGH _HANDLER_ ; high address to empty event handler (RTS)
                STA     KEY_HANDLER+1   ; init character input handler high address
                STA     NKEY_HANDLER+1  ; init no character input handler high address

                JSR     INITVECT

INITRESET       LDX     #LOW  MON_WARM_START
		LDY     #HIGH MON_WARM_START
                STX     RETURN_VECT     ; set entry point for monitor warm start
                STY     RETURN_VECT+1

		LDA     #$80
		JSR  	DELAY		; wait for ~128ms after reset
		JSR	INITIO		; find and initialize IO cards
VTDETECT	JSR  	DELAY		; wait for ~128ms after reset
		STA  	STAT_REG   	; reset ACIA

; ******************************************************************************
; Set Fixed Baud Rate Patch
; ******************************************************************************

		LDA	#$3E
		STA	PBDD
		LDA	#$06		; set keyboard decoder Q3 to low
		STA	PBD		; write value to RIOT port B
		LDA	$FFF9		; load standard baud rate value (19200 8 N 1)
		STA	BAUDRATE	; and store it in detected baud rate variable
		LDA  	#$0B       	; set ACIA to
         	STA  	COMM_REG	; no parity, no receiver echo, RTS low, no IRQ, DTR low
		LDA	PBD		; read RIOT port B
		LDX	#$0F		; set all keyboard decoder outputs to high
		STX	PBD		; write value to RIOT port B
		ROR	A		; rotate bit 0 into Carry
		BCC	INIT		; if Carry = 0 then skip autodetection

; ******************************************************************************

		LDA	#CMD_INIT
		JSR	CMDPRINT	; try to detect connected terminal

; **** Main Initialization Routine *********************************************

; ******************************************************************************

INIT            JSR     BEEP		; give some feedback
		LDA  	BAUDRATE   	; load selected baud rate
		STA  	CTRL_REG	; set detected baud rate
		BNE     INIT_END	; terminal detected or fixed baud rate?
		LDA	$FFF9		; no, load standard baud rate value
		STA  	CTRL_REG	; set baud rate
		LDA     DEVID
		CMP     #TTY1_ID        ; is TTY still the standard output device?
		BNE     SET_CRTDEV      ; no, CRT controller is installed. Continue initialization
		JMP  	JCRESET		; TTY ist still sdtoutdev, but not connected. Jump to junior monitor

SET_CRTDEV      STA     STDOUTDEV       ; make CRT controller the standard output device
                JSR     SET_STDOUTID
                LDA	#CMD_INIT
		JSR	CMDPRINT	; initialize standard output device

INIT_END        CLI			; enable interrupts

; **** Main Program Loop *******************************************************

; ******************************************************************************

MAIN		JSR	CGET		; clear input buffer
		JSR  	CLRLOADSTR    	; clear screen and load pointer to string table
		LDA  	#$1F
		JSR  	TAB		; send some space chars to center title
        	LDY  	#TITLE-STRINGP 	; load title string
		JSR  	WRSTR		; and write it
		JSR     WRITE_IO_INFO

CHK_IO_CARD     LDA	IOBASEH		; language card available?
		BEQ	SHOWMON		; no, just start monitor
		LDY	#IOCARD-STRINGP ; load detect message
		JSR	WRSTR		; and write it
		LDA	IOBASEH
		JSR	HEXOUT
		LDA	#$00
		JSR	HEXOUT
		LDA	STDINDEV
		CMP	#KEYBD1_ID	; is ASCII keyboard the standard input device?
		BNE	SHOW_CLOCK 	; no, show clock
		LDY	#KBDSTR-STRINGP	; yes, load detect message
		JSR	WRSTR		; and write it
		JSR	SETPPORTIN
SHOW_CLOCK	JSR	CLOCKSTART	; call clock

                JSR     SYS_BOOT        ; try to boot from storage device
                BCC     NO_BOOT_DEV     ; no boot device found, show menu
                JMP     BLOCK_BUF       ; jump to boot code
NO_BOOT_DEV     LDA	#$00
                LDY	#ACR		; select auxilary control register
		STA	(IOBASE),Y	; disable shift operation
                JSR     LOADSTRING
		LDY	#SPACE-STRINGP
		JSR	WRSTR		; write spacer lines
		LDA	#$1E		; send some space chars to center menu
		JSR  	TAB
		LDY	#MENU-STRINGP   ; load menu string
		JSR	WRSTR		; and write it
		LDA	#LOW LANGNAME	; load language name
		STA	PSTRL
		LDA	#HIGH LANGNAME
		STA	PSTRH
		JSR	STROUT		; and write it
		LDA	#SPC
		JSR	COUT
		LDA	#'?'
		JSR	COUT
MLOOP		JSR  	CIN		; main menu loop
        	AND  	#$DF		; convert the input to uppercase char
        	CMP  	#'M'		; (M)onitor choosen?
		BNE	MNEXT1
STARTMON	JMP  	MONITOR		; yes, start monitor
MNEXT1		CMP	LANGKEY		; compare with language key char
		BNE	MNEXT
		JSR  	CLRSCRN    	; clear screen
		JMP	$B000		; jump to language start
MNEXT		JMP  	MLOOP		; no valid input choosen, try again
SHOWMON		JMP	MONRESET

; Load String Pointer **********************************************************

CLRLOADSTR      JSR     CLRSCRN
LOADSTRING	LDA  	#LOW STRINGP 	; load string pointer 1
		STA  	PSTRL
		LDA  	#HIGH STRINGP
		STA  	PSTRH
		RTS
LOADSTRING2	LDA  	#LOW STRINGP2 	; load string pointer 2
		STA  	PSTRL
		LDA  	#HIGH STRINGP2
		STA  	PSTRH
		RTS

WRITE_IO_INFO   LDA     #$10
		STA     IO_INFO
CHK_IO_0	LDA     FGCBASEH        ; controller card 0 available?
		BEQ     CHK_IO_1        ; no, check next card
		STA     IO_INFO+1
		JSR     CALL_INFO
CHK_IO_1        LDA     CARD3BASEH      ; controller card 1 available?
                BEQ     IO_INFO_END     ; no, exit
                STA     IO_INFO+1
		JSR     CALL_INFO
IO_INFO_END	RTS

CALL_INFO       JMP     (IO_INFO)

; ******************************************************************************
; MONITOR COMMAND EXECUTOR ROUTINES
; ******************************************************************************

; print command ****************************************************************

PRINTOUT	STY	YSAV		; save y register
		LDA	STDPRINTDEV	; get standard printer
		JSR	SET_STDOUTID    ; and make it the current output device
		LDY	YSAV		; restore y register
		INY
		LDA  	STRBUF,Y   	; get next input char
		AND  	#$DF		; uppercase chars only
		CMP  	#'D'		; print mem dump?
		BEQ	PRINTDUMP
		JSR	DISASSEM
		JMP	ENDINP
PRINTDUMP	JSR	MEMDUMP		; print memory dump
		BCC	ENDINP 		; normal termination?
		JSR	BEEP		; no, ESC pressed. Beep
ENDINP		JSR	CROUT		; send CR/LF to print last line
		LDA	STDOUTDEV	; get standard output device
		JSR	SET_STDOUTID    ; and make it the current output device
		JMP	MONINP		; get next command line

; XMODEM load/save command *****************************************************

XMODEM		DEX			; check read/write mode
		BEQ	XMODEML		; read mode?
		LDA	MODE		; no, test if valid address mode
		BEQ	NOTVALID	; not valid, get next input
		JSR	XModemSnd	; call xmodem send
		BEQ	XMODEME
XMODEML		JSR	XModemRcv	; yes, call xmodem receive
XMODEME		JMP	MONINP		; get next command line

; parallel load/save command ***************************************************

PARALLEL	DEX			; check read/write mode
		BEQ	PARALLELL	; read mode?
		LDA	MODE		; no, test if valid address mode
		BEQ	NOTVALID	; not valid, get next input
		JSR	PPORTSAVE	; call save pport ### not implemented yet
		JMP	MONINP
PARALLELL	JSR	PPORTLOAD	; call load pport ### not implemented yet
		JMP	MONINP		; get next command line

; tape load/save command *******************************************************

TAPE		INY
		DEX			; check read/write mode
		BEQ	TAPEL		; read mode?
		LDA	MODE		; no, test if valid address mode
		BEQ	NOTVALID	; not valid, get next input
		LDA	#CMD_SAVE	; set save to tape command
		BNE	OPENTAPE
TAPEL		LDA	#CMD_LOAD	; set load from tape command
OPENTAPE	PHA			; save command to stack
		LDA	#TAPE1_ID	; open tape1 device
		STY	YSAV		; save y register
		JSR	DEV_OPEN	; open tape device
		LDY	YSAV		; restore y register
		JSR	STRINPUT	; check for filename
		PLA			; restore command
		JSR	CMDDEV		; and send it to opened device
		JMP	MONINP		; get next command line

; load/save command ************************************************************

LOADSAVE	LDA	MODE		; check address mode
		ASL	A
		BMI	CHKNEXTCMD	; mode = $C0 (block mode)?
		LDA	#$FF		; no, set end address to $ffff
		STA	NUML
		STA	NUMH
CHKNEXTCMD	INY
		LDA  	STRBUF,Y   	; get next input char
		AND  	#$DF		; uppercase chars only
		CMP  	#'M'		; load/save via xmodem
		BEQ  	XMODEM
		CMP  	#'P'		; load/save via parallel port
		BEQ  	PARALLEL
		CMP  	#'T'		; load/save via tape
		BEQ  	TAPE
		CMP	#'0'
		BCS	NOTVALID
		DEX			; check load/save mode
		BNE	NOTVALID	; if save mode, just get next input char
		JSR	DISASSEM	; last command was L, so call disassembler
		JMP	MONINP		; we are finnished, get next input line
NOTVALID	LDA	#$00		; no valid command, so restore registers
		TAX
		JMP  	SETMODE2   	; and get next input char

; save command *****************************************************************

SAVE		INX

; load command *****************************************************************

LOAD		INX
		JMP	LOADSAVE

; print command ****************************************************************

PRINT		JMP	PRINTOUT

; call a program ***************************************************************

RUN		JSR	PRADDRESS
		LDA	#'R'		; print R to signal run mode
		JSR	COUT
		JSR	CROUT
		JSR     EXECPROG
		JMP  	MONINP		; jump back from program call
EXECPROG	JMP  	(ADRL)     	; jump to program address; execute program

; **** Start Of Hex Monitor ****************************************************

; ******************************************************************************

MONITOR 	JSR  	CLRLOADSTR    	; clear screen and load pointer to string table
		LDY  	#MONSTR-STRINGP
        	JSR  	WRSTR		; show monitor title
MONRESET	JSR	SETPPORTIN	; initialize RIOT
MONINP		JSR  	CROUT
		LDA  	#PROMPT
		JSR  	COUT		; show monitor prompt
		JSR  	STRIN      	; read input string
		LDY  	#$00       	; reset string index
		TYA			; mode = 0 (none)

MONINIT		TAX
SETADRMODE	STA  	MODE
SKIPCMDCHR      INY			; increment string index
NEXTCMDCHR	LDA  	STRBUF,Y   	; get next input char
		CMP  	#CR
		BEQ  	ENDCMD 		; end of input line, return to reader routine
		CMP  	#' '
		BEQ  	SKIPCMDCHR 	; ignore spaces
		CMP  	#'.'
		BEQ  	SETBLKMODE 	; block mode
		CMP	#':'
		BEQ	SETADRMODE
		AND  	#$DF		; uppercase chars only
		CMP  	#'L'		; LOAD/LIST command
		BEQ	LOAD 		; load or list data
		CMP  	#'S'		; SAVE command
		BEQ	SAVE		; save data
		CMP	#'P'		; PRINT command
		BEQ	PRINT		; print data
		CMP  	#'G'		; GO command
		BEQ  	RUN		; call program
		CMP  	#'M'		; JUNIOR MONITOR command
		BNE  	NEXTCMD
		JMP	JCRESET		; execute original junior computer monitor
NEXTCMD		CMP  	#'Q'		; QUIT command
		BEQ  	MONEND		; exit monitor program
		LDA	MODE		; test if list command pending
		BMI	DUMP		; if mode = $80, dump last line
		STY  	YSAV		; save Y
		JSR  	HEXINPUT   	; read hex number
	 	CPY  	YSAV		; min 1 hex digit entered?
		BEQ  	SKIPCMDCHR     	; no, read next command
		LDA  	MODE
		BNE	SETMODE
STOREADR	LDA  	NUML       	; yes, copy input value to last address
                STA  	ADRL
                LDA  	NUMH
                STA  	ADRH
		LDA	#$00		; line list mode
SETMODE		CMP	#':'		; is it store mode?
		BEQ	STOREDATA	; yes, store data
		ORA	#$80
SETMODE2	STA	MODE
		BNE	NEXTCMDCHR	; branch always
SETBLKMODE	LDA	#$40		; set block list mode
		BNE	SETADRMODE
ENDCMD		LDA	MODE		; test if list command pending
		BMI	DUMP		; yes, dump last line
CMDEND		JMP	MONINP		; read next command line
MONEND		JMP     (RETURN_VECT)   ; return to monitor caller

; store data *******************************************************************

STOREDATA	LDA  	NUML       	; load lower byte of number
                STA  	(ADRL,X)   	; store current store address (X=0)
                INC  	ADRL       	; increment lower store index.
                BNE  	NEXTITEM    	; no overflow
                INC  	ADRH       	; add carry to upper store index
NEXTITEM        JMP  	NEXTCMDCHR    	; get next command string

; call memory dump *************************************************************

DUMP		JSR	MEMDUMP
		BCC	NEXTCMDCHR   	; get next input
		BCS	CMDEND		; yes, stop printing memory dump

; print memory dump ************************************************************

MEMDUMP		LDX	#$00
		STX  	PDBCNT		; printed data byte count = 0
		JSR	CHKESC		; ESC pressed?
		BCC	PRADR		; no, go on dumping
		RTS			; yes, exit leaving carry flag set
PRADR		JSR	PRADDRESS	; print current address

; print current data byte ******************************************************

PRDATA		JSR  	SPCOUT		; print space
                LDA  	(ADRL,X)   	; get data from address (X=0)
                JSR  	HEXOUT     	; print data in hex format
		INC  	PDBCNT     	; increment data counter

; examine next address *********************************************************

ADRNEXT		JSR	CMPADDR		; see if there's more to print
                BCS  	FINISHED?  	; no more data to output

		JSR	INCADR          ; increment list index
DIVCHK          LDA  	PDBCNT
		CMP  	#$08
		BNE  	MOD16CHK	; do we need a divider?
		JSR  	SPCOUT		; yes, print single SPC as block divider
MOD16CHK	LDA  	ADRL       	; if address MOD 16 = 0 start new line
                AND  	#$0F
		BNE  	PRDATA
		JSR  	PRASCII
		JMP  	MEMDUMP		; print next line

; check if line print completed ************************************************

FINISHED?	LDA  	MODE		; examine last mode
		STX  	MODE       	; set mode 0
		ASL	A		; mode = $D0?
		BPL  	ENDDUMP		; no, get next input
		JSR  	PRASCII		; yes, we are not finished, print ASCII output for last address
ENDDUMP		CLC			; normal exit, so clear carry flag
		RTS

; print a column with ASCII representation of data *****************************

PRASCII         STY  	YSAV       	; store Y
		SEC			; no carry to subtract
		LDA  	#52		; max tabs
		SBC  	PDBCNT		; calc tab count to print ASCII column
		SBC  	PDBCNT		; tab = 52-3*printed_data_bytes_count
		SBC  	PDBCNT
		LDY  	PDBCNT
		CPY  	#9		; more than 8 bytes viewed?
		BCS  	NOADJUST	; no
		ADC  	#1		; yes, adjust by one char for block divider
NOADJUST	JSR  	TAB		; print tab spaces

		LDY  	#$00
NEXTASC		LDA  	(ASCL),Y   	; get data from address
		CMP	#$7F
		BCS  	NOASC      	; char >= ASCII 127? yes, print '.'
		CMP  	#' '
		BCS  	ASCOUT		; printable character?
NOASC		LDA  	#'.'       	; no, print '.'
ASCOUT		JSR  	COUT
		INY
		CPY  	PDBCNT
		BNE  	NEXTASC
		LDY  	YSAV       	; restore Y
		RTS

; Prompt new line with current address *****************************************

;*******************************************************************************

PRADDRESS	JSR  	CROUT
		LDA  	ADRH
                STA  	ASCH		; store current print address high-order byte
		JSR  	HEXOUT		; print high-order byte of address
                LDA  	ADRL
		STA  	ASCL		; store current print address low-order byte
                JSR  	HEXOUT		; print low-order byte of address
		LDA  	#ADIV      	; print '-'
                JMP  	COUT

; Compare if start address ADR is greater end address NUM **********************

;*******************************************************************************

CMPADDR		LDA  	ADRL       	; see if there's more to print
                CMP  	NUML
                LDA  	ADRH
                SBC  	NUMH
		RTS

; Jump to original Junior Computer reset vector ********************************

;*******************************************************************************

JCRESET		LDA	#$06		; set PB5 = L (WRITE)
		STA	PBD
		SEI
		JSR     INITVECT
                JSR     TAPEIRQ_OFF
		CLI
		JMP	RESET		; jump to Junior Computer reset routine

; ******************************************************************************
; String Data Section
; ******************************************************************************

MAGIC0		DB	$65,$22,$65,$22                 ; Magic number of IO-Card
MAGIC1          DB      $18,$90,$00,$90                 ; clc bcc 00 bcc

PSSTR		TEXT	"PSAYX"				; processor status string

STRINGP							; *** string base pointer ***

ESCCLS  	DB     	$32,$4A,$1B,$5B                 ; VT100 clear screen sequence
ESCHOME        	DB     	$48,$00                 	; VT100 cursor home sequence
ESCCLL        	DB     	$32,$4B,$00         		; VT100 clear line sequence
ESCGID		DB     	$30,$63,$00	        	; VT100 get ID sequence
ESCNORM		DB     	$6D,$00	        		; VT100 set normal text mode
ESCINV		DB     	$37,$6D,$00	        	; VT100 set inverse text mode
ESCBLNK		DB     	$35,$6D,$00	        	; VT100 set blinking text mode

TITLE		TEXT   	"Junior Computer ]["
        	DB     	CR,CR,CR
		TEXT   	" BIOS Version "
        	DB     	VERMAIN,$2E,VERPSUB,$2E,VERSSUB,CR
        	TEXT   	" 2020/24 by Joerg Walke"
		DB     	CR,CR,$00
IOCARD		TEXT	" IO/Language-Card at $"
		DB	$00
KBDSTR		DB	CR
		TEXT	" ASCII Keyboard connected"
		DB	$00
SPACE    	DB     	CR,CR,CR,CR,$00
MENU		TEXT   	"(M)onitor  "
        	DB     	$00
MONSTR		DB	CR
		TEXT   	"Hex Monitor"
		DB     	CR,$00

DT_NOT_SET	DB	13,13
		TEXT	" Date/Time not set"
		DB	13,0
DATEINPUT	DB	13
		TEXT	" Date: "
		TEXT	"DD"
		DB	DATEDIV
		TEXT	"MM"
		DB	DATEDIV
		TEXT	"YY"
		DB	8,8,8,8,8,8,8,8,0
TIMEINPUT	DB	13
		TEXT	" Time: "
		TEXT	"HH"
		DB	TIMEDIV
		TEXT	"MM"
		DB	TIMEDIV
		TEXT	"SS"
		DB	8,8,8,8,8,8,8,8,0

STRINGP2

DAYS		TEXT	"MON"
		DB	0
		TEXT	"TUE"
		DB	0
		TEXT	"WED"
		DB	0
		TEXT	"THU"
		DB	0
		TEXT	"FRI"
		DB	0
		TEXT	"SAT"
		DB	0
		TEXT	"SUN"
		DB	0

OSID            TEXT    "JCOS"
BOOTDEV         DB      CR
                TEXT    " Booting from "
                DB      0
NOBOOTDEV       DB      CR
                TEXT    " No Boot Disk found"
                DB      0
SDCDEV          TEXT    "SDC1"
                DB      0

; ******************************************************************************
; START OF DISASSEMBLER
; ******************************************************************************

DISASSEM	LDA	MODE
		ASL	A
		BPL	SHOW1PAGE	; mode <> $C0 (block mode)?
NEXTLINE1	JSR     CHKESC          ; ESC pressed?
		BCS	ENDDISASSEM	; yes, quit disassembling
NEXTOP		JSR	LOADOPCODE	; load current opcode
MORE?		JSR	CMPADDR		; see if there's more to print
                BCC  	NEXTLINE1  	; no more data to output
		RTS
SHOW1PAGE	LDA	#23		; show 23 disassembled lines
		STA	LINECNT
NEXTLINE2	JSR	LOADOPCODE	; load current opcode
		DEC	LINECNT
		BNE	NEXTLINE2	; more lines to show?
ENDDISASSEM	RTS			; no, jump back to monitor

; load next opcode

LOADOPCODE	JSR	PRADDRESS	; print current address
		LDY	#$00
		LDA	(ADRL),Y	; load opcode
		TAY			; store opcode in Y
		AND	#$03
		CMP	#$03		; is it a unused opcode?
		BNE	DECODE  	; no, decode it
		LDY	#$02		; Y points to unused opcode $02 to print '???'
		TYA			; and we also need it in A
		BNE	DECODEMNEM	; branch always

; decode opcode index into compressed opcode instruction table

DECODE		TYA			; reload opcode into A
		LSR	A		; every fourth column in the opcode table is a (opcode) gap
		LSR	A		; so we have to adjust the index because these columns are
					; stripped off in our indirect index table
		STA	TEMP		; store number of bytes to subtract
		TYA			; reload opcode again
		SEC
		SBC	TEMP		; and subtract value in TEMP from the original opcode.
DECODEMNEM	STY	OPCODE		; store opcode
		TAY			; Y holds now the actual index to the stripped opcode table
		LDA	OPCODES,Y	; load packed mnemonic_index/instr._bytes from opcode table
		TAY			; and save to Y
		AND	#$03		; the lower two bits are the number of instruction bytes
		STA	IBYTES		; store it in IBYTES var
		TYA			; reload packed index
		LSR	A		; and strip the lower two bits off
		LSR	A
		TAY			; Y holds now the index to the mnemonics table
		LDA   	MNEMONICSH,Y    ; load first packed byte of mnemonic string
		STA   	ASCH            ; and store it as left byte of mnemonic
		LDA   	MNEMONICSL,Y    ; load second packed byte of mnemonic string
		STA   	ASCL            ; and store it as right byte of mnemonic
		JSR	SHOWHEX		; first print out all instruction bytes as hex numbers
		LDX   	#$03		; we have to unpack three chars
NEXTMCHR        LDA   	#$00		; clear A
		LDY   	#$05            ; shift 5 bits into A
NEXTSHIFT       ASL   	ASCL           	; MSBit of ASCL in C
		ROL   	ASCH		; C in LSBit of ASCH and MSBit of ASCH in C
		ROL   	A		; C in A
		DEY
		BNE   	NEXTSHIFT
		ADC   	#'?'		; add offset to result, to make it an ASCII char
		JSR     COUT		; print one character of mnemonic
		DEX
		BNE     NEXTMCHR	; more chars to decode?
		LDA	#$02		; print two space chars
		JSR	TAB

; decode address mode and print left part of mode string ('#', '(' or 'A')

		LDX     #$A0            ; default address mode is implied
		LDY	#$FF
NEXTMASK	INY
		CPY	#$0F		; all masks tested?
		BEQ	ENDMASK		; yes, finish. Address mode is implied
		LDA	ADRMODEM,Y	; load mask
		AND	OPCODE		; mask opcode
		CMP	ADRMODEC,Y	; is it the mask result?
		BNE	NEXTMASK	; no, try next mask
		LDX	ADRMODER,Y	; yes, load the resulting address mode
ENDMASK		STX	ADRMODE		; save address mode
		TXA			; address mode is in A
		AND	#$0F		; A holds left mode string index
		TAY
		LDA	ADRMSTRL,Y      ; load left mode string
		BEQ	PRINTVAL	; is it a NULL char? Then there is nothing to print
		JSR	COUT		; else print character

; print either one or two operand value bytes

PRINTVAL	JSR	INCADR		; increment current address
		LDX	IBYTES		; load number of instruction bytes
		DEX			; more than one IBs?
		BEQ	ENDINC		; no, just finish
		LDA	#'$'		; yes, print operant value
		JSR	COUT		; first print out '$' as hex number indicator
		LDY	#$01
		DEX			; more than two IBs?
		BEQ	HEX1		; no, just print one byte
		LDA	(ADRL),Y	; load high byte
		JSR	HEXOUT		; and print it as hex number
HEX1		DEY
		LDA	(ADRL),Y	; load low byte
		LDX	ADRMODE
		CPX	#$A4		; is it a branch opcode?
		BEQ	CALCADR		; yes, calculate branch destination address
		JSR	HEXOUT		; no, print byte as hex number

; print right part of mode string. (',X', ',Y', ',X)', '),Y' or ')' )

		TXA			; load address mode in A
		LSR	A		; upper nibble is index to right address mode string
		LSR	A		; so we have to shift it right by four bits
		LSR	A
		LSR	A
		TAY
NEXTAMCHR	LDA	ADRMSTRR,Y	; load one char of right mode string
		BEQ     ENDMODE		; if a NULL char then we are finished
		JSR	COUT		; else print char
		INY
		BNE	NEXTAMCHR	; branch always

; finish current instruction

ENDMODE		LDA	IBYTES		; how many address increments left?
		CMP	#$03
		BNE	INCADR		; just one?
		JSR	INCADR		; no, two increments needed

; increment current address

INCADR  	INC  	ADRL    	; increment current address
        	BNE  	ENDINC  	; no carry!
        	INC  	ADRH
ENDINC		RTS			; end of disassembly

; calculate destination address for branch instructions

CALCADR		SEC
		TAY			; transfer A to Y for sign test
		BPL	ADDOFS		; is the branch offset positiv?
		EOR	#$FF		; no, subtract offset from current address
		STA	STOL
		LDA	ADRL
		SBC	STOL		; subtract branch offset from LSB current address
		TAY			; store low byte of address to Y
		LDA	ADRH
		SBC	#$00		; substract carry from MSB of address
		JMP	PRINTOFFS
ADDOFS		ADC	ADRL		; add branch offset to LSB of current address
		TAY			; store low byte of address to Y
		LDA	ADRH
		ADC	#$00		; add carry to MSB of address
PRINTOFFS	JSR	HEXOUT		; print high byte of branch address
		TYA
		JSR	HEXOUT		; print low byte of branch address
		JMP	INCADR		; and increment current address by one

; show instruction bytes as hex values and trailing variable number of space chars

SHOWHEX		LDY	#$00
NEXTBYTE	JSR	SPCOUT		; print leading space char
		LDA	(ADRL),Y	; load data byte
		JSR	HEXOUT		; and print it
		INY
		CPY	IBYTES		; all data bytes printed?
		BNE	NEXTBYTE	; no, print next byte
		LDA	#$0C		; tab size is 12
		SEC
CALCTAB		SBC	#$03		; reduce tab space by 3 for every data byte
		DEY
		BNE	CALCTAB		; all data bytes considered?
		JMP	TAB

; Address Mode Decode Tables ***************************************************

; Mask, Mask Result and Mode tables. If Opcode and Mask = Mask Result then Mode
; each Mode holds two indices (4 bits R | 4 bits L) to the mode string parts

; ******************************************************************************

ADRMODEM	DB	$FF,$FF,$FF,$1F,$1F,$1F,$1F,$1F,$9F,$9F,$1C,$1C,$DF,$1C,$1C ; mask bits

ADRMODEC	DB	$6C,$A2,$BE,$01,$09,$10,$11,$19,$0A,$80,$04,$0C,$96,$14,$1C ; mask result bits

ADRMODER	DB	$52,$A1,$80,$32,$A1,$A4,$72,$80,$A3,$A1,$A0,$A0,$80,$00,$00 ; packed mode bits

; Address Mode Strings *********************************************************

ADRMSTRL	DB	$00,$23,$28,$41,$00
		;	 0   #   (   A   0

ADRMSTRR	DB	$2C,$58,$00,$2C,$58,$29,$00,$29,$2C,$59,$00
		;	 ,   X   0   ,   X   )   0   )   ,   Y   0

; Mnemonics Table **************************************************************

; three characters packed in two bytes. Each character uses 5 bits, last bit is
; unused

; ******************************************************************************

; low bytes of table

MNEMONICSL	DB	$48, $CA, $1A, $08, $28, $A4, $AA, $94
     		DB	$CC, $5A, $D8, $C8, $E8, $48, $4A, $54
     		DB	$6E, $A2, $72, $74, $88, $B2, $B4, $26
     		DB	$C8, $F2, $F4, $A2, $26, $44, $72, $74
     		DB	$26, $22, $C4, $44, $62, $44, $62, $1A
     		DB	$26, $54, $68, $C8, $88, $8A, $94, $44
     		DB	$72, $74, $B2, $B4, $32, $44, $68, $84, $00

; high bytes of table

MNEMONICSH	DB	$11, $13, $15, $19, $19, $19, $1A, $1B
     		DB	$1B, $1C, $1C, $1D, $1D, $23, $23, $23
     		DB	$23, $23, $24, $24, $29, $29, $29, $34
     		DB	$53, $53, $53, $5B, $5D, $69, $69, $69
     		DB	$6D, $7C, $84, $8A, $8A, $8B, $8B, $9C
     		DB	$9C, $9D, $9D, $A0, $A1, $A1, $A1, $A5
     		DB	$A5, $A5, $A8, $A8, $AD, $AE, $AE, $AE, $00

; Compressed Opcode Table ******************************************************

; each byte holds a 6 bit index to the mnemonic table and 2 bits instruction
; byte count
; empty opcode table columns (3,7,B,F) are stripped out

; ******************************************************************************

OPCODES         DB	$29, $8A, $E1, $E1, $8A, $0A, $91, $8A, $09, $E1, $8B, $0B
     		DB	$26, $8A, $E1, $E1, $8A, $0A, $35, $8B, $E1, $E1, $8B, $0B
     		DB	$73, $06, $E1, $1A, $06, $9E, $99, $06, $9D, $1B, $07, $9F
     		DB	$1E, $06, $E1, $E1, $06, $9E, $B1, $07, $E1, $E1, $07, $9F
     		DB	$A5, $5E, $E1, $E1, $5E, $82, $8D, $5E, $81, $6F, $5F, $83
     		DB	$2E, $5E, $E1, $E1, $5E, $82, $3D, $5F, $E1, $E1, $5F, $83
     		DB	$A9, $02, $E1, $E1, $02, $A2, $95, $02, $A1, $6F, $03, $A3
     		DB	$32, $02, $E1, $E1, $02, $A2, $B9, $03, $E1, $E1, $03, $A3
     		DB	$E1, $BE, $E1, $C6, $BE, $C2, $59, $E1, $D5, $C7, $BF, $C3
     		DB	$0E, $BE, $E1, $C6, $BE, $C2, $DD, $BF, $D9, $E1, $BF, $E1
     		DB	$7E, $76, $7A, $7E, $76, $7A, $CD, $76, $C9, $7F, $77, $7B
     		DB	$12, $76, $E1, $7E, $76, $7A, $41, $77, $D1, $7F, $77, $7B
     		DB	$4E, $46, $E1, $4E, $46, $52, $69, $46, $55, $4F, $47, $53
     		DB	$22, $46, $E1, $E1, $46, $52, $39, $47, $E1, $E1, $47, $53
     		DB	$4A, $AE, $E1, $4A, $AE, $62, $65, $AE, $85, $4B, $AF, $63
     		DB	$16, $AE, $E1, $E1, $AE, $62, $B5, $AF, $E1, $E1, $AF, $63

; ******************************************************************************
; START OF HIGH LEVEL REAL TIME CLOCK CODE
; ******************************************************************************

; **** Check If Date/Time Is Set And Show Date/Time ****************************

CLOCKSTART	JSR	CHECKDATETIME
		JSR	CROUT
		JSR	CROUT
		JSR	SPCOUT
		JMP	PRINTDATETIME

; **** Check If Date/Time Is Set ***********************************************

; ******************************************************************************

CHECKDATETIME	LDA	#$08
		JSR	READCLOCK
		CPY	#$65
		BNE	DATETIMELOST
		CPX	#$02
		BNE	DATETIMELOST
		RTS

DATETIMELOST	JSR	LOADSTRING
		LDY	#DT_NOT_SET-STRINGP
		JSR	WRSTR

SETDATETIME	JSR	SETTIME

SETDATE		JSR	LOADSTRING
		LDA	#'.'
		STA	DIVCHAR
		LDY	#DATEINPUT-STRINGP
		JSR	WRSTR
		LDY	#$31
		JSR	GETDIGIT
		STA	YREG
		JSR	PRINTDIVCHAR
		LDY	#$12
		JSR	GETDIGIT
		STA	XREG
		JSR	PRINTDIVCHAR
		LDY	#$99
		JSR	GETDIGIT
		STA	ACC
		JMP	WRITEDATE2

SETTIME		JSR	LOADSTRING
		LDA	#':'
		STA	DIVCHAR
		LDY	#TIMEINPUT-STRINGP
		JSR	WRSTR
		LDY	#$23
		JSR	GETDIGIT
		STA	ACC
		JSR	PRINTDIVCHAR
		LDY	#$59
		JSR	GETDIGIT
		STA	XREG
		JSR	PRINTDIVCHAR
		LDY	#$59
		JSR	GETDIGIT
		STA	YREG
		JMP	WRITETIME2

GETDIGIT	INY
		STY	YSAV
GETDIGIT1	JSR	NUMINPUT
		BCC	GETDIGIT1
		TAX
		SBC	#48
		ASL	A
		ASL	A
		ASL	A
		ASL	A
		CMP	YSAV
		BCS	GETDIGIT1
		STA	TEMP
		TXA
		JSR	COUT
GETDIGIT2	JSR	NUMINPUT
		BCC	GETDIGIT2
		TAX
		SBC	#48
		ORA	TEMP
		CMP	YSAV
		BCS	GETDIGIT2
		STA	TEMP
		LDA	#'.'
		CMP	DIVCHAR
		BNE	GETDIGITEND
		LDA	TEMP
		BEQ	GETDIGIT2
GETDIGITEND	TXA
		JSR	COUT
		LDA	TEMP
		RTS


NUMINPUT	JSR	CIN
		CMP	#'0'
		BCC	NOTNUM
		CMP	#':'
		BCC	ISNUM
NOTNUM		CLC
		RTS
ISNUM		SEC
		RTS

; **** Print Date And Time *****************************************************

; ******************************************************************************

PRINTDATETIME	JSR	PRINTDATE	; print current date	; PRINTFULLDATE
		JSR	SPCOUT
		JSR	PRINTTIME	; print current time
		JMP	CROUT

; **** Print Time **************************************************************

; ******************************************************************************

PRINTTIME	LDA	#':'
		STA	DIVCHAR
		JSR	READTIME
		JSR	PRINTDIGIT
		TXA
		JSR	PRINTDIGIT
		TYA
		JMP	HEXOUT

; **** Print Date And Day Of Week **********************************************

; ******************************************************************************

PRINTFULLDATE	JSR	READDOW
		ASL	A
		ASL	A
		TAY
		LDA  	#LOW DAYS-4
		STA  	PSTRL
		LDA  	#HIGH DAYS-4
		STA  	PSTRH
		JSR	WRSTR
		JSR	SPCOUT

; **** Print Date **************************************************************

; ******************************************************************************

PRINTDATE	LDA	#DATEDIV	; load divider char
		STA	DIVCHAR
		JSR	READDATE	; read current date
		STA	TEMP		; store year value in TEMP
		TYA
		JSR	PRINTDIGIT	; print day
		TXA
		JSR	PRINTDIGIT	; print month
		LDA	#CENTURY
		JSR	HEXOUT		; print century
		LDA	TEMP
		JMP	HEXOUT		; print year

PRINTDIGIT	JSR	HEXOUT		; print digit
PRINTDIVCHAR	LDA	DIVCHAR		; print divider char
		JMP	COUT

; ******************************************************************************
; START OF LOW LEVEL ROUTINES
; ******************************************************************************

; **** Print Processor Status **************************************************

; ******************************************************************************

PRSTATUS	JSR	PRADDRESS	; print current program counter
		LDX	#$04
NXTREG		JSR	SPCOUT		; print space char
		LDA	PSSTR,X		; load register label
		JSR	COUT		; and print it
		LDA	#'='
		JSR	COUT		; print =
		LDA	PREG,X
		JSR	HEXOUT
		DEX
		BPL	NXTREG
		RTS

; **** Initialize IO Devices ***************************************************

; ******************************************************************************

INITIO          LDA     #$00
                LDX     #$06
INITIO1         STA     IOBASE,X        ; clear K2,K3 and K4 base address pointers
                DEX
                BNE     INITIO1

                JSR     DEV_INIT        ; initialize driver list
SET_TTY_DEV     LDX     #LOW  TTY_DEV
                LDY     #HIGH TTY_DEV
                JSR     DEV_ADD         ; add terminal driver
		STA	STDINDEV        ; and initially set TTY as standard IO
		STA	STDOUTDEV
		STA     DEVID

SET_XMODEM_DEV  LDX     #LOW  XMODEM_DEV
                LDY     #HIGH XMODEM_DEV
                JSR     DEV_ADD         ; add xmodem driver

SET_PRINTER_DEV LDX     #LOW  PPRINT_DEV
                LDY     #HIGH PPRINT_DEV
                JSR     DEV_ADD         ; add parallel printer driver
                STA	STDPRINTDEV     ; and initially set parallel port printer as standard printer

		JSR     DETECT_IO       ; detect IO cards

; TEMP #### future: Set std beep only if no language card found

INIT_BEEP	LDA	#LOW DOBEEP	; load low byte of address of system beep
		STA	STDBEEP
		LDA	#HIGH DOBEEP	; load high byte of address of system beep
		STA	STDBEEP+1

                JMP     RESET_STDIO     ; reset to standard IO devices

IO_INITIALIZE   JMP     (ADRL)

; **** Scan Bus And Detect IO Cards ********************************************
;
; ******************************************************************************

DETECT_IO       LDA     #$FB
                STA     ADRL            ; set pointer to init routine
                LDA     #$07
                STA     ADRH
                LDA     #$03            ; search on three slot base addresses
                STA     PDBCNT
DETECT_LOOP     CLC
                LDA     ADRH
                TAX
                INX                     ; X holds slot base address high byte
                ADC     #$04
                STA     ADRH            ; set high byte to init routine
                LDY	#$03            ; test byte string in card ROM against magic number
COMP_LOOP	LDA	MAGIC1,Y        ; get one byte of magic number
		CMP	(ADRL),Y        ; and compare it with ROM content
		BNE	NO_MATCH        ; byte does not match, exit inner detection loop
		DEY                     ; byte matched magic number, try next one
		BPL	COMP_LOOP       ; more bytes to compare?
		JSR     IO_INITIALIZE   ; IO card detected. Call init routine
NO_MATCH        DEC     PDBCNT
                BNE     DETECT_LOOP     ; try next card base address
                                        ; fall through to IO/Language Card detection

; **** Try To Detect IO/Language Card ******************************************
;
; ******************************************************************************

DETECT_IOL_CARD	LDA	#$00
		STA	IOBASEL		; set low byte of IO base pointer to $00
		STA	IOBASEH		; set high byte of IO base pointer to $00
		LDA	K4+$20		; walk through all IO spaces
		LDA	K3+$20		; and trigger annunciator address
		LDA	K2+$20		; to initially switch from ROM to RAM
K4?		LDY	#$10
		LDA	K4+$30		; try switching to ROM at base address $1000.
		JSR	GETMAGIC	; get magic number?
		BEQ	STOREBASE	; yes, store base address.
K3?		LDY	#$0C		; no,
		LDA	K3+$30		; try switching to ROM at base address $0C00.
		JSR	GETMAGIC	; get magic number?
		BEQ	STOREBASE	; yes, store base address.
K2?		LDY	#$08		; no,
		LDA	K2+$30		; try switching to ROM at base address $0800.
		JSR	GETMAGIC	; get magic number?
		BEQ	STOREBASE	; yes, initialize IO card
NOCARD          RTS                     ; no card found

STOREBASE	STY	IOBASEH		; card found, set high byte of base pointer.

; **** Initialize The IO/Language Card *****************************************

; ******************************************************************************

INIT_IOCARD     LDA     STDINDEV
                CMP     #TTY1_ID
                BNE     INIT_VIA        ; is standard input device still TTY?
                JSR	DETECT_ASCIIKBD	; yes, check if ASCII keyboard available, else skip it
INIT_VIA	LDY	#PORTB
		LDA	#%01001110	; SDA=0,/CAS_MOT=1,CAS_SENSE=0,CAS_WR=0,/SPI_LOAD=1,SPI_CS=1,/SND_WE=1,SCL=0
		STA	VIA_STATUS	; store current PortB output status
		STA	(IOBASE),Y	; set SDA as input to pull it high, set SCL as input to pull it high
		LDY	#DDRB		; initialize data direction of port B
		LDA	#%01011110	; SDA,/CAS_MOT,/CAS_SENSE,CAS_WR,/SPI_LOAD,SPI_CS,/SND_WE,SCL
		STA	(IOBASE),Y
		LDY	#DDRA		; initialize data direction of port A
		LDA	#$FF		; all pins of port A are outputs
		STA	(IOBASE),Y
		JSR	SOUND_MUTEALL	; mute sound output
INIT_SDCARD     JSR     SPI_INIT        ; initialize SPI
                LDX     #LOW  SDC_DEV
                LDY     #HIGH SDC_DEV
                JSR     DEV_ADD         ; add sd-card driver
INIT_TAPE       LDA	#$00
                LDY	#ACR		; select auxilary control register
		STA	(IOBASE),Y	; set one shot timer mode
                STA	KEY_SENSE	; reset tape sense line status
		LDY	#PCR		; select peripheral control register
		STA	(IOBASE),Y	; set interrupt on falling edge of CA1
		;LDY	#IER		; select interrupt enable register
		JSR	TAPERW_OFF	; turn tape read/write mode off
		JSR	RESET_TIMER2	; set Timer2 to 1/60 second
                LDX     #LOW  TAPE_DEV
                LDY     #HIGH TAPE_DEV
                JSR     DEV_ADD         ; add tape driver
		LDX	#LOW  TAPEIRQ 	; set low address of clock interrupt routine
		LDY	#HIGH TAPEIRQ   ; set low address of clock interrupt routine
SETIRQVECT	STX	IRQVECT
		STY	IRQVECT+1
		RTS

; ******************************************************************************
; START OF TAPE READ/WRITE ROUTINES
; ******************************************************************************

TAPEESC		JMP	BREAKSYNC

; *** Tape Load Routine ********************************************************

; ******************************************************************************

TAPELOAD	JSR	PREPFILENAME
		JSR	TAPE_PLAY_MSG	; print PLAY message
		JSR	TAPE_ESC_MSG
WAITPLAY	JSR	CHKESC		; <ESC> key pressed?
		BCS	TAPEESC		; yes -> exit
		LDA	KEY_SENSE	; check sense line status
		BNE	WAITPLAY	; if <> 0, wait until datasette key pressed down
		JSR	TAPERW_ON	; turn off key clock interrupt and turn on bit read interrupt
STARTLOAD	JSR	TAPE_LOAD_MSG	; print LOAD message
		JSR	MOTOR_ON	; and turn motor on
STARTSYNC	LDA	#$01		; we are in sync mode
		STA	BITCNT		; so initialize bit counter to just one bit
WAITBIT		LDY	#PORTB		; set index to Port B
		LDA	(IOBASE),Y	; load port B
		AND	#$20		; test tape sense line at PB5
		BNE	BREAKSYNC	; if sense line is high, PLAY key is no longer down -> exit.
READSYNC	LDA	BITCNT		; bit counter reached 0 ?
		BNE	WAITBIT		; no, wait for more bits
		LDA	OUTBYTE		; yes, load current byte into A
		CMP	#SYNCMARK	; is it a valid sync mark?
		BNE	STARTSYNC	; no, resync
		LDX	#$00
		STX	IBYTES		; yes, reset sync block counter
GETBYTE?	JSR	BYTE_IN		; read next full byte
		LDA	OUTBYTE		; and load it into A
		CMP	#SYNCMARK	; still a sync mark?
		BNE	SYNCEND?	; no, check if end of sync
		INX			; yes, increment sync mark counter
		BNE	GETBYTE?	; 256 sync marks read? no read more
		JSR	COUT		; yes, print '.'
		INC	IBYTES		; increment sync block counter
		JMP	GETBYTE?	; and read next byte
SYNCEND?	LDA	IBYTES
		BEQ	STARTSYNC	; at least one sync block read? no resync
		JSR	READHEADER	; yes, read header. C = 0 if no header mark is found. X returns 0
		BCC	STARTSYNC	; no header mark found or names not equal. resync
		STX	BLKNO		; BLKNO = 0
		STX	CHECKSUM	; CHECKSUM = 0
NEXTBLK		LDA	OUTBYTE		; load current block number into A
		CMP	BLKNO		; is it the expected number?
		BNE	ERRLOAD		; no, error.
NEXTDATA	JSR	BYTE_IN		; yes, read next data byte
		LDA	OUTBYTE		; and load it into A
		LDY	#$00
		STA	(ADRL),Y	; store read data byte to destination address
		EOR	CHECKSUM	; XOR it with checksum
		STA	CHECKSUM	; and write result back to checksum
		JSR	CMPADDR		; see if there's more to load
                BCS  	ENDLDDATA  	; no, finish loading
		JSR	INCADR		; yes, increment current destination address
		INX
		BNE	NEXTDATA	; and read next byte
		JSR	BYTE_IN		; read checksum
		LDA	OUTBYTE		; and load it int A
		CMP	CHECKSUM	; compare expected check sum with calculated checksum
		BNE	ERRLOAD		; if checksum incorrect, exit with error
		JSR	BYTE_IN		; read next block number
		INC	BLKNO		; increment internal block counter
		JMP	NEXTBLK		; read next block
ENDLDDATA	JSR	BYTE_IN		; read last checksum
		LDA	OUTBYTE		; and load it int A
		CMP	CHECKSUM	; compare expected check sum with calculated checksum
		BNE	ERRLOAD		; if checksum incorrect, exit with error
		JSR	TAPE_OK_MSG	; print OK message
ENDLOAD		JSR	TAPERW_OFF	; return to clock interrupt
		JMP	MOTOR_OFF	; and turn motor off

BREAKREAD	PLA			; clean up stack
		PLA
		PLA
BREAKSYNC	JSR	TAPE_BREAK_MSG	; print BREAK message
		JMP	ENDLOAD		; and exit

ERRLOAD		JSR	TAPE_ERR_MSG	; print error message
		JMP	ENDLOAD		; end exit

; *** Read Tape Header Routine *************************************************

; ******************************************************************************

READHEADER	LDA	OUTBYTE		; load current byte
		CMP	#ADDRMARK	; is it a address mark?
		BNE	NOHDRMARK	; no, exit
		LDY	#$00		; set string counter to 0
		STY	EQUFLAG		; clear character compare flag
		LDX	#$06		; 6 bytes (start address, end address, reserved) to read
READADDR	JSR	BYTE_IN		; read new address byte
		LDA	OUTBYTE		; and load it into A
		STA	NUML-3,X	; store it to pinter location
		LDA	TAPEFND,Y	; load one char of "found" message
		JSR	COUT		; and print it
		INY			; increment message pointer
		DEX			; decrement byte read counter
		BNE	READADDR	; more address bytes to read?
		JSR	BYTE_IN		; read next byte
		LDA	OUTBYTE		; and load it into A
		CMP	#NAMEMARK	; is it a name mark?
		BNE	READFIRSTBYTE	; no, read first data byte
		LDY	#$00		; reset name string pointer
READNAME	JSR	BYTE_IN		; read name char
		LDA	OUTBYTE		; load it into A
		STA	IBYTES 		; and save value
		CMP	#FILEMARK	; is it the file mark?
		BEQ	READFIRSTBYTE	; yes, read first data byte
		BCC	MARKERROR 	; is character < spac char? yes show error
		JSR	COUT		; no, print current name char
		LDA	RBUFF,Y		; load compare char
		CMP	#'*'		; is it a '*'?
		BEQ	READNAME	; yes, skip compare
		INY
		EOR	IBYTES		; is char of search name equal current name?
		BEQ	READNAME	; yes, read next char
		STA	EQUFLAG		; no, mark name as not equal
		BNE	READNAME	; and read next char

READFIRSTBYTE	LDA	EQUFLAG		; is search name equal current name?
		BNE	NAMENEQ		; no, we need to skip the file
		LDA	RBUFF,Y
		CMP	#'*'		; was last char in search name a '*'?
		BEQ	NAMEEQU		; yes, name is equal
		LDA	RBUFF,Y		; no, is search name length equal current name length?
		BNE	NAMENEQ		; no, we need to skip the file
NAMEEQU		JSR	BYTE_IN		; yes, read first data Byte
		SEC			; header OK, so set carry flag
		RTS

NAMENEQ		JSR	TAPE_SKIP_MSG	; print skip message
NOHDRMARK	CLC			; header not OK, so clear carry flag
		RTS

MARKERROR	PLA			; clear return address
		PLA
		JMP	ERRLOAD		; and jump to error routine

; *** Tape Byte Read Routine ***************************************************

; ******************************************************************************

BYTE_IN		TYA			; save Y register
		PHA
		LDY	#PORTB		; select port B register
READBIT		LDA	(IOBASE),Y	; read port B Bits
		AND	#$20		; test tape sense line at PB5
		BNE	BREAKREAD	; play key is no longer down, stop reading
		LDA	BITCNT		; load bit counter
		BNE	READBIT		; check again until bit counter = 0
		LDA	#$08
		STA	BITCNT		; reset bit counter
ENDBYTE_IN	PLA			; yes, restore Y register
		TAY
		RTS

; *** Tape Save Routine ********************************************************

; ******************************************************************************

TAPESAVE	JSR	PREPFILENAME
		JSR	TAPE_REC_MSG	; Print press record message
		JSR	TAPE_ESC_MSG
WAITRECORD	JSR	CHKESC		; <ESC> key pressed?
		BCS	BREAKSAVE	; yes -> exit
		LDA	KEY_SENSE	; Check if any Datasette key is pressed
		BNE	WAITRECORD	; No, repeat check
		JSR	TAPE_SAVE_MSG	; Print save message
		SEI			; Yes, disable interrupts
		JSR	STROUT		; Print file name
		LDA	#$FF
		STA  	CNTA		; Initialize timer value
		LDA	#$06		; Write 6x256 Byte blocks of sync marks
		JSR	WRITESYNC	; Write sync marks
		JSR	WRITEHEADER	; Write tape header
		LDA	#FILEMARK
		JSR	BYTE_OUT	; Write file mark
		LDA	#$00
		STA	CHECKSUM	; Initialize XOR data checksum
		STA	BLKNO		; Initialize block numbers
		TAX			; Initialize Byte counter
NEXTBLOCK	JSR	BYTE_OUT	; Write block number to tape
WRNXTBYTE	LDY	#PORTB
		LDA	(IOBASE),Y	; Read Port B
		AND	#$20		; Test tape sense line at PB5
		BNE	BREAKSAVE	; No Datasette key pressed. Stop saving
		LDY	#$00
		LDA	(ADRL),Y	; Load current data Byte
		TAY			; Save data to Y register
		EOR	CHECKSUM	; XOR data with checksum
		STA	CHECKSUM
		TYA			; Reload data into Accumulator
		JSR	BYTE_OUT	; Write data Byte to tape
		JSR	CMPADDR		; See if there's more to copy
                BCS  	ENDDATA  	; No more data to copy
		JSR	INCADR		; Increment current save address
		INX			; Increment Byte counter
		BNE	WRNXTBYTE	; If less than 256 Bytes written, then write next data Byte
ENDBLOCK	LDA	CHECKSUM	; Else...
		JSR	BYTE_OUT	; Write checksum at the end of block
		INC	BLKNO		; Increment block number
		LDA	BLKNO
		JMP	NEXTBLOCK	; Write next block
ENDDATA		LDA	CHECKSUM
		JSR	BYTE_OUT	; Write checksum at end of block
		LDA	#$03
		JSR	BYTE_OUT	; Write End-Of-Text mark
		JSR	TAPE_OK_MSG	; Print OK message
ENDSAVE		CLI			; Reenable interrupts
		JMP	MOTOR_OFF	; Stop motor

; ******************************************************************************

BREAKSAVE	JSR	TAPE_BREAK_MSG	; Print Break message
		JMP	ENDSAVE

; **** Write Synchronization Bytes To Tape *************************************

; ******************************************************************************

WRITESYNC	STA	STOH
		LDA	#$00
		STA	STOL
		LDA	#SYNCMARK	; Load sync mark
		STA	OUTBYTE		; and store it to output variable
PLOOP		JSR	WRITEBYTE	; Write sync mark
		DEC	STOL		; Decrement loop counter
		BNE	PLOOP		; Repeat loop if counter low byte > 0
		DEC	STOH		; Overflow, decrement counter high byte
		BNE	PLOOP		; Repeat loop if counter high byte > 0
ENDPREAMBLE	RTS

; **** Write File Header To Tape ***********************************************

; ******************************************************************************

WRITEHEADER	LDX	#$06
		LDA	#ADDRMARK	; load address mark
WRITEADDR	JSR	BYTE_OUT	; write to tape
		LDA	NUML-3,X	; load address byte
		DEX
		BPL	WRITEADDR	; all address fields written? no repeat
		LDA	#NAMEMARK	; yes, load name mark
		JSR	BYTE_OUT	; and write it to tape
		LDY	#$00		; index to first filename char
WRNXTCHAR	LDA	RBUFF,Y		; load filename char
		BEQ	ENDHEADER	; is it a NULL? yes -> exit
		JSR	BYTE_OUT	; no write filename char to tape
		INY			; increment index to next filename char
		BNE	WRNXTCHAR	; and write it
ENDHEADER	RTS

; **** Write Tape Byte Routine *************************************************

; ******************************************************************************

BYTE_OUT	STA	OUTBYTE		; save output byte
WRITEBYTE	TXA			; save X register
		PHA
		TYA			; save Y register
		PHA
WAIT_BIT1	BIT  	CNTIRQ		; timer counted to zero
		BPL  	WAIT_BIT1	; no, repeat test
		LDX	#8		; initialize bit counter
NEXT_BIT	LDY	#PORTB
		LDA	#%00010000	; set CAS_WR output HIGH
		ORA	VIA_STATUS	; get old output status and set CAS_WR Pin
		STA	(IOBASE),Y
		ROL	OUTBYTE		; rotate next output bit to carry flag
		BCC	SET_SHORT	; if carry = 0 then write short pulse
SET_LONG	LDY	#LPTIME		; else write long pulse
		BNE	WRITE_BIT
SET_SHORT	LDY	#SPTIME		; set short pulse value
WRITE_BIT	STY	YSAV		; save pulse width value for low phase
		JSR	SHORTDELAY1	; high phase delay
		LDY	#PORTB		; index to port B
		LDA	#%11101111	; set CAS_WR output LOW
		AND	VIA_STATUS	; get old output status and clear CAS_WR pin
		STA	(IOBASE),Y
		LDY	YSAV		; restore delay value for low phase of pulse
		DEX
		BEQ	ENDWRITE	; all bits done? yes, exit routine
		JSR	SHORTDELAY1	; low phase delay
		JMP	NEXT_BIT	; continue bit send loop
ENDWRITE	STY  	CNTA		; set timer for final low phase
		ROL	OUTBYTE		; rotate one bit to restore old Byte value
		PLA
		TAY			; restore Y register
		PLA
		TAX			; restore X register
		RTS

; **** VIA2 IRQ Routine ********************************************************

; ******************************************************************************

TAPEIRQ		PHA			; save accumulator
		TYA
		PHA			; save Y register
		LDY	#IFR		; select interrupt flag register
		LDA	(IOBASE),Y
		BPL	NOTAPEIRQ	; check if it was a VIA2 interrupt
		AND	#$02		; yes, CA1 interrupt occured?
		BEQ	CHECKKEY	; no, check key status
CHECKBIT	DEC	BITCNT		; decrement bit counter
		LDY	#PORTA
		LDA	(IOBASE),Y	; clear CA1 interrupt flag
		LDA	CNTIRQ		; load timer IRQ status
		ASL	A		; and shift it into the carry flag
		ROL	OUTBYTE		; save carry as current bit value
		LDA	#RPTIME
		STA	CNTB		; set timer to Read-Point-Time
		BNE	ENDTAPEIRQ	; and exit IRQ routine
CHECKKEY	JSR	CHECK_KEYSIG	; check tape sense line
		JSR	RESET_TIMER2	; reset Timer2 and interrupt flags
		LDA     TICKCNT         ; load the tick counter
		BEQ     ENDTAPEIRQ      ; is it 0?
		DEC     TICKCNT         ; no, decrement tick counter
ENDTAPEIRQ	PLA
		TAY			; restore Y register
		PLA			; restore accumulator
		RTI

NOTAPEIRQ	PLA
		TAY			; restore Y register
	        PLA			; restore accumulator
USRIRQ		JMP	IRQ		; call user interrupt routine

; **** Reset Timer2 Routine ****************************************************

; ******************************************************************************

RESET_TIMER2	LDY	#T2CL		; select Timer2 lower byte register
		LDA	#$4B		; reset Timer2
		STA	(IOBASE),Y	; store timer low value
		LDA	#$41
		INY			; select Timer2 higher byte register
		STA	(IOBASE),Y	; store timer high value
		RTS

; **** Check Tape Sense Line Routine *******************************************

; ******************************************************************************

CHECK_KEYSIG	LDY	#PORTB
		LDA	(IOBASE),Y
		AND	#$20		; test tape sense line at PB5
		CMP	KEY_SENSE	; is it different to old tape sense line status?
		BEQ	ENDCHECK	; no, just return
 		STA	KEY_SENSE	; yes, save new state value
		BCS	MOTOR_OFF
		BCC	MOTOR_ON
ENDCHECK	RTS

; **** Turn Tape Drive Motor On ************************************************

; ******************************************************************************

MOTOR_ON	LDY	#PORTB
		LDA	#%10111111	; set CAS_MOT line low
		AND	VIA_STATUS
		STA	VIA_STATUS
		STA	(IOBASE),Y
		RTS

; **** Turn Tape Drive Motor Off ***********************************************

; ******************************************************************************

MOTOR_OFF	LDY	#PORTB
		LDA	#%01000000	; set CAS_MOT line high
		ORA	VIA_STATUS
		STA	VIA_STATUS
		STA	(IOBASE),Y
		RTS

; **** Tape IRQ Off ************************************************************

; ******************************************************************************

TAPEIRQ_OFF     LDY	#IER		; select interrupt enable register
                LDA     IOBASEH
                BEQ     TAPEIRQ_OFF1    ; IO card available? No, just exit
		LDA	#$7F
		STA	(IOBASE),Y	; disable all VIA2 interrupts
TAPEIRQ_OFF1	RTS

; **** Turn Tape Read/Write Mode On ********************************************

; ******************************************************************************

TAPERW_ON	JSR	TAPEIRQ_OFF
		LDA	#$82
		STA	(IOBASE),Y	; set interrupt for CA1
		RTS

; **** Turn Tape Read/Write Mode Off *******************************************

; ******************************************************************************

TAPERW_OFF	JSR	TAPEIRQ_OFF
		LDA	#$A0
		STA	(IOBASE),Y	; set interrupt for Timer2
		RTS

; **** Prepare Filename ********************************************************

; Input: X - low byte of string pointer
;	 Y - high byte of string pointer

; ******************************************************************************

PREPFILENAME	JSR	SETSTRBUFF0
		LDY	#$00
		LDX	#$00
NEXTFNCHAR	LDA  	(PSTR),Y   	; get next input char
		BEQ	ENDFILENAME
		CMP	#'a'		; char < 'a'?
		BCC	COPYNAME	; no, just copy char to buffer
		CMP	#'{'		; char > 'z'?
		BCS	COPYNAME	; no, just copy char to buffer
		AND	#$DF		; convert to upper case char
COPYNAME	STA	RBUFF,X		; char to buffer
		INY
		INX
		BNE	NEXTFNCHAR	; read next char of filename
ENDFILENAME	CPX	#$00
		BNE	ENDPREP		; is X = 0? no -> exit
		LDA	#'*'		; yes, empty string.
		STA	RBUFF,X		; make it "*"
		INX
		TYA
ENDPREP		STA	RBUFF,X		; terminate string with NULL
		JSR	SETSTRBUFF
		RTS

; ******************************************************************************
; START OF XMODEM CODE
; ******************************************************************************
;
; XMODEM/CRC Sender/Receiver for the 6502
;
; By Daryl Rictor Aug 2002
;
; A simple file transfer program to allow transfers between the SBC and a
; console device utilizing the x-modem/CRC transfer protocol.
;
;*******************************************************************************
; This implementation of XMODEM/CRC does NOT conform strictly to the
; XMODEM protocol standard in that it (1) does not accurately time character
; reception or (2) fall back to the Checksum mode.

; (1) For timing, it uses a crude timing loop to provide approximate
; delays.  These have been calibrated against a 1MHz CPU clock.  I have
; found that CPU clock speed of up to 5MHz also work but may not in
; every case.  Windows HyperTerminal worked quite well at both speeds!
;
; (2) Most modern terminal programs support XMODEM/CRC which can detect a
; wider range of transmission errors so the fallback to the simple checksum
; calculation was not implemented to save space.
;*******************************************************************************
;
; Files transferred via XMODEM-CRC will have the load address contained in
; the first two bytes in little-endian format:
;  FIRST BLOCK
;     offset(0) = lo(load start address),
;     offset(1) = hi(load start address)
;     offset(2) = data byte (0)
;     offset(n) = data byte (n-2)
;
; Subsequent blocks
;     offset(n) = data byte (n)
;
; One note, XMODEM send 128 byte blocks.  If the block of memory that
; you wish to save is smaller than the 128 byte block boundary, then
; the last block will be padded with zeros.  Upon reloading, the
; data will be written back to the original location.  In addition, the
; padded zeros WILL also be written into RAM, which could overwrite other
; data.
;
;*******************************************************************************
;
; Code extensions 2022 by Joerg Walke
;
; Included: CAN command in addition to ESC to cancel sending and receiving data.
; Included: EOT command to signal end of transmition.
; Included: address range for received data, to override the start address in
;           the first data block and to prevent overwriting of data by
;	    trailing zeros.

; XMODEM Receive Routine *******************************************************

XModemRcv       JSR     PrintXStart
		STA	BLKEND		; set flag to false
                LDA     #$01
                STA     BLKNO           ; set block # to 1
                STA	BFLAG           ; set flag to get address from block 1
StartRcv        LDA     #"C"            ; "C" start with CRC mode
                JSR     SOUT	     	; send it
                LDA     #$FF
                STA     RETRYH          ; set loop counter for ~3 sec delay
                LDA     #$00
                STA     CRCL
                STA     CRCH            ; init CRC value
                JSR     GetByte         ; wait for input
		BCS     GotByte         ; byte received, process it
		JMP     StartRcv
StartBlk        LDA     #$FF
                STA     RETRYH          ; set loop counter for ~3 sec delay
                JSR     GetByte         ; get first byte of block
                BCC     StartBlk        ; timed out, keep waiting...
GotByte         CMP     #ESC            ; quitting?
                BEQ     GotESC          ; yes
		CMP	#CAN		; cancel?
		BNE     GotByte1	; no
GotESC          JMP     PrintXErr       ; print error and return
GotByte1        CMP     #SOH            ; start of block?
                BEQ     BegBlk          ; yes
                CMP     #EOT            ;
                BNE     BadCRC          ; Not SOH or EOT, so flush buffer & send NAK
                JMP     RDone           ; EOT - all done!
BegBlk          LDX     #$00
GetBlk          LDA     #$FF            ; 3 sec window to receive characters
                STA     RETRYH
GetBlk1         JSR     GetData         ; get next character
                BCC     BadCRC          ; chr rcv error, flush and send NAK
GetBlk2         STA     RBUFF,x         ; good char, save it in the rcv buffer
                INX                     ; inc buffer pointer
                CPX     #$84            ; <01> <FE> <128 bytes> <CRCH> <CRCL>
                BNE     GetBlk          ; get 132 characters
                LDX     #$00
                LDA     RBUFF,x         ; get block # from buffer
                CMP     BLKNO           ; compare to expected block #
                BEQ     GoodBlk1        ; matched!
                JSR     PrintXErr       ; Unexpected block number - abort
                JMP     Flush           ; mismatched - flush buffer and return
GoodBlk1        EOR     #$FF            ; 1's comp of block #
                INX                     ;
                CMP     RBUFF,x         ; compare with expected 1's comp of block #
                BEQ     GoodBlk2        ; matched!
                JSR     PrintXErr       ; Unexpected block number - abort
                JMP     Flush           ; mismatched - flush buffer and return
GoodBlk2        JSR     CalcCRC         ; calc CRC
                LDA     RBUFF,y         ; get hi CRC from buffer
                CMP     CRCH            ; compare to calculated hi CRC
                BNE     BadCRC          ; bad crc, send NAK
                INY                     ;
                LDA     RBUFF,y         ; get lo CRC from buffer
                CMP     CRCL            ; compare to calculated lo CRC
                BEQ     GoodCRC         ; good CRC
BadCRC          JSR     Flush           ; flush the input port
                LDA     #NAK            ;
                JSR     SOUT            ; send NAK to resend block
                JMP     StartBlk        ; start over, get the block again
GoodCRC         LDX     #$02            ;
                LDA     BLKNO           ; get the block number
                CMP     #$01            ; 1st block?
                BNE     CopyBlk         ; no, copy all 128 bytes
                LDA     BFLAG           ; is it really block 1, not block 257, 513 etc.
                BEQ     CopyBlk         ; no, copy all 128 bytes
		LDA     MODE		; address mode = 0?
		BEQ	READADR         ; yes, read start address from data stream
                INX
		BNE     READDATA	; branch always
READADR         LDA     RBUFF,x         ; get target address from 1st 2 bytes of blk 1
		STA     ADRL            ; save lo address
                INX
                LDA     RBUFF,x         ; get hi address
                STA     ADRH            ; save it
READDATA        LDA	ADRL
		STA	STOL		; save start address low byte
		LDA	ADRH
		STA	STOH		; save start address high byte
		INX                     ; point to first byte of data
                DEC     BFLAG           ; set the flag so we won't get another address
CopyBlk         LDY     #$00            ; set offset to zero
CopyBlk3        LDA     BLKEND		; block end flag set?
		BNE     CopyBlk5	; yes, skip reading data
		LDA     RBUFF,x         ; get data byte from buffer
		STA     (STOL),y        ; save to target
		SEC
                LDA     NUML
                SBC     STOL            ; are we at the last address?
                BNE     CopyBlk5  	; no, inc pointer and continue
                LDA     NUMH
                SBC     STOH
                BNE     CopyBlk5
                INC     BLKEND		; yes, set last byte flag
CopyBlk5	INC     STOL            ; point to next address
                BNE     CopyBlk4        ; did it step over page boundary?
                INC     STOH            ; adjust high address for page crossing
CopyBlk4        INX                     ; point to next data byte
                CPX     #$82            ; is it the last byte
                BNE     CopyBlk3        ; no, get the next one
IncBlk          INC     BLKNO           ; done.  Inc the block #
                LDA     #ACK            ; send ACK
                JSR     SOUT
                JMP     StartBlk        ; get next block
RDone           LDA     #ACK            ; last block, send ACK and exit.
                JSR     SOUT
                JSR     Flush           ; get leftover characters, if any
                JMP     PrintXSucc

; XMODEM Send Routine **********************************************************

XModemSnd       JSR     PrintXStart
		STA     ERRCNT          ; error counter set to 0
		STA     BLKEND          ; set flag to false
		LDA     #$01
                STA     BLKNO           ; set block # to 1
Wait4CRC        LDA     #$FF            ; 3 seconds
                STA     RETRYH
                JSR     GetByte
                BCC     Wait4CRC        ; wait for something to come in...
                CMP     #"C"            ; is it the "C" to start a CRC xfer?
                BEQ     SetStoAddr      ; yes
                CMP     #ESC            ; is it a cancel? <Esc> Key
                BEQ     DoCancel        ; No, wait for another character
		CMP     #CAN            ; is it a cancel?
                BNE     Wait4CRC        ; No, wait for another character
DoCancel        JMP     PrtAbort        ; Print abort msg and exit
SetStoAddr	LDA     #$01            ; manually load blk number
                STA     RBUFF           ; into 1st byte
                LDA     #$FE            ; load 1's comp of block #
                STA     RBUFF+1         ; into 2nd byte
                LDA     ADRL            ; load low byte of start address
                STA     RBUFF+2         ; into 3rd byte
                LDA     ADRH            ; load hi byte of start address
                STA     RBUFF+3         ; into 4th byte
		LDX     #$04            ; preload X to receive buffer
		LDY     #$00            ; init data block offset to 0
                BEQ     LdBuff1         ; jump into buffer load routine
LdBuffer        LDA     BLKEND          ; was the last block sent?
                BEQ     LdBuff0         ; no, send the next one
                JMP     SDone           ; yes, we're done
LdBuff0         LDX     #$02            ; init pointers
                LDY     #$00
                INC     BLKNO           ; inc block counter
                LDA     BLKNO
                STA     RBUFF           ; save in 1st byte of buffer
                EOR     #$FF
                STA     RBUFF+1         ; save 1's comp of blkno next
LdBuff1         LDA     (ADRL),y        ; save 128 bytes of data
                STA     RBUFF,x
LdBuff2         SEC
                LDA     NUML
                SBC     ADRL            ; are we at the last address?
                BNE     LdBuff4         ; no, inc pointer and continue
                LDA     NUMH
                SBC     ADRH
                BNE     LdBuff4
                INC     BLKEND          ; yes, set last byte flag
LdBuff3         INX
                CPX     #$82            ; are we at the end of the 128 byte block?
                BEQ     SCalcCRC        ; yes, calc CRC
                LDA     #$00            ; fill rest of 128 bytes with $00
                STA     RBUFF,x
                BEQ     LdBuff3         ; branch always
LdBuff4         INC     ADRL            ; inc address pointer
                BNE     LdBuff5
                INC     ADRH
LdBuff5         INX
                CPX     #$82            ; last byte in block?
                BNE     LdBuff1         ; no, get the next
SCalcCRC        JSR     CalcCRC
                LDA     CRCH            ; save hi byte of CRC to buffer
                STA     RBUFF,y
                INY
                LDA     CRCL            ; save lo byte of CRC to buffer
                STA     RBUFF,y
Resend          LDX     #$00
                LDA     #SOH
                JSR     SOUT            ; send SOH
SendBlk         LDA     RBUFF,x         ; send 132 bytes in buffer to the console
                JSR     SOUT
                INX
                CPX     #$84            ; last byte?
                BNE     SendBlk         ; no, get next
                LDA     #$FF            ; yes, set 3 second delay
                STA     RETRYH          ; and
                JSR     GetByte         ; wait for ACK/NACK
                BCC     SetError        ; no char received after 3 seconds, resend
                CMP     #ACK            ; char received... is it:
                BEQ     LdBuffer        ; ACK, send next block
                CMP     #NAK
                BEQ     SetError        ; NAK, inc errors and resend
                CMP     #ESC
                BEQ     PrtAbort        ; ESC pressed to abort
		CMP	#CAN
		BEQ     PrtAbort	; CANCEL send
					; fall through to error counter
SetError        INC     ERRCNT          ; inc error counter
                LDA     ERRCNT
                CMP     #$0A            ; are there 10 errors? (Xmodem spec for failure)
                BNE     Resend          ; no, resend block

PrtAbort        JSR     Flush           ; yes, too many errors, flush buffer,
                JMP     PrintXErr       ; print error msg and exit
SDone           JMP     PrintXSucc   	; All Done..Print msg and exit

; Get Data From Serial Port ****************************************************

GetData		LDA     #$00            ; wait for chr input and cycle timing loop
                STA     RETRYL          ; set low value of timing loop
LoopGetData     JSR     SIN        	; get chr from serial port, don't wait
                BCS     EndGetData      ; got one, so exit
                DEC     RETRYL          ; no character received, so dec counter
                BNE     LoopGetData
                DEC     RETRYH          ; dec hi byte of counter
                BNE     LoopGetData     ; look for character again
                CLC                     ; if loop times out, CLC, else SEC and return
EndGetData      RTS                     ; with character in A

; Get Byte From Serial Port. Check if ESC pressed ******************************

GetByte		LDA     #$00            ; wait for chr input and cycle timing loop
                STA     RETRYL          ; set low value of timing loop
LoopGetByte     LDA     #LOW SIN        ; check low byte of serial in address
		CMP	STDIN	        ; is Low(stdin) = Low(SIN)?
                BNE     GetChar         ; no, use standard Get Char Routine
                LDA     #HIGH SIN       ; yes, check high byte of serial in address
                CMP     STDIN+1         ; is High(stdin) = High(SIN)?
                BEQ	ReadByte	; yes, just read input stream
GetChar		JSR	CGET
		BCC	ReadByte
		CMP	#ESC
		BNE	ReadByte
		SEC
		BCS	EndGetByte
;		JSR	CHKESC		; no, check stdin if ESC key pressed
;		BCC	ReadByte	; no ESC pressed, read data byte from serial port
;		LDA	#ESC
;		BNE     EndGetByte      ; ESC pressed, so exit
ReadByte	JSR     SIN        	; get chr from serial port, don't wait
                BCS     EndGetByte      ; got one, so exit
                DEC     RETRYL          ; no character received, so dec counter
                BNE     LoopGetByte
                DEC     RETRYH          ; dec hi byte of counter
                BNE     LoopGetByte     ; look for character again
                CLC                     ; if loop times out, CLC, else SEC and return
EndGetByte      RTS                     ; with character in A

; Empty Buffer *****************************************************************

Flush           LDA     #$1C            ; flush receive buffer
                STA     RETRYH          ; flush until empty for ~1/4 sec.
Flush1          JSR     GetData         ; read the port
                BCS     Flush           ; if char received, wait for another
                RTS

; Calculate CRC ****************************************************************

CalcCRC		LDA	#$00		; calculate the CRC for the 128 bytes
		STA	CRCL
		STA	CRCH
		LDY	#$02
CalcCRC1	LDA	RBUFF,y
		EOR 	CRCH 		; Quick CRC computation with lookup tables
       		TAX		 	; updates the two bytes at crc & crc+1
       		LDA 	CRCL		; with the byte send in the "A" register
       		EOR 	CRCHI,x
       		STA 	CRCH
      	 	LDA 	CRCLO,x
       		STA 	CRCL
		INY
		CPY	#$82		; done yet?
		BNE	CalcCRC1	; no, get next
		RTS			; y=82 on exit

; Print XModem Messages ********************************************************

PrintXStart     SEI			; disable interrupts during XModem transfer
		JSR	Flush		; clear buffer
		LDY     #$00		; load start message
		BEQ	PrintXMsg

PrintXErr       JSR	BEEP
PrintXError	LDY     #(ERRX-MSGX)	; load error message
		CLC
		BNE     PrintXEnd

PrintXSucc      LDY     #(SUCCX-MSGX)	; load success message
		SEC
PrintXEnd	CLI			; enable interrupts

PrintXMsg	LDA     #$00
		ROL	A		; save carry
		PHA
PrintXMsg1	LDA  	MSGX,Y   	; load char at string pos y
		BEQ  	EndXMsg  	; exit, if NULL char
		JSR  	COUT       	; write character
		INY             	; next index
		BNE  	PrintXMsg1
EndXMsg		PLA
		LSR	A		; restore carry and leave A = 0
		RTS

; Tape Messages ****************************************************************

TAPE_OK_MSG	SEC
		LDY	#(TAPEOK-MSGX)
		BNE	PrintXMsg

TAPE_ERR_MSG	CLC
		LDY	#(TAPELDERR-MSGX)
		BNE	PrintXMsg

TAPE_BREAK_MSG	CLC
		LDY	#(TAPEBRK-MSGX)
		BNE	PrintXMsg

TAPE_SAVE_MSG	LDY	#(TAPESAV-MSGX)
		BNE	PrintXMsg

TAPE_LOAD_MSG	LDY	#(TAPELOD-MSGX)
		BNE	PrintXMsg

TAPE_SKIP_MSG	LDY	#(TAPESKIP-MSGX)
		BNE	PrintXMsg

TAPE_REC_MSG	JSR	TAPE_PLAY_MSG
		LDY	#(TAPEREC-MSGX)
		BNE	PrintXMsg

TAPE_PLAY_MSG	LDY	#(TAPEPLAY-MSGX)
		BNE	PrintXMsg

TAPE_ESC_MSG	LDY	#(ESCX-MSGX)
		BNE	PrintXMsg

; ******************************************************************************
; String Data Section
; ******************************************************************************

MSGX            DB      CR
		TEXT	"Begin data transfer"
ESCX		TEXT	", <ESC> to cancel. "
		DB     	$00
ERRX		DB	CR
		TEXT	"Transfer Error"
		DB      CR,$00
SUCCX           DB	EOT,EOT,EOT

TAPEOK		DB	CR
		TEXT 	"OK"
		DB  	CR,$00
TAPEPLAY	DB	CR
		TEXT	"Press PLAY"
		DB	$00
TAPEREC		TEXT	" & RECORD"
		DB	$00
TAPESAV		DB	CR
		TEXT	"saving "
		DB	$00
TAPESKIP	TEXT	", skipped"
TAPELOD		DB	CR
		TEXT	"loading"
		DB	$00
TAPEFND		TEXT	"found "
TAPEBRK		DB	CR
		TEXT	"Break"
		DB	CR,$00
TAPELDERR	DB	CR
		TEXT	"Load Error"
		DB	CR,$00
TAPEANYNAME	TEXT	"*"
		DB	$00

; **** IRQ, NMI and BREAK Service Routines *************************************

; ******************************************************************************

IRQ		STA	STOACC		; save current accumulator
		PLA			; get current processor status in A
		PHA			; and push it back to stack
		AND	#$10		; mask break flag
		BNE	USRBREAK	; if break flag set, jump to user break handler
		LDA	STOACC
		JMP	(IRQUSR)	; else jump to clock IRQ routine

USRBREAK	LDA	STOACC
		JMP	(BRKUSR)

NMI		STA	ACC		; save current accumulator

BREAK					; default IRQUSR & BRKUSR entry
		PLA			; get current processor status in A
		STA	PREG		; save it
		PHA			; and push it back to stack
		STX	XREG		; save x-register
		STY	YREG		; save y-register
		JSR	RESET_STDIO	; always reset to standard I/O
		PLP			; get last processor status
		PLA			; get last program counter low byte
		STA	PCL		; and store it
		STA	ADRL
		PLA			; get last program counter high byte
		STA	PCH		; and store it
		STA	ADRH
		TSX			; get current stack pointer
		STX	SPUSER		; and store it
		CLD			; set binary mode
		JSR	BEEP		; error beep
		JSR	PRSTATUS	; print user program status
		LDX     #$FF
		TXS			; initialize stack pointer
		CLI			; enable interrupts
		JMP	MONRESET	; and return to monitor

; **** Try To Read Magic Number ************************************************

; ******************************************************************************

GETMAGIC	LDX	#$04
MAGICLOOP	LDA	MAGIC0-1,X
		CMP	$DFFB,X
		BNE	NOMAGIC
		DEX
		BNE	MAGICLOOP
NOMAGIC		TXA
NOSTDPROC	RTS

; **** Write To Serial Routine *************************************************

; Input: A - Output Byte to RS232

; ******************************************************************************

SOUT
SERIALOUT	PHP			; save processor status
		SEI			; disable interrupts
		PHA			; save character
		LDA  	#$10
EMPTY?		BIT  	STAT_REG	; ACIA output register empty?
		BEQ  	EMPTY?		; no, check again.
		PLA			; restore character
		STA  	DATA_REG   	; write character to ACIA
		PLP			; restore processor status
		RTS

; **** Read From Serial Routine ************************************************

; Output: A - Input Byte from RS232
;         C - 1 char get, 0 no char get

; ******************************************************************************

SIN
SERIALIN	CLC              	; set to no chr present
		LDA	STAT_REG
		AND	#$08		; ACIA input register full?
		BEQ	SERIALEND	; no, just exit
		LDA	DATA_REG	; yes, read character
		SEC		 	; and set C = 1, char present
SERIALEND	RTS

; **** Read From ASCII Keyboard Routine ****************************************

; Output: A - Input Byte from Keyboard
;         C - 1 char get, 0 no char get

; ******************************************************************************

ASCIIKBD	LDA	PADD		; are we in read mode?
		BEQ	READMODE	; yes, check if data available
		JSR	SETPPORTIN	; no, first set parallel port as an input
READMODE	CLC			; set to no char present
		BIT	WRDC		; test PA7 (DATA_AVAIL)
		BVC	NODATA		; no new data, just exit with C = 0
		LDA	WRDC		; clear PA7 flag
		LDA	PAD		; load keyboard ASCII code from port A
		AND	#%01111111	; clear MSB
DATA_AVAIL	SEC			; and set C = 1, char present
NODATA		RTS

; **** PS2 Keyboard Driver Routine *********************************************

; Output: A - Input Byte from Keyboard
;         C - 1 char get, 0 no char get

; ******************************************************************************

PS2KBD          CLC                     ; set to no char present
                STY     PREG            ; save current Y register
                LDY     #PIA_PORTC
                LDA     (FGCBASE),Y     ; load data from Port C
                AND     #$20            ; and check Strobe line
                BEQ     PS2_NODATA      ; no data received, just exit with C = 0
                LDY     #PIA_PORTA
                LDA     (FGCBASE),Y     ; data received, load it from Port A
                BNE     PS2_DATA_AVAIL
                LDY     #PIA_PORTC      ; NULL Byte received, check for second byte
PS2_CHECK       LDA     (FGCBASE),Y     ; load data from Port C
                AND     #$20            ; and check Strobe line
                BEQ     PS2_CHECK       ; no data received, repeat
                LDY     #PIA_PORTA
                LDA     (FGCBASE),Y     ; data received, load it from Port A
                ORA     #$80            ; set bit 7
PS2_DATA_AVAIL  SEC			; and set C = 1, char present
PS2_NODATA      LDY     PREG            ; restore Y register
                RTS

; **** Detect ASCII Keyboard Routine *******************************************

; ******************************************************************************

DETECT_ASCIIKBD JSR	SETPPORTIN	; set parallel port as an input
		LDA	PAD		; read parallel port
		CMP	#$FF		; is there anything connected?
		BEQ	NOKBD		; no, just exit
                LDX     #LOW  KEYBD_DEV
                LDY     #HIGH KEYBD_DEV
                JSR     DEV_ADD         ; add ASCII keyboard driver
		STA	STDINDEV	; make it the standard input device
NOKBD		RTS

; **** Write To Parallel Port Routine ******************************************

; Input: A - Output Byte to parallel port

; ******************************************************************************

PPORTOUT	PHA			; save character
		LDA	#$BE		; initialize handshake line I/O on port b
		CMP	PBDD		; already initialized?
		BEQ	SETHSK		; yes, just set output values
		STA	PBDD		; no, PB7 = /strobe, PB6 = busy, PB5 = r/w, PB0 = speaker off
SETHSK		LDA	#$86		; set handshake lines to their initial values
		STA	PBD		; r/w = L, strobe = H, PB1,PB2 = H -> hex-kbd disabled; speaker = H
		LDA	#$FF		; all port A lines are outputs
		STA	PADD
		PLA			; reload character in A
		PHA
		STA	PAD		; set output data
PPORTBSY?	BIT	PBD		; bussy line is high?
		BVS	PPORTBSY?	; yes, check bussy line again
		LDA	#$06		; generate strobe pulse
		STA	PBD		; set strobe line low
		LDA	#$86
		STA	PBD		; set strobe line high
		PLA			; restore character
		RTS

; **** Read From Parallel Port Routine *****************************************

; Output: A - Input Byte from parallel port
;         C - 1 char get, 0 no char get

; ******************************************************************************

PPORTIN		JSR	SETPPORTIN	; set parallel port as input
		CLC
		BIT	PBD		; check if /STROBE = 0
		BMI	NOSTROBE	; no, just exit with C = 0
STROBE?		BIT	PBD		; yes, wait for strobe to come high again
		BMI	STROBE?
		LDA	PAD		; load data from port A
		SEC			; and set C = 1, data present
NOSTROBE	RTS

; **** Switch Parallel Port To Data Input **************************************

; ******************************************************************************

SETPPORTIN	LDA	#$00		; initialize port A as input
		STA	PADD
		LDA	#$3E		; initialize port B bits for read operation
		STA	PBDD
		LDA	#$26		; set PB5 = H (READ)
		STA	PBD
		STA	WRDC		; set PA7 raising edge detection, no interrupt
		LDA	WRDC		; clear interrupt flag
		RTS

; ******************************************************************************
; SPI Driver
; ******************************************************************************

; ******************************************************************************
; Initialize SPI Interface
; ******************************************************************************

SPI_INIT					;fall trough to SPI_SLOW

; ******************************************************************************
; Set SPI to Slow Mode (250KHz)
; ******************************************************************************

SPI_SLOW        LDA	#$04
		LDY	#ACR
		STA	(IOBASE),Y		; set VIA mode "shift in under T2 control"
		LDA	#$00			; reset Timer2
		LDY	#T2CL
		STA	(IOBASE),Y		; store timer low value
		JSR	SPI_RESET		; flush shift register
		RTS				; Clock is set to 250 kHz

; ******************************************************************************
; Set SPI to Fast Mode (500KHz)
; ******************************************************************************

SPI_FAST	LDA	#$08
		LDY	#ACR
		STA	(IOBASE),Y		; set VIA mode "shift in under phi2 control"
		RTS				; Clock is set to 500 kHz

; ******************************************************************************
; Write a Single Byte to the SPI Interface
;
; Input: A = Byte to Send
; ******************************************************************************

SPI_WRITE	STY	YSAV
		LDY	#PORTA
		STA	(IOBASE),Y		; output data to shift register
		LDY	#IFR
SPI_WRITE1	LDA	#$04			; set bit mask for data available flag
		AND	(IOBASE),Y		; shift register full?
		BEQ	SPI_WRITE1		; no, check again
		LDY	#PORTB
		LDA	#$42 			; SPI_CS = L; LOAD_DATA = 0
		STA	(IOBASE),Y		; load data into shift register
		LDA	#$4A 			; SPI_CS = L; LOAD_DATA = 1
		STA	(IOBASE),Y		; data is now in shift register
		BNE	SPI_RESET               ; branch always

; ******************************************************************************
; Read a Single Byte from the SPI Interface
;
; Output: A = Received Byte
; ******************************************************************************

SPI_READ	STY	YSAV
		LDY	#IFR
SPI_READ1	LDA	#$04			; set bit mask for data available flag
		AND	(IOBASE),Y		; shift register full?
		BEQ	SPI_READ1		; no, check again
SPI_RESET	LDY	#SR
		LDA	(IOBASE),Y		; start next shifting, clear data available flag
		LDY	YSAV
		RTS

; ******************************************************************************
; SD-Card Driver Routines
; ******************************************************************************

; ******************************************************************************
; Initialize SD-Card
; Output: C = 1 Init OK, C = 0 Error
; ******************************************************************************

SD_INIT		SEI                             ; disable interrupts
                LDA	#$00
		STA	SD_TYPE
		JSR	SD_RESET		; reset SD-Card
		CMP	#$01			; SD-Card present?
		BNE	SDC_NOT_FOUND		; invalid response, no usable card found
		JSR	SD_GET_VERS		; get SD-Card version
		CMP	#$05			; seems to be a version 1 card
		BEQ	INIT_SD0		; so just try to initialize it
		CMP	#$AA			; version 2 cards should response with $(01)AA
		BNE	SDC_NOT_FOUND		; invalid response, no usable card found
		LDA	#$40			; try ACMD41($40000000) init (SD Ver. 2+)
		BNE	INIT_SD1
INIT_SD0	LDA	#$00			; try ACMD41($00000000) init (SD Ver. 1)
INIT_SD1	JSR	SD_CLEAR_CMD		; prepare for new command
		STA	SD_PB3
INIT_SD2	LDA	#CMD55			; send prefix CMD55 (application cmd)
		JSR	SD_SEND_CMD
		CMP	#$01
		BNE	SDC_NOT_FOUND		; invalid response, no usable card found
		LDA	#ACMD41			; send ACMD41 (initialize)
		JSR	SD_SEND_CMD
		BEQ	INIT_SD3		; response = 0 means card waked up,
		CMP	#$01			; card still idle?
		BEQ	INIT_SD2		; yes, try again
		BNE	SDC_NOT_FOUND		; no, invalid response, no usable card found
INIT_SD3	LDA	SD_PB3			; Ver. 2+ Card?
		BEQ	INIT_SD4		; no, just set block size
		JSR	SD_CLEAR_CMD		; prepare for new command
		LDA	#CMD58			; send CMD58 (get OCR)
		JSR	SD_SEND_CMD
		BNE	SDC_NOT_FOUND		; invalid response, no usable card found
		JSR	SD_WAIT_RESP3		; wait for OCR response
		LDA	SD_PB3			; Test Bit 30
		AND	#$40			; 1 if SDHC/SDXC card, 0 else
		STA	SD_TYPE			; set type $00 Byte mode, $40 LBA mode
INIT_SD4	JSR	SD_CLEAR_CMD		; prepare for new command
		LDA	#$02			; set blocksize to 512 byte
		STA	SD_PB1
		LDA	#CMD16			; send CMD16 (set block size)
		JSR	SD_SEND_CMD
		BNE	SDC_NOT_FOUND		; invalid response, no usable card found
		JSR	SPI_FAST		; and switch to SPI fast mode (500kHz)
		CLI                             ; reenable interrupts
		SEC				; everything gone well, set carry
		RTS
SDC_NOT_FOUND	LDA	#$80
                CLI                             ; reenable interrupts
		CLC				; something went wrong, clear carry
		RTS				; to signal error

; ******************************************************************************
; Get SD-Card Version
; ******************************************************************************

SD_GET_VERS	LDA	#$01			; set parameter byte 1
		STA	SD_PB1
		LDA	#$AA			; set parameter byte 0
		STA	SD_PB0
		LDA	#$87			; set crc
		STA	SD_CRC
		LDA	#CMD8			; send CMD8($000001AA) (get version)
		JSR	SD_SEND_CMD		; response should be $01
		CMP	#$01			; SD-Card present?
		BNE	END_GET_VERS		; no, exit with result <> $01
						; yes, fall through to sd_wait_resp

; ******************************************************************************
; Wait for a 32 Bit Command R3 Response from SD-Card
; ******************************************************************************

SD_WAIT_RESP3	LDY	#$00
READ_RESP3	JSR	SD_WAIT_RESP		; yes, receive 4 response bytes
		STA	SD_PB3,Y		; store response bytes in PB0..3
		INY
		CPY	#$04
		BNE	READ_RESP3
END_GET_VERS	RTS

; ******************************************************************************
; Clear SD-Card Command Parameters
; ******************************************************************************

SD_CLEAR_CMD	LDA	#$00
		LDY	#$04			; 4 parameter bytes to clear
NEXT_PARAM	STA	SD_CMD,Y		; clear parameter byte
		DEY
		BNE	NEXT_PARAM		; more to clear?
		LDA	#$FF
		STA	SD_CRC			; no, finally set CRC byte to $FF
		RTS

; ******************************************************************************
; Send Command to SD-Card
; Input: A = Command Index
; ******************************************************************************

SD_SEND_CMD	STA	SD_CMD
		JSR	SPI_READ		; send one dummy
		LDX	#$00
SEND_BYTE	LDA	SD_CMD,X		; get one command byte
		JSR	SPI_WRITE		; and send it
		INX
		CPX	#$06			; all 6 cmd bytes send?
		BNE	SEND_BYTE		; no, send more bytes
						; yes, fall through to sd_wait_resp

; ******************************************************************************
; Wait for a 8 Bit Command R1 Response from SD-Card
; Output: A = Response Byte
; ******************************************************************************

SD_WAIT_RESP	LDX	#$08			; wait for max 8 cycles
READ_RESP1	JSR	SPI_READ		; receive data
		CMP	#$FF			; is it a $FF?
		BNE	RESPONSE		; no, card did response
		DEX				; yes, try again
		BNE	READ_RESP1		; check for timeout
RESPONSE	TAX
		TXA				; set proper status flags for A
		RTS

; ******************************************************************************
; Wait for a Special Token Response from SD-Card
; Input:  A = Token Byte
; Output: A = Response Byte
; ******************************************************************************

SD_WAIT_TOKEN	STA	TEMP			; store token into TEMP variable
		LDY	#$FF			; load low byte of time out counter
		LDX	#$0A			; load high byte of time out counter
WAIT_RESP	JSR	SPI_READ		; read byte from SPI
		DEY				; decrement wait counter
		BNE	WAIT_RESP0
		DEX
		BEQ	WAIT_RESP_END		; wait counter is 0 -> time out
WAIT_RESP0	CMP	TEMP			; did we read the token we are waiting for?
		BNE	WAIT_RESP		; no, read next byte
WAIT_RESP_END	RTS

; ******************************************************************************
; Read Single Data Block to Std. Block Buffer
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Source Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; ******************************************************************************

SD_RD_BLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
		BEQ	SD_RD_BLK

; ******************************************************************************
; Read Single Data Block from Logical Address to Std. Block Buffer
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Source Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; ******************************************************************************

SD_RD_LBLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
						; fall through to sd_rd_lblk

; ******************************************************************************
; Read Single Data Block from Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Source Address
;	  BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; ******************************************************************************

SD_RD_LBLK	JSR	LOAD_LBA		; convert LBA CMD ADR
						; fall through to sd_rd_blk

; ******************************************************************************
; Read Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Source Address
;         BLKBUF,BLKBUFH = 16 Bit Destination Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; ******************************************************************************

SD_RD_BLK	LDA	#CMD17			; send CMD17 (blk read)
		JSR	SD_SEND_BLK_CMD
		JSR	SD_WAIT_TOKEN		; wait for data token $FE
		CMP	#$FE			; is card ready for block read?
		CLC
		BNE	SD_RD_END		; did not receive data token, exit with C = 0
		LDX	#$01			; initialize page counter
		LDY	#$00			; initialize byte counter
SD_RD_BLK0	STY	YSAV			; read a byte
		LDY 	#SR
		LDA	(IOBASE),Y
		LDY	YSAV
		STA	(BLKBUF),Y		; and store it into the block buffer
		INY				; increment destination pointer
		BNE	SD_RD_BLK0		; pointer overflow? No, read next byte
		INC	BLKBUFH			; yes, increment block buffer page
		DEX
		BPL	SD_RD_BLK0		; two pages read? no, read next byte
SD_RD_BLK1	JSR	SPI_READ		; yes, read 3 more bytes (CRC H, CRC L, dummy)
		INY
		CPY	#$03			; all 3 bytes read?
		BNE	SD_RD_BLK1		; no, read next byte
		SEC				; yes, all data read, set C = 1
SD_RD_END	RTS

; ******************************************************************************
; Write Single Data Block from Std. Block Buffer
; Input:  SD_PB3..SD_PB0 = 32 Bit Command Block Destination Address
; Output: C = 0 Error, C = 1 Read OK
;	  A = Error Code
; ******************************************************************************

SD_WR_BLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
		BEQ	SD_WR_BLK

; ******************************************************************************
; Write Single Data Block from Std. Block Buffer to Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Destination Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; ******************************************************************************

SD_WR_LBLK_BUF	JSR	INIT_BLKBUF		; set pointer to block buffer
						; fall through to sd_rd_lblk

; ******************************************************************************
; Write Single Data Block to Logical Address
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Destination Address
;	  BLKBUF,BLKBUFH = 16 Bit Source Address
; Output: C = 0 Error, C = 1 Data OK
;	  A = Error Code
; ******************************************************************************

SD_WR_LBLK	JSR	LOAD_LBA		; convert LBA CMD ADR
						; fall through to sd_rd_blk

; ******************************************************************************
; Write Single Data Block
; Input:  SD_PB3..SD_PB0 = 32 Bit CommandBlock Destination Address
;	  BLKBUF,BLKBUFH = 16 Bit Source Address
; Output: C = 0 Error, C = 1 Write OK
;	  A = Error Code
; ******************************************************************************

SD_WR_BLK	LDA	#CMD24			; send CMD24 (blk write)
		JSR	SD_SEND_BLK_CMD
		JSR	SPI_WRITE		; write data token
		LDX	#1			; initialize page counter
		STX	YSAV
		DEX				; initialize byte counter
SD_WR_BLK0	TXA
		TAY
		LDA	(BLKBUF),Y		; read next byte from buffer
		LDY	#PORTA			; and write it to the card
		STA	(IOBASE),Y		; output data to shift register
		DEY				; set for PORTB
		LDA	#$42 			; SPI_CS = L; LOAD_DATA = 0
		STA	(IOBASE),Y		; load data into shift register
		LDA	#$4A 			; SPI_CS = L; LOAD_DATA = 1
		STA	(IOBASE),Y		; data is now in shift register
		LDY 	#SR
		LDA	(IOBASE),Y		; and start clk'ing
		INX				; increment source pointer
		BNE	SD_WR_BLK0		; pointer overflow? No, write next byte
		INC	BLKBUFH			; yes, increment block buffer page
		DEC	YSAV
		BPL	SD_WR_BLK0		; two pages written? no, write next byte
		JSR	SPI_READ		; yes, send a (dummy) CRC ($FFFF)
		JSR	SPI_READ
		JSR	SPI_READ		; read one dummy byte
		JSR	SPI_READ		; read response byte
                PHA                             ; and save it onto the stack
SD_WR_BUSY?	JSR	SPI_READ		; read next byte
		CMP	#0
		BEQ	SD_WR_BUSY?		; check if busy ($00)
		PLA
		AND	#$1F			; mask result bits
		CMP	#$05			; data accepted?
		CLC
		BNE	SD_WR_END		; no, exit with C = 0
		SEC				; yes, exit with C = 1
SD_WR_END	RTS

; ******************************************************************************
; Send Block Read or Write Command
; Input :  A = Command (CMD17,CMD24)
; Output : A = Data Token
; ******************************************************************************

SD_SEND_BLK_CMD	JSR	SD_SEND_CMD
		BNE	SD_RESP_ERR		; response <> 0 check error type
		LDA	#DATA_TOKEN
		RTS

; ******************************************************************************
; Check Error
; ******************************************************************************

SD_RESP_ERR	AND	#$01			; is card in idle mode?
		BEQ	SD_DISK_RW		; no, print error
		JSR	SPI_SLOW		; set SPI slow mode
		JSR	SD_INIT			; yes, maybe card changed, reset
		BCS	SD_DISK_CHNG
SD_NO_DISK	LDA	#$80
		RTS
SD_DISK_RW	LDA	#$81
		CLC
		RTS
SD_DISK_CHNG	LDA	#$82
		CLC
		RTS

; ******************************************************************************
; Reset SD-Card
; ******************************************************************************

SD_RESET	JSR	SD_CLEAR_CMD		; clear command parameters
		LDA	#$95
		STA	SD_CRC			; and set crc to $95 for CMD0
		JSR	SD_PREPARE		; send dummy sequence to SD-Card
		BNE	RESET_SDC		; is MISO line high?
		LDA	#CMD0			; no, send CMD0 (reset) to SD-Card
		JSR	SD_SEND_CMD
		JSR	SD_PREPARE		; send init dummy sequence again
		BEQ	END_SD_RESET		; MISO still low? Exit with A = $FF
RESET_SDC	LDA	#CMD0			; send CMD0 (reset) to SD-Card
		JMP	SD_SEND_CMD		; response should be $01

END_SD_RESET	LDA	#$FF			; reset failed
		RTS

; **** Prepare SD-Card for Communication ***************************************
;
; ******************************************************************************

SD_PREPARE	JSR	SPI_SLOW		; set SPI slow mode
		LDY	#PORTB			; initialize VIA Port B
		LDA	#$4E			; set /SPI_CS = H and /SPI_LOAD = H
		STA	(IOBASE),Y
		LDX	#10			; first send 80 clocks to SD-Card
SEND_CLOCK	JSR	SPI_READ		; send 8 clock cycles
		DEX
		BNE	SEND_CLOCK		; send more clock cycles
		TAX
		LDY	#IFR
SD_PREPARE1	LDA	#$04
		AND	(IOBASE),Y
		BEQ	SD_PREPARE1
		LDY	#PORTB
		LDA	#$4A			; set /SPI_CS = L and /SPI_LOAD = H
		STA	(IOBASE),Y
		TXA				; set proper status flags
SD_END		RTS

; **** SD-Card Boot Routine ****************************************************
;
; ******************************************************************************

SD_BOOT         JSR	SD_CLEAR_CMD
		JSR	SD_RD_BLK_BUF           ; read MBR
                BCC     SD_END                  ; error reading MBR. Exit
                JSR     SYS_MBR_ID              ; check boot block ID tag
                BCC     SD_END                  ; error, wrong ID. Exit
                LDA     PART0-2                 ; check if partition ID1 is $65
                CMP     #$65
                BNE     LOAD_PART0              ; no, just load partition 0
                LDA     PART0-1                 ; check if partition ID2 is $02
                CMP     #$02
                BNE     LOAD_PART0              ; no, just load partition 0
                JSR     MBR                     ; partition ID $65 $02 found. Call MBR code
                BNE     LOAD_PART1              ; is boot menu result 1,2,3, or 4 ?
                CLC                             ; no, ESC pressed or no valid partition found
                RTS                             ; abort booting from SD-Card

LOAD_PART1      DEX                             ; set result to 0,1,2 or 3
                TXA                             ; transfer result to Accu
                TAY                             ; and to Y-Register
                ASL     A                       ; multiply result by 16
                ASL     A
                ASL     A
                ASL     A
                ORA     #$08                    ; and add 8
                TAX                             ; move partition table index into X
                TYA
                CLC
                ADC     #49                     ; convert partition number to ASCII char (+1)
                STA     PSAV                    ; and store it to PSAV
                BNE     LOAD_PART               ; branch always
LOAD_PART0      LDX     #$08                    ; for partition 0 the table index is 8
                LDA     #'1'                    ; partition 0 number as ASCII char (+1)
                STA     PSAV                    ; store it in PSAV
                LDA     PART0                   ; read boot indicator
                BEQ     SYS_MSG_ERR             ; if $00 then exit
LOAD_PART       LDY     #$08
SD_BOOT1        LDA     PART0_RS,X              ; load partition start and length
                STA     BOOT_PART,Y             ; and save it to boot device descriptor
                DEX
                DEY
                BPL     SD_BOOT1
                LDX	#LOW  BOOT_PART         ; read partition boot blk ptr
		LDY	#HIGH BOOT_PART
		JSR     SYS_LD_BOOTBLK          ; load partition boot block
                BCC     SD_END                  ; block not found. Exit
                JSR     SYS_CHECK_OS            ; check OS OEM string
                BCC     SD_END                  ; wrong OEM string. Exit
                LDY     #SDCDEV-STRINGP2        ; load pointer to device name
                JSR     SYS_MSG                 ; print device name to screen
                LDA     #'_'
                JSR     COUT
                LDA     PSAV                    ; add partition number to name (_1.._4)
                JSR     COUT
                SEC                             ; normal boot, set carry flag
                RTS

; ******************************************************************************
; Initialize Block Buffer Pointer
; ******************************************************************************

INIT_BLKBUF	LDA	#HIGH BLOCK_BUF         ; set pointer to standard block buffer
		STA	BLKBUFH
		LDA	#$00
		STA	BLKBUF
		RTS

; ******************************************************************************
; Load Logical Block Address into Command Address.
; Swap Endian and Shift Bits if Desired
; Input:  X,Y = Ptr[LO:HI] to 32 Bit LBA Address
; Output: ADR in SD_PB3..SD_PB0
; ******************************************************************************

LOAD_LBA	STX	PLBAL
		STY	PLBAH
		LDX	#$04
		LDY	#$00
		LDA	SD_TYPE
		BNE	BLK_MODE
		CLC
		TYA
                STA	SD_CMD,X
		DEX
BIT_MODE	LDA	(PLBA),Y
		ROL	A
                STA	SD_CMD,X
		INY
		DEX
		BNE	BIT_MODE
		RTS
BLK_MODE	LDA	(PLBA),Y
		STA	SD_CMD,X
		INY
		DEX
		BNE	BLK_MODE
		RTS

; ******************************************************************************
; Boot Routines
; ******************************************************************************

; **** Main Boot Routine *******************************************************
;
; Find first bootable device
; Output : C = 0 No Boot Device Found
;          C = 1 Boot Device Found. Boot Code at $0600 Available
;
; ******************************************************************************

SYS_BOOT        LDY     #STORAGE_DEV            ; boot from storage device only
SYS_BOOT1       STY     YREG
                TYA
                JSR     DEV_OPEN                ; open device descriptor
                BCC     SYS_BOOT2               ; device not found, try next one
                LDA     #CMD_INIT
                JSR     CMDDEV                  ; initialize device
                BCC     SYS_BOOT2               ; could not initialize, try next one
                LDA     #CMD_BOOT
                JSR     CMDDEV                  ; can we boot from device?
                BCS     SYS_BOOT_END            ; yes, exit
SYS_BOOT2       LDY     YREG                    ; no, try next device
                INY
                CPY     #$2F                    ; all devices checked?
                BNE     SYS_BOOT1               ; no, try next one
                LDY     #NOBOOTDEV-STRINGP2     ; yes, no boot device found

; ***** Show System Message ****************************************************
;
; Input:  Y - Index To Message String
; Output: C = 0
;
; ******************************************************************************

SYS_MSG         JSR     LOADSTRING2
                JSR  	WRSTR                   ; show error message
SYS_MSG_ERR     CLC
SYS_MSG_END     RTS

; ***** Finalize Boot Procedure ************************************************

SYS_BOOT_END    LDA     #$B0                    ; boot block could be loaded
                STA     $0600                   ; modify jump opcode in boot block into BCS
                RTS

; ***** Load Boot Block From Device ********************************************
;
; Input:  X - Pointer to Boot Block Low Address
;         Y - Pointer to Boot Block High Address
; Output: C = 0 No Boot Block Found
;         C = 1 Boot Block Loaded at $0600
;
; ******************************************************************************

SYS_LD_BOOTBLK  LDA     #CMD_READ_BUF
                JSR     CMDDEV                   ; load master boot block
                BCC     SYS_TAG_ERR

; ***** Check Boot Block ID Tag ($55 $AA) **************************************
;
; Output: C = 0 No Boot Block Tag Found
;         C = 1 Boot Block Tag Found
;
; ******************************************************************************

SYS_MBR_ID      LDA     BOOTBLK_TAG             ; check boot block ID tag
                CMP     #$55
                BNE     SYS_TAG_ERR
                LDA     BOOTBLK_TAG+1
                CMP     #$AA
                BNE     SYS_TAG_ERR
                SEC
                RTS
SYS_TAG_ERR     CLC
                RTS

; ***** Check OS OEM String ****************************************************
;
; Output: C = 0 OS OEM String Not Found
;         C = 1 OS OEM String Found
;
; ******************************************************************************

SYS_CHECK_OS    LDX     #04                     ; check four characters of OEM string
SYS_ID_LOOP     LDA     OSID-1,X
                CMP     BLOCK_BUF+2,X
                CLC
                BNE     SYS_CHECK_END           ; wrong OEM string
                DEX
                BNE     SYS_ID_LOOP             ; more charactrs to check
                LDY     #BOOTDEV-STRINGP2
SYS_BOOTMSG     JSR     SYS_MSG                 ; write boot message
                SEC
SYS_CHECK_END   RTS

; ******************************************************************************
; Miscellanious Routines
; ******************************************************************************

; **** Read Joystick Port ******************************************************

; Output: A - button state (Bit 0 = Button 1, Bit 1 = Button 2, Bit 2 = Button 3)
;         X - vertical joystick position 0 = Center, -1 ($FF) = Left, 1 = Right
;         Y - horizontal joystick position 0 = Center, -1 ($FF) = Up, 1 = Down

; ******************************************************************************

READ_JOY_PORT   LDA     FGCBASEH
                BEQ     NO_JOY_PORT             ; check if Floppy-/Graphisc-Controller installed
                LDY     #PIA_PORTB
                LDA     (FGCBASE),Y             ; yes, read joystick port
DECODE_JOY_PORT LDX     #$00                    ; preset x position to CENTER
                LDY     #$00                    ; preset y position to CENTER
                STX     TEMP                    ; clear temp value
JP_UP           LSR     A                       ; get /UP flag
                BCS     JP_DOWN                 ; not set, check DOWN position
                LDY     #$FF                    ; set y position to -1 (UP)
                LSR     A                       ; skip DOWN bit
                JMP     JP_LEFT                 ; and test x position
JP_DOWN         LSR     A                       ; get /DOWN flag
                BCS     JP_LEFT                 ; not set, test x position
                LDY     #$01                    ; set y position to 1 (DOWN)
JP_LEFT         LSR     A                       ; get /LEFT flag
                BCS     JP_RIGHT                ; not set, check RIGHT position
                LDX     #$FF                    ; set x position to -1 (UP)
                LSR     A                       ; skip RIGHT bit
                JMP     JP_BUTTON3              ; and test button 3
JP_RIGHT        LSR     A                       ; get /RIGHT flag
                BCS     JP_BUTTON3              ; not set, test button 3
                LDX     #$01                    ; set x position to 1 (RIGHT)
JP_BUTTON3      LSR     A                       ; get /BUTTON3 flag
                BCS     JP_BUTTON1              ; not set, test button 1
                PHA                             ; save joystick port value
                LDA     #$04
                STA     TEMP                    ; set bit 2 of temp button result
                PLA                             ; restore joystick port value
JP_BUTTON1      LSR     A                       ; get /BUTTON1 flag
                BCS     JP_BUTTON2              ; not set, test button 2
                PHA                             ; save joystick port value
                LDA     #$01
                ORA     TEMP
                STA     TEMP                    ; set bit 0 of temp button result
                PLA                             ; restore joystick port value
JP_BUTTON2      LSR     A                       ; get /BUTTON2 flag
                BCS     END_JOY_PORT            ; not set, exit
                LDA     #$02
                ORA     TEMP
                STA     TEMP                    ; set bit 1 of temp button result
END_JOY_PORT    LDA     TEMP                    ; load temp button result into A
                SEC                             ; data valid
                RTS
NO_JOY_PORT     TAX                             ; no joystick port available, clear X
                TAY                             ; and Y
                CLC                             ; no joystick port available, data invalid
                RTS

; ******************************************************************************
; Device Driver Routines
; ******************************************************************************

; **** Initialize Device Driver List *******************************************
;
; ******************************************************************************

DEV_INIT	LDY	#$3E                    ; clear entire list
                LDA     #$00                    ; and fill it with zeros
DEV_INIT1       STA     DEVLIST,Y
                DEY
		BPL	DEV_INIT1
END_DEV_INIT	RTS

; **** Add Device Driver *******************************************************
;
; Input  - X : Driver Descriptor Address Low Byte
;          Y : Driver Descriptor Address High Byte
; Output - C = 1 Success, C = 0 Error
;          A = Device ID (0F = Too Many Devices, FF = Unknown Device Type)
;
; ******************************************************************************

DEV_ADD		STX	PDEVL
		STY	PDEVH
		LDY	#$00
		LDA	(PDEV),Y                ; load device ID into A
		STA     TEMP
                JSR     DEV_CHECK
                BCC     END_DEV_ADD
                LSR     A
                AND     #$0F
                CMP     #$0F
                BNE     ADD_DEV
FIND_FREE_DEV   TYA
                AND     #$E0
                TAY
                LDX     #$00
FIND_NEXT_DEV   LDA     DEVLIST-$20,Y
                BEQ     ADD_DEV1
                INY
                INY
                INX
                CPX     #$0F
                BCC     FIND_NEXT_DEV
                CLC
                RTS
ADD_DEV         TAX
ADD_DEV1        LDA     PDEVL
                STA     DEVLIST-$20,Y
                LDA     PDEVH
                STA     DEVLIST-$1F,Y
                LDA     TEMP
                AND     #$F0
                STX     TEMP
                ORA     TEMP
                SEC
END_DEV_ADD     RTS

DEV_ERR         LDX     #$FF
                CLC
               	RTS

DEV_CHECK       CMP     #STORAGE_DEV+$10
		BCS     DEV_ERR
		CMP     #COM_DEV
                BCC     DEV_ERR
                ASL     A
                TAY
                SEC
                RTS

; **** Open Device Driver ******************************************************
;
; Input  - A : Device ID
; Output - C = 1 Success, C = 0 Error
;          X : Descriptor Address Low Byte
;          Y : Descriptor Address High Byte
;
; ******************************************************************************

DEV_OPEN        JSR     DEV_CHECK
                BCC     END_DEV_OPEN
                LDA     DEVLIST-$20,Y
                BNE     DEV_OPEN1
                LDA	#LOW NULL_DEV   ; no device found use NULL device
DEV_OPEN1       STA     PDEVL
                LDA     DEVLIST-$1F,Y
                BNE     DEV_OPEN2
                LDA	#HIGH NULL_DEV  ; no device found use NULL device
DEV_OPEN2       STA     PDEVH
		LDY	#$02
		LDX	#$00
DEV_OPEN3	LDA	(PDEV),Y
		STA	DEVIN,X
		INY
		INX
		CPX	#$06
		BNE	DEV_OPEN3
		LDX	PDEVL
		LDY	PDEVH
		SEC
END_DEV_OPEN    RTS

; ******************************************************************************
; Standard Driver Command Routines
; ******************************************************************************

; ******************************************************************************
; XModem Command Interpreter
; ******************************************************************************

XMODEM_CMD	CMP	#CMD_LOAD
		BNE	XM_SAVE
		JMP	XModemRcv
XM_SAVE  	CMP	#CMD_SAVE
		BNE     COM_CMD
		JMP	XModemSnd

; ******************************************************************************
; Tape Device Command Interpreter
; ******************************************************************************

TAPE_CMD	CMP	#CMD_LOAD
		BNE	TP_SAVE
		JMP	TAPELOAD
TP_SAVE 	CMP	#CMD_SAVE
		BNE     COM_CMD
		JMP	TAPESAVE

; ******************************************************************************
; XSD_Card Command Interpreter
; ******************************************************************************

SDC_CMD         CMP     #CMD_INIT
                BNE     SDC_READ
                JMP     SD_INIT
SDC_READ        CMP     #CMD_READ
                BNE     SDC_WRITE
                JMP     SD_RD_LBLK
SDC_WRITE       CMP     #CMD_WRITE
                BNE     SDC_RD_BUF
                JMP     SD_WR_LBLK
SDC_RD_BUF      CMP     #CMD_READ_BUF
                BNE     SDC_WR_BUF
                JMP     SD_RD_LBLK_BUF
SDC_WR_BUF      CMP     #CMD_WRITE_BUF
                BNE     SDC_SETADR
                JMP     SD_WR_LBLK_BUF
SDC_SETADR      CMP     #CMD_SETSTARTADR
                BNE     SDC_BOOT
                STX     BLKBUFL
                STY     BLKBUFH
                SEC
                RTS
SDC_BOOT        CMP     #CMD_BOOT
                BNE     _EMPTY_
                JMP     SD_BOOT

; ******************************************************************************
; Common Command Interpreter
; ******************************************************************************

COM_CMD	        CMP	#CMD_SETSTARTADR
		BNE     COM_SETENDADR
		STX	ADRL
		STY	ADRH
		SEC
		RTS
COM_SETENDADR	CMP	#CMD_SETENDADR
                BNE     _EMPTY_
		STX	NUML
		STY	NUMH
		SEC
		RTS

; EMPTY Command Handler ********************************************************

_EMPTY_         CLC
_HANDLER_       RTS

; Command Handler For Floppy Drive 2 *******************************************

FGC_FDC_CMD2    ORA     #$80            ; set bit 7 of command byte (drive 2 operation)
                JMP     FGC_FDC_CMD     ; call command handler


; **** Floppy IRQ Routine ******************************************************

; ******************************************************************************
                ORG     $F948

MOTOR_IRQ       PHA
                LDA     FDC_OPT_REG     ; load option register
                AND     $04             ; watch dog interrupt pending?
                BEQ     VPU_IRQ         ; no, check VPU IRQ
                LDA     FDC_MOTOR1_REG  ; yes, clear interrupts
                LDA     FDC_MOTOR2_REG  ; by reading the motor registers

                LDA     #$0C
                STA     FDC_OPT_REG     ; all motors off
                LDA     #$00
                STA     FDC_MOTOR       ; save current motor status
                PLA
                RTI

; **** VPU IRQ Routine *********************************************************

; ******************************************************************************

VPU_IRQ         LDA     #VPU_STAT0
                STA     VPU_PORT1
                LDA     #VPU_REG15
                STA     VPU_PORT1
                LDA     VPU_PORT1       ; is it a line interrupt?
                BPL     NO_VPU_IRQ      ; no, exit
                LDA     TICKCNT         ; yes, load the tick counter
		BEQ     IRQ_END         ; is it 0?
		DEC     TICKCNT         ; no, decrement tick counter
IRQ_END         PLA
                RTI
NO_VPU_IRQ	PLA			; restore accumulator
		JMP	IRQ		; call user interrupt routine

; ******************************************************************************
; Standard Driver Descriptors
; ******************************************************************************

                ORG     $FA00-16*8

NULL_DEV	DB	NULL_ID, $00     ; Null Device Driver Descriptor
		DW	_EMPTY_
		DW	_EMPTY_
		DW	_EMPTY_

TTY_DEV		DB	TTY1_ID, $00     ; Terminal Driver Descriptor
		DW	SERIALIN
		DW	SERIALOUT
		DW	TTY_CMD

PPRINT_DEV	DB	PRINTER1_ID, $00 ; Parallel Printer Driver Descriptor
		DW	_EMPTY_
		DW	PPORTOUT
		DW	_EMPTY_

KEYBD_DEV       DB	KEYBD1_ID, $00   ; ASCII Keyboard Driver Descriptor
		DW	ASCIIKBD
		DW	_EMPTY_
		DW	_EMPTY_

VDP_DEV         DB	VDP1_ID, $00     ; Video Display Processor Driver Descriptor
		DW      PS2KBD
                DW      FGC_VPU_OUT
		DW      FGC_VPU_CMD

XMODEM_DEV	DB	XMODEM1_ID, $00  ; XModem Device Driver Descriptor
		DW	SERIALIN
		DW	SERIALOUT
		DW	XMODEM_CMD

TAPE_DEV	DB	TAPE1_ID, $00    ; Tape Device Driver Descriptor
		DW	_EMPTY_
		DW	_EMPTY_
		DW	TAPE_CMD

SDC_DEV	        DB	SDC1_ID, $00     ; SD-Card Driver Descriptor
		DW	_EMPTY_
		DW	_EMPTY_
		DW      SDC_CMD

FDD1_DEV	DB	FDD1_ID, $00     ; Floppy Disk Drive 1 Driver Descriptor
		DW	_EMPTY_
		DW	_EMPTY_
		DW      FGC_FDC_CMD

FDD2_DEV	DB	FDD2_ID, $00     ; Floppy Disk Drive 2 Driver Descriptor
		DW	_EMPTY_
		DW	_EMPTY_
		DW      FGC_FDC_CMD2

; ******************************************************************************
; Low Byte CRC Lookup Table (XMODEM)
; ******************************************************************************

                ORG 	$FA00
CRCLO
 		DB 	$00,$21,$42,$63,$84,$A5,$C6,$E7,$08,$29,$4A,$6B,$8C,$AD,$CE,$EF
 		DB 	$31,$10,$73,$52,$B5,$94,$F7,$D6,$39,$18,$7B,$5A,$BD,$9C,$FF,$DE
 		DB 	$62,$43,$20,$01,$E6,$C7,$A4,$85,$6A,$4B,$28,$09,$EE,$CF,$AC,$8D
 		DB 	$53,$72,$11,$30,$D7,$F6,$95,$B4,$5B,$7A,$19,$38,$DF,$FE,$9D,$BC
 		DB 	$C4,$E5,$86,$A7,$40,$61,$02,$23,$CC,$ED,$8E,$AF,$48,$69,$0A,$2B
 		DB 	$F5,$D4,$B7,$96,$71,$50,$33,$12,$FD,$DC,$BF,$9E,$79,$58,$3B,$1A
 		DB 	$A6,$87,$E4,$C5,$22,$03,$60,$41,$AE,$8F,$EC,$CD,$2A,$0B,$68,$49
 		DB 	$97,$B6,$D5,$F4,$13,$32,$51,$70,$9F,$BE,$DD,$FC,$1B,$3A,$59,$78
 		DB 	$88,$A9,$CA,$EB,$0C,$2D,$4E,$6F,$80,$A1,$C2,$E3,$04,$25,$46,$67
 		DB 	$B9,$98,$FB,$DA,$3D,$1C,$7F,$5E,$B1,$90,$F3,$D2,$35,$14,$77,$56
 		DB 	$EA,$CB,$A8,$89,$6E,$4F,$2C,$0D,$E2,$C3,$A0,$81,$66,$47,$24,$05
 		DB 	$DB,$FA,$99,$B8,$5F,$7E,$1D,$3C,$D3,$F2,$91,$B0,$57,$76,$15,$34
 		DB 	$4C,$6D,$0E,$2F,$C8,$E9,$8A,$AB,$44,$65,$06,$27,$C0,$E1,$82,$A3
 		DB 	$7D,$5C,$3F,$1E,$F9,$D8,$BB,$9A,$75,$54,$37,$16,$F1,$D0,$B3,$92
 		DB 	$2E,$0F,$6C,$4D,$AA,$8B,$E8,$C9,$26,$07,$64,$45,$A2,$83,$E0,$C1
 		DB 	$1F,$3E,$5D,$7C,$9B,$BA,$D9,$F8,$17,$36,$55,$74,$93,$B2,$D1,$F0

; ******************************************************************************
; Hi Byte CRC Lookup Table (XMODEM)
; ******************************************************************************

                ORG 	$FB00
CRCHI
 		DB 	$00,$10,$20,$30,$40,$50,$60,$70,$81,$91,$A1,$B1,$C1,$D1,$E1,$F1
 		DB 	$12,$02,$32,$22,$52,$42,$72,$62,$93,$83,$B3,$A3,$D3,$C3,$F3,$E3
 		DB 	$24,$34,$04,$14,$64,$74,$44,$54,$A5,$B5,$85,$95,$E5,$F5,$C5,$D5
 		DB 	$36,$26,$16,$06,$76,$66,$56,$46,$B7,$A7,$97,$87,$F7,$E7,$D7,$C7
 		DB 	$48,$58,$68,$78,$08,$18,$28,$38,$C9,$D9,$E9,$F9,$89,$99,$A9,$B9
 		DB 	$5A,$4A,$7A,$6A,$1A,$0A,$3A,$2A,$DB,$CB,$FB,$EB,$9B,$8B,$BB,$AB
 		DB 	$6C,$7C,$4C,$5C,$2C,$3C,$0C,$1C,$ED,$FD,$CD,$DD,$AD,$BD,$8D,$9D
 		DB 	$7E,$6E,$5E,$4E,$3E,$2E,$1E,$0E,$FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
 		DB 	$91,$81,$B1,$A1,$D1,$C1,$F1,$E1,$10,$00,$30,$20,$50,$40,$70,$60
 		DB 	$83,$93,$A3,$B3,$C3,$D3,$E3,$F3,$02,$12,$22,$32,$42,$52,$62,$72
 		DB 	$B5,$A5,$95,$85,$F5,$E5,$D5,$C5,$34,$24,$14,$04,$74,$64,$54,$44
 		DB 	$A7,$B7,$87,$97,$E7,$F7,$C7,$D7,$26,$36,$06,$16,$66,$76,$46,$56
 		DB 	$D9,$C9,$F9,$E9,$99,$89,$B9,$A9,$58,$48,$78,$68,$18,$08,$38,$28
 		DB 	$CB,$DB,$EB,$FB,$8B,$9B,$AB,$BB,$4A,$5A,$6A,$7A,$0A,$1A,$2A,$3A
 		DB 	$FD,$ED,$DD,$CD,$BD,$AD,$9D,$8D,$7C,$6C,$5C,$4C,$3C,$2C,$1C,$0C
 		DB 	$EF,$FF,$CF,$DF,$AF,$BF,$8F,$9F,$6E,$7E,$4E,$5E,$2E,$3E,$0E,$1E


		END