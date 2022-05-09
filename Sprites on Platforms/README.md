This is an attempt to fix the original patch's issues listed by Maarfy here: https://smwc.me/1505665

It also adds custom sprite support and uses DSS natively. You could remove the DSS dependency yourself, I'm too lazy.

## Disclaimer
This patch worked exclusively on my baserom, I do not guarantee its insertion capabilities in a ROM, let alone working fine at all since I removed some experimental code regarding conveyors and I didn't even attempt to try to see if the game worked at all after removing these lines of code. As a result, I will not provide any support regarding this patch conversion since it was done years ago and I've forgotten how it worked at all.

## Fixed issues
- Brown rotating chain platform no longer drops sprites when it's marked as offscreen.
- The Skull Raft stopped processing sprites if Mario went too far from them.
- Baby Yoshi's bouncing is not disabled when on a platform as was done for adult Yoshi, causing it to fall through or off of many platforms with ease.
- Similarly to the above, Baby Yoshi will bounce off of a platform when offscreen, losing contact and disabling proper offscreen handling.
- A flying ?-Block that flies back and forth will produce its (non-coin) sprite item one full block to the right, but only if the ?-Block was flying to the right when activated.
- The Invisible Solid Block sprite as well as message boxes seem to have odd collision that can really push the player/thrown sprites around by a block length +, and can push the player through a wall.
- Mario rapidly oscillates between standing and falling state when on top of a Boo Block, forfeiting proper control every other frame as such.
- The springboard explicitly checks for Urchins to avoid giving them speed; the wall springboards do not, and will push Urchins away at warp speed.
- Mega Moles can serve as platforms, but they don't respond well to having items placed upon them. The bouncing motion as a sprite lands even from a gentle drop can cause them to turn around as if blocked, drop the item, or even get pushed through a wall with little effort.
- A glitched, static berry sprite created by Yoshi can trigger a springboard's bounce animation, but only once.
- There is one truly bizarre glitch involving the grey hammer bro platform, wherein throwing a sprite at the platform generates blocks at the point of contact. It can be recreated rather reliably in level 006 by throwing a Goomba at the bottom of the hammer bro platform past the translucent box after the midway point. More bizarrely, if no bounce sprites are generated before this point, a turnblock is produced, but if the translucent box is bumped, translucent boxes are produced instead. ON/OFF blocks and noteblocks have been spawned as well in this manner. I was utterly unable to figure out what initiates this behavior - it does not appear to be connected to the platform's sprite slot, the level screen, the platform's position, the sprite hitting the platform or whether the platform is ridden by a hammer bro. Platforms earlier in the level do not exhibit this behavior, but once a platform is reached that does, others acquire the ability as well. Refer to the .gif below for a demonstration:
- The P-switch sprite registers as a solid platform with its normal hitbox when in the "pressed" state.
- Yoshi falls through the grey hammer bro platform on its upswing; Yoshi falls off of rotating grey platforms on their upswing.
- Here's an odd one - placing a Key on a Skull Raft and jumping in place on the Key will cause the Key to fall through the raft, but only when turbo mode is active in the emulator (only tested on Snes9x 1.59.2, turbo = 2 mostly worked, = 3 always worked).
- Hitboxes are on the wonky side for some platform sprites. Notable is the left wall spring board, which can bounce sprites a full block away from its right end.
- Sprites resting on the Grey Platform (Sinks in Lava) sprite will slowly shift rightwards when the platform is made to sink.
- Sprites that are falling quickly can pass through platforms (especially the grey hammer bro platform) and trigger light switch/message boxes from above.
    - Partially fixed. The patch increases leniency if the sprite goes too fast (+1 per $10 units of movement in either direction on the Y-Axis). I'm not going to bother further fixing this.
- Line-guided Grinders can be bounced off of their lines with a springboard, but only once; other line guided enemies weren't tested but will presumably react accordingly. (This would actually be really cool to make into an every-time kind of event.)
- Dolphins can serve as platforms for sprites, but generally move too quickly to carry anything reliably.
    - Partially fixed. Dolphins, mainly horizontal ones, can drop items when going underwater.
