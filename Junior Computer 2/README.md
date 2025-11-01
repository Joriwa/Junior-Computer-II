# Junior Computer 2

The Junior Computer ][ is essentially an expanded Elektor Junior Computer. It uses the same address decoding as the original, with some extra decoding to reach memory addresses beyond $1FFF.
Due to its incomplete address decoding, the Elektor Junior Computer mapped the first 8KB of the 6502's total 64KB memory space eight times in a row. 
This makes it possible to place the ROM at address range from $1C00 to $1FFF while at the same time reaching the reset and interrupt vectors at the required addresses from $FFFA to $FFFF.

The JC2 extends the address decoders of the Junior in the way to enable the use of the entire 64KB address space, without having to change any absolute addresses in the original Monitor ROM. So using old style programs should cause no problems at all.

With a 628128 RAM the JC2 can directly access 51712 bytes of free memory. The upper 64KB could be used via the 128K_SEL line on the expansion bus with some additional electronics. However, it's not currently used. 

A 6551 UART makes it possible to communitate with the JC2 via a VT100 compatible terminal or a terminal emulation such as TeraTerm, qTerm or PuTTY. The JC2 BIOS attempts to determine the baud rate used by the terminal by sending the “Send-ID” command at various baud rates until it receives a response from the connected terminal. If no response is received, JC2 uses 9600 baud, 8 bits, no parity on the COM port. You can use a little hardware patch to disable the auto baud rate detection, as described in "Hardware Patch.pdf".

The Junior Computer ][ can be expanded with additional hardware via the 64-pin expansion bus, which is pin-compatible with the original bus interface of the Elektor Junior Computer. Therefore, old hardware expansions should also work with the JC2 but there is no guarantee that all old cards will work.

The new monitor program for the JC2 was build uppon Steve Wozniak's Apple 1 monitor program, but has since been replaced by a new implementation. However, the old postfix style of command input has been retained.

To load and save programs and data from the Junior Computer's memory, I use the XModem implementation of Daryl Rictor from 2002. This uses CRC checking of the tramsmitted data.
In order to use CRC checking in TeraTerm, you have to modify the TeraTerm.ini file as described in the TeraTerm README.
