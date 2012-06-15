
#define VERSION "1.0"
// vim: ts=4:sw=4
/*
 * screenresolution sets the screen resolution on Mac computers.
 * Copyright (C) 2011  John Ford <john@johnford.info>
 * Modified by Li Richard at 2012-06-15
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

#import <ApplicationServices/ApplicationServices.h>

// Number of modes to list per line.
#define MODES_PER_LINE 3

// I have written an alternate list routine that spits out WAY more info
// #define LIST_DEBUG 1

struct config {
    size_t w; // width
    size_t h; // height
    size_t d; // colour depth
    double r; // refresh rate
};

unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode);
unsigned int configureDisplay(CGDirectDisplayID display,
                              struct config *config,
                              int displayNum);
unsigned int listCurrentMode(CGDirectDisplayID display, int displayNum);
unsigned int listAvailableModes(CGDirectDisplayID display, int displayNum);
unsigned int parseStringConfig(const char *string, struct config *out);
size_t bitDepth(CGDisplayModeRef mode);

// http://stackoverflow.com/questions/3060121/core-foundation-equivalent-for-NSLog/3062319#3062319
//void NSLog(CFStringRef format, ...);


int main(int argc, const char *argv[]) {
    // http://developer.apple.com/library/IOs/#documentation/CoreFoundation/Conceptual/CFStrings/Articles/MutableStrings.html
    unsigned int exitcode = 0;
    CFMutableStringRef args = CFStringCreateMutable(NULL, 0);
    CFStringEncoding encoding = CFStringGetSystemEncoding();
    CFStringAppend(args, CFSTR("    starting screenresolution argv="));
    if (argc > 1) {
        for (int i = 1 ; i < argc ; i++) {
            CFStringAppendCString(args, argv[i], encoding);
            // If I were so motivated, I'd probably use CFStringAppendFormat
            CFStringAppend(args, CFSTR(" "));
        }
    }
    else
        CFStringAppendCString(args, "null", encoding);

    DLog(@"%@", args);
    CFRelease(args);
    
    if (argc > 1) {
        //int keepgoing = 1;
        CGError rc;
        uint32_t displayCount = 0;
        uint32_t activeDisplayCount = 0;
        CGDirectDisplayID *activeDisplays = NULL;
        
        rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
        if (rc != kCGErrorSuccess) {
            DLog(@"    Error: failed to get list of active displays");
            return 1;
        }
        // Allocate storage for the next CGGetActiveDisplayList call
        activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
        if (activeDisplays == NULL) {
            DLog(@"    Error: could not allocate memory for display list");
            return 1;
        }
        rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
        if (rc != kCGErrorSuccess) {
            DLog(@"    Error: failed to get list of active displays");
            return 1;
        }
        
        // This loop should probably be in another function.
        for (int i = 0; i < displayCount; i++) {
            if (strcmp(argv[1], "get") == 0) {
                if (!listCurrentMode(activeDisplays[i], i)) {
                    exitcode++;
                }
            } else if (strcmp(argv[1], "list") == 0) {
                if (!listAvailableModes(activeDisplays[i], i)) {
                    exitcode++;
                }
            } else if (strcmp(argv[1], "set") == 0) {
                if (i < (argc - 2)) {
                    if (strcmp(argv[i+2], "skip") == 0 && i < (argc - 2)) {
                        DLog(@"    Skipping display %d", i);
                    } else {
                        struct config newConfig;
                        if (parseStringConfig(argv[i + 2], &newConfig)) {
                            if (!configureDisplay(activeDisplays[i], &newConfig, i)) {
                                exitcode++;
                            }
                        } else {
                            exitcode++;
                        }
                    }
                }
            } else if (strcmp(argv[1], "--help") == 0) {
                // Send help information to stdout since it was requested
                DLog(@"    screenresolution sets the screen resolution on Mac computers.\n");
                DLog(@"    screenresolution version %s Licensed under GPLv2", VERSION);
                DLog(@"    Copyright (C) 2011  John Ford <john@johnford.info> Modified by Li Richard at 2012\n");
                DLog(@"    usage: screenresolution [get]    - Show the resolution of all active displays");
                DLog(@"           screenresolution [list]   - Show available resolutions of all active displays");
                DLog(@"           screenresolution [skip] [display1resolution] [display2resolution]");
                DLog(@"                                     - Sets display resolution and refresh rate");
                DLog(@"           screenresolution --version - Displays version information for screenresolution"); 
                DLog(@"           screenresolution --help    - Displays this help information\n"); 
                DLog(@"    examples: screenresolution 800x600x32            - Sets main display to 800x600x32");
                DLog(@"              screenresolution 800x600x32 800x600x32 - Sets both displays to 800x600x32");
                DLog(@"              screenresolution skip 800x600x32       - Sets second display to 800x600x32\n");
            } else if (strcmp(argv[1], "--version") == 0) {
                DLog(@"    screenresolution version %s\nLicensed under GPLv2", VERSION);
                //keepgoing = 0;
                break;
            } else {
                DLog(@"    I'm sorry %s. I'm afraid I can't do that", getlogin());
                // Send help information to stderr
                DLog(@"    Error: unable to copy current display mode\n");
                DLog(@"    screenresolution version %s -- Licensed under GPLv2\n\n", VERSION);
                DLog(@"    usage: screenresolution [get]  - Show the resolution of all active displays");
                DLog(@"           screenresolution [list] - Show available resolutions of all active displays");
                DLog(@"           screenresolution [skip] [display1resolution] [display2resolution]");
                DLog(@"                                     - Sets display resolution and refresh rate");
                DLog(@"           screenresolution --version - Displays version information for screenresolution");
                DLog(@"           screenresolution --help    - Displays this help information\n");
                DLog(@"    examples: screenresolution 800x600x32            - Sets main display to 800x600x32");
                DLog(@"              screenresolution 800x600x32 800x600x32 - Sets both displays to 800x600x32");
                DLog(@"              screenresolution skip 800x600x32       - Sets second display to 800x600x32\n");
                exitcode++;
                //keepgoing = 0;
                break;
            }
        }
        free(activeDisplays);
        activeDisplays = NULL;
    } else {
            CGRect screenFrame = CGDisplayBounds(kCGDirectMainDisplay);  
            CGSize screenSize  = screenFrame.size;  
            printf("%.0f %.0f\n", screenSize.width, screenSize.height);    
    }
    return exitcode > 0;
}

size_t bitDepth(CGDisplayModeRef mode) {
    size_t depth = 0;
	CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding(mode);
    // my numerical representation for kIO16BitFloatPixels and kIO32bitFloatPixels
    // are made up and possibly non-sensical
    if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO32BitFloatPixels), kCFCompareCaseInsensitive)) {
        depth = 96;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO64BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 64;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO16BitFloatPixels), kCFCompareCaseInsensitive)) {
        depth = 48;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 32;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO30BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 30;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive)) {
        depth = 16;
    } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive)) {
        depth = 8;
    }
    CFRelease(pixelEncoding);
    return depth;
}

unsigned int configureDisplay(CGDirectDisplayID display, struct config *config, int displayNum) {
    unsigned int returncode = 1;
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
    if (allModes == NULL) {
        DLog(@"    Error: failed trying to look up modes for display %u", displayNum);
        return 0; 
    }
    
    CGDisplayModeRef newMode = NULL;
    CGDisplayModeRef possibleMode;
    size_t pw; // possible width.
    size_t ph; // possible height.
    size_t pd; // possible depth.
    double pr; // possible refresh rate
    int looking = 1; // used to decide whether to continue looking for modes.
    int i;
    for (i = 0 ; i < CFArrayGetCount(allModes) && looking; i++) {
        possibleMode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
        pw = CGDisplayModeGetWidth(possibleMode);
        ph = CGDisplayModeGetHeight(possibleMode);
        pd = bitDepth(possibleMode);
        pr = CGDisplayModeGetRefreshRate(possibleMode);
        if (pw == config->w &&
            ph == config->h &&
            pd == config->d &&
            pr == config->r) {
            looking = 0; // Stop looking for more modes!
            newMode = possibleMode;
        }
    }
    CFRelease(allModes);
    if (newMode != NULL) {
        DLog(@"    set mode on display %u to %lux%lux%lu@%.0f", displayNum, pw, ph, pd, pr);
        setDisplayToMode(display,newMode);
    } else {
        DLog(@"    Error: mode %lux%lux%lu@%f not available on display %u", 
              config->w, config->h, config->d, config->r, displayNum);
        returncode = 0;
    }
    return returncode;
}

unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode) {
    CGError rc;
    CGDisplayConfigRef config;
    rc = CGBeginDisplayConfiguration(&config);
    if (rc != kCGErrorSuccess) {
        DLog(@"    Error: failed CGBeginDisplayConfiguration err(%u)", rc);
        return 0;
    }
    rc = CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
    if (rc != kCGErrorSuccess) {
        DLog(@"    Error: failed CGConfigureDisplayWithDisplayMode err(%u)", rc);
        return 0;
    }
    rc = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (rc != kCGErrorSuccess) {
        DLog(@"    Error: failed CGCompleteDisplayConfiguration err(%u)", rc);        
        return 0;
    }
    return 1;
}

unsigned int listCurrentMode(CGDirectDisplayID display, int displayNum) {
    unsigned int returncode = 1;
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(display);
    if (currentMode == NULL) {
        DLog(@"    Error: unable to copy current display mode");
        return 0;
    }
    DLog(@"    Display %d: %lux%lux%lu@%.0f",
          displayNum,
          CGDisplayModeGetWidth(currentMode),
          CGDisplayModeGetHeight(currentMode),
          bitDepth(currentMode),
          CGDisplayModeGetRefreshRate(currentMode));
    CGDisplayModeRelease(currentMode);
    return returncode;
}

unsigned int listAvailableModes(CGDirectDisplayID display, int displayNum) {
    unsigned int returncode = 1;
    int i;
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
    if (allModes == NULL) {
        DLog(@"    Error: unable to copy all display mode");
        return  0;
    }
#ifndef LIST_DEBUG
    DLog(@"    Available Modes on Display %d", displayNum);
    
#endif
    CGDisplayModeRef mode;
    for (i = 0; i < CFArrayGetCount(allModes) && returncode; i++) {
        mode = (CGDisplayModeRef) CFArrayGetValueAtIndex(allModes, i);
        // This formatting is functional but it ought to be done less poorly.
#ifndef LIST_DEBUG
        if (i % MODES_PER_LINE == 0) {
            printf("  ");
        } else {
            printf("\t");
        }
        char modestr [50];
        sprintf(modestr, "%lux%lux%lu@%.0f",
                CGDisplayModeGetWidth(mode),
                CGDisplayModeGetHeight(mode),
                bitDepth(mode),
                CGDisplayModeGetRefreshRate(mode));
        printf("%-20s ", modestr);
        if (i % MODES_PER_LINE == MODES_PER_LINE - 1) {
            printf("\n");
        }
#else
        uint32_t ioflags = CGDisplayModeGetIOFlags(mode);
        printf("    display: %d %4lux%4lux%2lu@%.0f usable:%u ioflags:%4x valid:%u safe:%u default:%u",
               displayNum,
               CGDisplayModeGetWidth(mode),
               CGDisplayModeGetHeight(mode),
               bitDepth(mode),
               CGDisplayModeGetRefreshRate(mode),
               CGDisplayModeIsUsableForDesktopGUI(mode),
               ioflags,
               ioflags & kDisplayModeValidFlag ?1:0,
               ioflags & kDisplayModeSafeFlag ?1:0,
               ioflags & kDisplayModeDefaultFlag ?1:0 );
        printf("    safety:%u alwaysshow:%u nevershow:%u notresize:%u requirepan:%u int:%u simul:%u",
               ioflags & kDisplayModeSafetyFlags ?1:0,
               ioflags & kDisplayModeAlwaysShowFlag ?1:0,
               ioflags & kDisplayModeNeverShowFlag ?1:0,
               ioflags & kDisplayModeNotResizeFlag ?1:0,
               ioflags & kDisplayModeRequiresPanFlag ?1:0,
               ioflags & kDisplayModeInterlacedFlag ?1:0,
               ioflags & kDisplayModeSimulscanFlag ?1:0 );
        printf("    builtin:%u notpreset:%u stretched:%u notgfxqual:%u valagnstdisp:%u tv:%u vldmirror:%u\n",
               ioflags & kDisplayModeBuiltInFlag ?1:0,
               ioflags & kDisplayModeNotPresetFlag ?1:0,
               ioflags & kDisplayModeStretchedFlag ?1:0,
               ioflags & kDisplayModeNotGraphicsQualityFlag ?1:0,
               ioflags & kDisplayModeValidateAgainstDisplay ?1:0,
               ioflags & kDisplayModeTelevisionFlag ?1:0,
               ioflags & kDisplayModeValidForMirroringFlag ?1:0 );
#endif
    }
    CFRelease(allModes);
    return returncode;
}

unsigned int parseStringConfig(const char *string, struct config *out) {
    unsigned int rc;
    size_t w;
    size_t h;
    size_t d;
    double r;
    int numConverted = sscanf(string, "%lux%lux%lu@%lf", &w, &h, &d, &r);
    if (numConverted != 4) {
        rc = 0;
        DLog(@"    Error: the mode '%s' couldn't be parsed", string);
    } else {
        out->w = w;
        out->h = h;
        out->d = d;
        out->r = r;
        rc = 1;
    }
    return rc;
}
