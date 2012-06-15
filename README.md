# screenresolution

This is a tool that can be used to determine current resolution,
list available resolutions and set resolutions for active displays
on Mac OS 10.6, and possibly above.

## requirement

Mac OS X 10.6 and above version (10.8 not tested)

## Build+Install

Just fetch the code via git clone github.com:othercat/screenresolution
Then compile it with Xcode 4.

## Running

There are three commands that this program supports: get, list 
and set.  All three modes operate on active displays [1].

The get mode will show you the resolution of all active displays

    $ screenresolution get
    Display 0: 1920x1200x32
    Display 1: 1920x1200x32
 
 The list mode will show you to the available resolutions of all
 active displays, seperated by various whitespace.

    Available Modes on Display 0
      1920x1200x8   1920x1200x16    1920x1200x32    960x600x8 
      960x600x16    960x600x32      1680x1050x8 	1680x1050x16 
    <snip>
    Available Modes on Display 1
    <snip>

The set command takes a list of modes.  It will apply the modes
in the list of modes to the list of displays, starting with 0.
Modes in excess of the number of active displays will be ignored.
If you wish to set a monitor but not the lower numbered displays,
there is a keyword 'skip' which can be subsituted for a resolution.
This keyword will cause the first display to be skipped.  If you
specify more resolutions than you have active screens, the extra
resolutions will be ignored.

Example 1:
    This example works with one or more screens
    $ screenresolution 800x600x32
Result 1:
    The main display will change to 800x600x32, second screen
    will not be changed

Example 2:
    This example assumes two screens
    $ screenresolution 800x600x32 800x600x32
Result 2:
    The first and second monitor on the system will be set to 
    800x600x32

Example 3:
    This example assumes two screens
    $ screen resolution skip 800x600x32
    This will not touch the first screen but will set the second
    screen to 800x600x32

[1]See discussion point for explanation of what active display means.
http://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/Quartz_Services_Ref/Reference/reference.html#//apple_ref/c/func/CGGetActiveDisplayList

## Changelog

New markdown README

Move the command line makefile to Xcode compile environment (Xcode 4.2 tested).

Compile with clang successfully.

default return should be the resolution raw value.
