Mario 8x8 DMA patch thingy

by Ladida

version 3


This patch makes Mario's 8x8 tiles get loaded through DMA, just like his head and body tiles.
This saves space in SP1, but wastes ~1KB in ROM (and whatever NMI time is wasted in
uploading the extra tiles).


basically (if you don't change !Tile):

8x8 tiles $0A-$0B, $1A-$1B, $20-$24, $30-$34, $4A-$4B, $5A-$5B, and $7E-$7F are now free
$0C and $0D are where the new tiles will be DMA'd to
$00-$09 and $10-$19 are still used by Mario/Cape/Yoshi/Podoboo.


Just make sure the patch AND ExtendGFX.bin are in the same directory.

the main patch hijacks the MarioGFXDMA routine, as well as some tables. Make sure you check
that none of these are being edited by other patches (like the 32x32 player tilemap patch. if
you're using that, you don't need this patch)



version 2: some updates and optimizations. the 8x8 tiles still appear 1 frame before the player

version 3: following my recoding of the 32x32 player tilemap patch, ive moved logic out of NMI (this
	also fixes the "1 frame before player" quirk). in addition, the random cape tiles have been
	moved to ROM as well, saving tiles $4A-$4B, $5A-$5B, and $7F (plus some tiles in GFX32)


note that certain Mario frames in Lunar Magic (for the entrance positions) may appear glitched.
this will not affect how Mario appears in-game