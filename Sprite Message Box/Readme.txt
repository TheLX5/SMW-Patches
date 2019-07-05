Sprite Message Box v1.0

If you run into graphical glitches or crashing, make sure:
- You've saved the overworld at least once
- You've inserted the included ExGFX file, and properly pointed to it by editing !GFXFileNumber at the top of the patch
- You have gone under Options > Compression options, and selected something other than "Original Game Code". The modified routines store the decompressed size to an address
- If you're using the DMA Remap patch, you change !DMACh and !HDMACh in the patch, as suggested.
- If you're using SpriteTilesReserved, the RAM address is an Empty "Reset on level load" address unused by any other ASM hack.