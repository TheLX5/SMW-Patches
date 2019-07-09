Fade-in Pack
============

These two patches replace the game's default mosaic fade-in with either a circle that zooms into or out from the player, or a "horizontally convex" shape which zooms into or out from the center of the screen. A "horizontally convex" shape is a shape such that every horizontal line intersects the shape's boundaries no more than two times. For example, a circle, Mario's head, and any other normally convex shape is horizontally convex; a star is not horizontally convex, and neither are munchers.


Circular Fade-In
================

To change the radii of the circles (which is usually not necessary - the default values work fine), modify !frames to be the number of frames that the fade-in lasts. Then, modify the radii table's values; a lower index into the table corresponds to an earlier part of the fade-in, and a later part of the fade-out.

Shaped Fade-In
==============

To change the shape of the window, change the values under "windowing:" in the patch. Since manually specifying the values is extremely annoying, a program which will generate the values is included, courtesy of Vitor Vilela. Insert a 256x224 image, and it will output the windowing values which can then be used as the windowing values.

To change the scales of the window (which is usually not necessary - the default values work fine), change the values under "scales:". The values under "inv_scales:" should be as close as possible to the number such that multiplying by the corresponding value in "scales:" yields #$010000.