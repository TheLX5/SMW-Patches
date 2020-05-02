**********************************
* Instructions                   *
**********************************

0. Make a backup of your ROM before inserting this patch just in case.
- Make sure that at least (any) one of levels has a midway entrance with the option "Use separate settings for Midway Entrance" checked.
  (This will silently install Lunar Magic's level transition ASM to your ROM, which is required by this patch.
   Once it is certainly installed, feel free to uncheck the option in any level.)

1. To insert: asar.exe retry.asm [your_rom].smc
- Don't try to directly insert "retry_table.asm" or "retry_extra.asm". It won't do anything!
- Whenever you want to save the changes in "retry_table.asm" or "retry_extra.asm", reinsert "retry.asm" instead.

2. You can put more than one checkpoints (respawning locations).
- Refer to the comments in "retry_table.asm" and the figures in the "midway instruction" folder.

3. This patch is compatible with AddmusicK or no addmusic. Other addmusics are not guaruanteed to work.

4. Almost everything can be customized in "retry_table.asm": prompt settings, checkpoint settings, lives, counterbreak, etc.
- Edit "letters.bin" with YY-CHR to change the font of the retry prompt. The letters use palette 08.
  letters.bin is automatically inserted when you apply retry.asm to your ROM. (Don't insert it with LM.)

5. If you have a code that should be executed during reset, check "retry_extra.asm".


**********************************
* What's new in ver 2.06?        *
**********************************

1. Compatible with Lunar Magic 3.00 (still supports Lunar Magic 2.5x too)
- Except for the redirect midway feature which can be done by custom midway bars instead (see "midway instruction/custom_bar.png").
  I think it is not worthwhile to make the patch support it because it's not appropriate for multiple checkpoints.

2. Includes the "HDMA off" patch by default which turns off HDMA effects during level transition including reset.

3. Supports the retry and checkpoint feature in the intro level (C5 or 1C5).
   Its prompt type follows the option of level 0 in "local settings (for each translevel)" in "retry_table.asm" (since its translevel is recognized as level 0 in smw in general).
   You can set it to $04 if you prefer what the older versions did.

4. Fixed a rare glitch that the game freezes if the following conditions are met. Thanks to Mellonpizza for reporting this.
- You have exited a room through a pipe.
- The entrance of the next room is set to "Do Nothing - Cannot Bring Item".
- There's an autoscroll command sprite at the beginning of the room.

5. Now (re)inserting this patch is prohibited if there is Lunar Magic's 'Title Moves Recording ASM' in your ROM.
   After finishing working on your titlescreen, remove the recording ASM (there's a menu to do this) and you will be able to reinsert this.

6. Added "retry_extra.asm" where you can put your code to be executed during level reset.

7. (ver 2.06a) More proper initialization including cape status.

8. (ver 2.06a) Compatible with the level ender custom sprite.

9. (ver 2.06b) Compatible with Mario's 8x8 GFX DMAer, 32x32 Player Tilemap and Custom Powerups v3.4.0+.

10. (ver 2.06b) Fixed several bugs regarding the implementation of Individual Dragon Coins Save on SA-1 ROMs.

11. (ver 2.06b) Fixed window garbage that appeared for a frame upon closing the retry prompt.


**********************************
* Compatibility Management       *
**********************************

1. If you are already using ObjecTool, the "custom midway bar" feature will not be automatically inserted.
   You have to manually insert it with ObjecTool if (and only if) you need; replace your "objectool04.asm" with the one in "optional/objectool/" folder.
   Be aware that all slots of object 2D will be occupied by the custom midway bar.

2. For a SA-1 ROM, you will want to apply a patch called "BW-RAM Plus" to save the midway state to SRAM.
   An example configuration is included in "optional/sram plus/bwram_tables.asm".

3. If you need "SRAM Plus" in a non SA-1 ROM for reasons, refer to an example configuration in "optional/bwram plus/sram_table.asm".

* ObjecTool 0.4: https://www.smwcentral.net/?p=section&a=details&id=16040
* SRAM and BW-RAM Plus: https://www.smwcentral.net/?p=section&a=details&id=14762


**********************************
* Trouble Shooting               *
**********************************

1. If the respawning location of a midway seems entirely wrong, shift any midway entrance in any level by dragging, and save the level.
   (Alternatively check "Use separate settings for Midway Entrance" in the main/midway entrance dialog, and save it.)
   This action will install Lunar Magic's level entrance asm to your ROM, which is required for the patch.
   Once it is done, all of your midway entrances (even if "Use separate settings for Midway Entrance" is uncheckd) will work correctly as respawning locations.


2. To make FG gradients code (generated by Effect Tool) compatible with the prompt, open the code and replace

      LDA #$17    ;\  BG1, BG2, BG3, OBJ on main screen (TM)
      STA $212C   ; | 
      LDA #$00    ; | 0 on main screen should use windowing. (TMW)
      STA $212E   ;/  
     ...

   with

      LDA #$17
      STA $212C
      LDA #$17    ; <- difference
      STA $212E
      ...


3. If a custom midway bar is not spawned, check if the number of custom bars in the level exceeds the value of "!max_custom_midway_num" in retry_table.asm.
   You may increase the value if necessary. Note that custom bars buried by other objects/map16 tiles also count.


4. If the left tile of a custom midway bar is not spawned, check if the object is lying over a boundary line of subscreens (press F2 in LM).


5. If the Mario Action of a main/midway entrance is set to "Vertical Pipe Exit Down (Water Level)" (last option), it sometimes works incorrectly.
   When you enter the level from the overworld via this entrance which is not the first respawning point, Mario will act as if "Do Nothing - Cannot Bring Item" were chosen.
   (It is vanilla but I'm not sure where it was exploited in the original game.)
   Due to this, it is recommended to use "Vertical Pipe Exit Down" (5th option) and check "Make this level a water level" instead.


6. If the layer 2 position becomes inconsistent when you enter a level from the overworld, it is likely that its layer 2 H-Scroll is set to None.
   Place a checkpoint considering that the layer 2 x position is always set to zero when you enter that kind of	level from the overworld.
   Also note that the layer 2 x value inherits from the state in the previous room when you move to that room via door/pipe.
   Avoid placing a checkpoint in that level is a good option too.


7. (SRAM Plus only)
   If you apply SRAM Plus for the first time to a ROM where this version of retry is already installed, the load/save functions will not work properly.
   (e.g. "Erase Data" menu in the title screen will crash the game.)
   To fix it, apply the retry patch once again. After doing this, applying patches in any order will be okay.


8. If you make a BGM fade out in your level by the following code (assuming you are using AddmusicK),
	LDA #$FF
	STA $1DFB
   the music won't be reset when you die after it fades out. You'd want to append the code with `STA $0DDA` to make it work properly.
	LDA #$FF
	STA $1DFB
	STA $0DDA


9. TBC