- Thrown springboards can interact with Monty Moles before they have emerged from the ground/wall; in the case of wall variants, the spring can nudge them upwards slightly, causing their mole-hole to burst out of the wrong tile.
- At sublabel .SkipTurn2, I believe JMP .SkipTurn at line 1062 can be optimized to JMP .DontCheck.
- In the code under [;sides, check which side of the platform's center the sprite's center is at], line 985 - I believe ADC $0E should be ADC $0F.
- The code under the BrownFix label contains an improperly SA-1 converted sprite table (STZ $1602|!addr,x instead of STZ !1602,x). It ends up not mattering, though, as the RTL leads to an RTS, which I believe itself leads to another copy of STZ !1602,x at $01CA0E.

## Ignored issues
- Attempting to drop an item on a platform rising even modestly often drops the item right through.
    - I have no clue how am I supposed to fix this *shrug*
- The Mushroom Scale Platform sprites drop carried items when offscreen.
    - Can't replicate.
- The grey hammer bro platform can be "bumped" if it flies down on top of an immobile sprite (key, P-switch, etc.).
    - Issue too small to bother.
- Diagonal moving platforms have no sprite interaction (intended?).
    - It's not viable to add interaction with the current infrastructure the patch offers.
- Turn Block Bridges can create phantom clipping areas or cause sprites to warp around when thrown or stacked, especially when two bridges are present and especially when one or more of said bridges are processing offscreen.
    - Not able to replicate the issue. Perhaps it was related to Erik's version?
- If one of the platforms within a triple grey rotating platform sprite is made to hold an item, putting the platform offscreen and returning may variably fail to respawn the other two platforms, or respawn three new platforms plus an additional platform carrying the deposited sprite.
    - Rotating Platforms will always fail to carry a sprite placed above them, it's better to recommend not place sprites on top of them in LM. They will fail to carry a sprite if they're not on the same column.
- The offscreen clipping fix specifically checks for special clipping on the part of Turn Block Bridges, but not any of the other sprites that are made to use BeSolidToSpritesSpecialClip - brown rotating platforms, Keys, P-switches and Skull Rafts. There is no support for custom platform sprites that utilize custom clipping.
    - Possibly related to Erik's fix, which I'm not using to make my changes (also can't reproduce)
- The brown rotating chain platform no longer has sprite interaction (deliberately removed?).
    - This was from Erik's version. No need to fix something that wasn't there.
- The Skull Raft will drop carried items when just under one-and-a-half skulls have moved offscreen in either direction.
    - This was from Erik's version. No need to fix something that wasn't there.
- With !SolidInMovement = $01, dropping a Key/P-switch on top of Yoshi pushes him through the ground.
    - That's a weird option to give. Not gonna bother with that one.
- If a grey hammer bro platform flies down over top of Yoshi within two blocks of the ground on which Yoshi stands, Yoshi will be pushed through the ground.
    - Adding a warning regarding this behavior seems like a better approach to this situation.
- Not a bug introduced by this patch, just made easier to bump into - if Yoshi is bounced into the ceiling, he will clip through and rise up and away.
    - Not a bug introduced by this patch ;)
- If the leftmost pixel of the left wall springboard goes offscreen (which is to say, virtually all of the sprite is still visible), the spring noise is deactivated. The same more or less occurs with the right wall springboard, but the rightmost 16 pixels must be offscreen instead.
    - idc about this, but made it play sounds regardless of the offscreen status
- If the leftmost pixel of the carryable springboard goes offscreen, the spring noise is deactivated. Sound deactivation works correctly when offscreen to the right.
    - idc about this
- A fire-breathing Bowser Statue carrying an item will continue to audibly breath fire when offscreen.
    - idc about this
- Eating a springboard with Yoshi while it is compressed from bouncing another sprite will allow Yoshi to spit the springboard out still in its compressed state. Touching the spring in this state seems to revert it without issue.
    - idc about this
