# Creating the BIOS

The main BIOS was assembled using the [A65](https://www.retrotechnology.com/restore/a65c.html) assembler.
In order to create a fully functional Junior Computer ][ BIOS, you must merge the assembled output of BIOS.asm with the original Monitor program. 
While BIOS.bin occupies the first 7KB of the total 8KB ROM image, MONITOR.bin uses the last 1KB. 
This last 1KB also contains the reset and interrupt vectors of the 6502 CPU. Therefore this step is absolutly necessary for a working JC2 BIOS.

However, you can use the already pre build BIOS images. "BIOS - 8K.BIN" can be uses in a 27C64 EPROM or 28C64 EEPROM, while "BIOS - 32K.BIN" should be used for 27C256 or 28C256 ROMs.

A 32KB ROM can contain an alternative BIOS that can be selected with the ROM_BANK_SEL jumper (J4) on the JC2 mainboard. This alternative BIOS must reside from absolute ROM address $2000 to $3FFF
while the main BIOS is located between $6000 and $7FFF.
