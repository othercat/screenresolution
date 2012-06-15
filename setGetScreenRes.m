
#define NEWFOR10_6 
#define JohnFordWORK

#ifdef NEWFOR10_6 //another boy build for 10.6

#ifdef JohnFordWORK

#define VERSION "1.0"
// vim: ts=4:sw=4
/*
 * screenresolution sets the screen resolution on Mac computers.
 * Copyright (C) 2011  John Ford <john@johnford.info>
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

#else
#define OUT_OF_BOUND 255

/* 
 * screenresolution.m 
 *  
 * Description: 
 *    It set/get current Online display resolutions. 
 * 
 * Author: 
 *    Tony Liu, Copy Right Tony Liu 2011,  All rights reserved. 
 * 
 * Version History: 
 *    2011-06-01: add -a option. 
 *    2011-06-08: Display adding flags and not display duplicate modes. 
 *    2011-06-09: Adding set the best fit resolution function. 
 * 
 * COMPILE: 
 *    c++ screenresolution.m -framework ApplicationServices -o screenresolution -arch i386 
 * 
 */  
#include <ApplicationServices/ApplicationServices.h>  
struct sLIST {  
	double width, height;  
	CGDisplayModeRef mode;  
};  
typedef int (*compfn)(const void*, const void*);  
void ListDisplays(uint32_t displayTotal);  
void ListDisplayAllMode (CGDirectDisplayID displayID, int index);  
void PrintUsage(const char *argv[]);  
void PrintModeParms (double width, double height, double depth, double freq, int flag);  
int GetModeParms (CGDisplayModeRef mode, double *width, double *height, double *depth, double *freq, int *flag);  
int GetDisplayParms(CGDirectDisplayID disp, double *width, double *height, double *depth, double *freq, int *flag);  
int GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight);  
int modecompare(struct sLIST *elem1, struct sLIST *elem2);  
uint32_t maxDisplays = 20;  
CGDirectDisplayID onlineDisplayIDs[20];  
uint32_t displayTotal;  
char *sysFlags[]={"Unknown","Interlaced,", "Multi-Display,", "Not preset,", "Stretched,"};  
char flagString[200];  

int main (int argc, const char * argv[])  
{  
	double width = 0, height = 0, depth, freq;  
	int flag = -1;  
	int displayNum = OUT_OF_BOUND;  
	//CGDirectDisplayID theDisplay;  
	
	// 1. Getting system info.  
	if (CGGetOnlineDisplayList (maxDisplays, onlineDisplayIDs, &displayTotal) != kCGErrorSuccess) {  
		printf("Error on getting online display List.");  
		return -1;  
	}  
	
	if (argc == 1) {  
		CGRect screenFrame = CGDisplayBounds(kCGDirectMainDisplay);  
		CGSize screenSize  = screenFrame.size;  
		printf("%.0f %.0f\n", screenSize.width, screenSize.height);  
		return 0;  
	}  
	
	if (! strcmp(argv[1],"-l")) {  
		if (argc == 2) {  
			ListDisplays(displayTotal);  
			return 0;  
		}  
		else if (argc == 3)  {  
			displayNum = atoi(argv[2]);  
			if (displayNum <= displayTotal && displayNum > 0) {  
				ListDisplayAllMode (onlineDisplayIDs[displayNum-1], 0);  
			}  
		}  
		return 0;  
	}  
	
	if (! strcmp(argv[1],"-a")) {  
		printf("Total online displays: %d\n", displayTotal);  
		return 0;  
	}  
	
	if ((! strcmp(argv[1],"-?")) || (! strcmp(argv[1],"-h"))) {  
		PrintUsage(argv);  
		return 0;  
	}  
	if (! strcmp(argv[1],"-s")) {  
		if (argc == 4) {  
			displayNum = 1; width = atoi(argv[2]); height = atoi(argv[3]);  
		}  
		else if (argc == 5) {  
			displayNum = atoi(argv[2]); width = atoi(argv[3]); height = atoi(argv[4]);  
		}  
		if (displayNum <= displayTotal)  
			flag = GetBestDisplayMod(displayNum-1, width, height);  
		if (flag < 0) {
			fprintf(stderr, "ERROR: flag num error : %d.\n", flag);  
			return -1;  
		}
		return flag;  
	}  
	displayNum = atoi(argv[1]);  
	if (displayNum <= displayTotal) {  
		GetDisplayParms(onlineDisplayIDs[displayNum-1], &width, &height, &depth, &freq, &flag);  
		PrintModeParms (width, height, depth, freq, flag);  
		return 0;  
	}  
	else {  
		fprintf(stderr, "ERROR: display number out of bounds; displays on this mac: %d.\n", displayTotal);  
		return -1;  
	}  
	return 0;  
}  

void ListDisplays(uint32_t displayTotal)  
{  
	uint32_t i;  
	//CGDisplayModeRef mode;  
	double width, height, depth, freq;  
	int flag;  
	
	// CGDirectDisplayID mainDisplay = CGMainDisplayID();  
	printf("Total Online Displays: %d\n", displayTotal);  
	for (i = 0 ; i < displayTotal ;  i++ ) {  
		printf ("  Display %d (id %d): ", i+1, onlineDisplayIDs[i]);  
		GetDisplayParms(onlineDisplayIDs[i], &width, &height, &depth, &freq, &flag);  
		if ( i == 0 )    printf(" (main) ");  
		PrintModeParms (width, height, depth, freq, flag);  
	}  
}  
void ListDisplayAllMode (CGDirectDisplayID displayID, int iNum)  
{  
	CFArrayRef modeList;  
	CGDisplayModeRef mode;  
	CFIndex index, count;  
	double width, height, depth, freq;  
	int flag;  
	//double width1, height1, depth1, freq1;  
	//int flag1;  
	
	modeList = CGDisplayCopyAllDisplayModes (displayID, NULL);  
	if (modeList == NULL)   return;  
	count = CFArrayGetCount (modeList);  
	//width1=0; height1=0; depth1=0; freq1=0; flag1=0;  
	if (iNum <= 0) {  
		for (index = 0; index < count; index++)  
		{  
			mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, index);  
			GetModeParms(mode, &width, &height, &depth, &freq, &flag);  
			PrintModeParms (width, height, depth, freq, flag);  
		}  
	}  
	else if (iNum <= count) {  
		mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, iNum-1);  
		GetModeParms(mode, &width, &height, &depth, &freq, &flag);  
		PrintModeParms (width, height, depth, freq, flag);  
	}  
	CFRelease(modeList);  
}  
void PrintModeParms (double width, double height, double depth, double freq, int flag)  
{  
	printf ("%ld x %ld x %ld @ %ld Hz, <%d>\n", (long int)width, (long int)height, (long int)depth, (long int)freq, flag);  
}  
int GetDisplayParms(CGDirectDisplayID disp, double *width, double *height, double *depth, double *freq, int *flag)  
{  
	int iReturn=0;  
	CGDisplayModeRef Mode = CGDisplayCopyDisplayMode(disp);  
	iReturn = GetModeParms (Mode, width, height, depth, freq, flag);  
	CGDisplayModeRelease (Mode);  
	return iReturn;  
}  
int GetModeParms (CGDisplayModeRef Mode, double *width, double *height, double *depth, double *freq, int *sflag)  
{  
	*width = CGDisplayModeGetWidth (Mode);  
	*height = CGDisplayModeGetHeight (Mode);  
	*freq = CGDisplayModeGetRefreshRate (Mode);  
	CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding (Mode);  
	*depth = 0;  
	if (pixelEncoding == NULL) return -1;  
	if (pixelEncoding == CFSTR(IO32BitDirectPixels))  
		*depth = 32;  
	else if (pixelEncoding == CFSTR(IO16BitDirectPixels))  
		*depth = 16;  
	else    *depth = 8;  
	
	*sflag = CGDisplayModeGetIOFlags(Mode);  
	CFRelease(pixelEncoding);  
	return 0;  
}

int GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight)  
{  
	CFArrayRef modeList;  
	CGDisplayModeRef mode;  
	CFIndex index, count, scount=0; // sindex, 
	double width, height, depth, freq;  
	double width1, height1, depth1, freq1;  
	int flag, flag1;  
	struct sLIST mList[100];  
	int ireturn=0;  
	
	modeList = CGDisplayCopyAllDisplayModes (display, NULL);  
	if (modeList == NULL)   return -1;  
	count = CFArrayGetCount (modeList);  
	scount=0;  
	for (index = 0; index < count; index++)  
	{  
		mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, index);  
		GetModeParms(mode, &width, &height, &depth, &freq, &flag);  
		// printf("........ scount=%d\n", (int)scount);  
		if (!((width==width1) && (height==height1) && (depth==depth1) && (freq==freq1) && (flag==flag1))) {  
			if (CGDisplayModeIsUsableForDesktopGUI(mode)) {  
				mList[scount].mode=mode; mList[scount].width=width; mList[scount].height=height;  
				width1=width; height1=height; depth1=depth; freq1=freq; flag1=flag;  
				scount++;  
			}  
		}  
	}  
	mode=NULL;  
	qsort ((void *) mList, scount, sizeof(struct sLIST), (compfn) modecompare);  
	for (index=0; index<scount; index++)  
	{  
		if (mList[index].width >= dwidth) {  
			if (mList[index].height >= dheight) {  
				mode = mList[index].mode;  
				break;  
			}  
		}  
	}  
	
	CGDisplayConfigRef pConfigRef;  
	CGConfigureOption option=kCGConfigurePermanently;  
	if ((mode != NULL) && (CGBeginDisplayConfiguration(&pConfigRef) == kCGErrorSuccess)) {  
		CGConfigureDisplayWithDisplayMode(pConfigRef, display, mode, NULL);  
		if (CGCompleteDisplayConfiguration (pConfigRef, option) !=kCGErrorSuccess) CGCancelDisplayConfiguration (pConfigRef);     
	}  
	else ireturn = -1;  
	CFRelease(modeList);  
	return ireturn;  
}  
int modecompare(struct sLIST *elem1, struct sLIST *elem2)  
{  
	if ( elem1->width < elem2->width)  
		return -1;  
	else if (elem1->width > elem2->width) return 1;  
	if (elem1->height < elem2->height) return -1;  
	else if (elem1->height > elem2->height) return 1;  
	else return 0;  
}  
void PrintUsage(const char *argv[])  
{  
	char *fname = strrchr(argv[0], '/')+1;  
	printf("Screen Resolution v1.0, Mac OS X 10.6 or later, i386\n");  
	printf("Copyright 2010 Tony Liu. All rights reserved. June 1, 2010\n");  
	printf("\nUsage:");  
	printf("       %s -a\n", fname);  
	printf("       %s [-l] [1..9]\n", fname);  
	printf("       %s -s [ 1..9 ] hor_res vert_res\n", fname);  
	printf("       %s -? | -h        this help.\n\n", fname);  
	printf("      -l  list resolution, depth and refresh rate\n");  
	printf("    1..9  display # (default: main display)\n");  
	printf("  -l 1-9  List all support for the display #\n");  
	printf("      -s  Set mode.\n");  
	printf(" hor_res  horizontal resolution\n");  
	printf("vert_res  vertical resolution\n\n");  
	printf("Examples:\n");  
	printf("%s -a             get online display number\n", fname);  
	printf("%s                get current main diplay resolution\n", fname);  
	printf("%s 3              get current resolution of third display\n", fname);  
	printf("%s -l             get resolution, bit depth and refresh rate of all displays\n", fname);  
	printf("%s -l 1           get first display all supported mode\n", fname);  
	printf("%s -l 1 2         get first display the second supported mode\n", fname);  
	printf("%s -s 800 600     set resolution of main display to 800x600\n", fname);  
	printf("%s -s 2 800 600   set resolution of secondary display to 800x600\n", fname);  
}   
#endif

#else

#if 0 //open it to list all mode

#include <ApplicationServices/ApplicationServices.h>

#define MAX_DISPLAYS 32

CGDirectDisplayID displays[MAX_DISPLAYS];
uint32_t numDisplays;
uint32_t i;

bool MyBestMode (CGDisplayModeRef mode);
void MyDrawToDisplayWithMode (CGDirectDisplayID display, CGDisplayModeRef mode);

int main (int argc, const char * argv[])
{
	
	CGGetActiveDisplayList (MAX_DISPLAYS, displays, &numDisplays); // 1

	for (i = 0; i < numDisplays; i++) // 2
	{
    CGDisplayModeRef mode;
    CFIndex index, count;
    CFArrayRef modeList;
	
    modeList = CGDisplayCopyAllDisplayModes (displays[i], NULL); // 3
    count = CFArrayGetCount (modeList);
	
    for (index = 0; index < count; index++) // 4
    {
        mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, index);
        if (MyBestMode (mode)) {
            MyDrawToDisplayWithMode (displays[i], mode); // 5
            break;
        }
    }
    CFRelease(modeList);// 6
	}
}

bool MyBestMode (CGDisplayModeRef mode) // 7
{
    long height = 0, width = 0;
    CFStringRef pixelEncoding;
	
    height=CGDisplayModeGetHeight(mode);
    width=CGDisplayModeGetWidth(mode);
    pixelEncoding=CGDisplayModeCopyPixelEncoding(mode);
	
	//get the path as a UTF-8 C string.
	//this is harder than Cocoa programmers expect. ;)
	void (*freeFunc)(void *) = NULL;
	char *pathUTF8 = CFStringGetCStringPtr(pixelEncoding, kCFStringEncodingUTF8);
	if(!pathUTF8) {
		pathUTF8 = alloca(255);
		if(pathUTF8)
			CFStringGetCString(pixelEncoding, pathUTF8, 255, kCFStringEncodingUTF8);
		else {
			pathUTF8 = malloc(255);
			if(!pathUTF8) {
				DLog(CFSTR("Could not test the existence of %@: could not allocate %lu bytes for path (errno is %s)"), pixelEncoding, (unsigned long)255, strerror(errno));
				return false;
			} else {
				freeFunc = free;
				CFStringGetCString(pixelEncoding, pathUTF8, 255, kCFStringEncodingUTF8);
			}
		}
	}
	
	DLog(@"%d %d %@",width,height,pixelEncoding);
	CFRelease(pixelEncoding);
	return false;
	
    if (height == 768 && width == 1024 && CFStringCompare(pixelEncoding,CFSTR(IO32BitDirectPixels),0)==kCFCompareEqualTo)
    {
        CFRelease(pixelEncoding);
        return true;
    }
    else
    {
        CFRelease(pixelEncoding);
        return false;
    }
}

void MyDrawToDisplayWithMode (CGDirectDisplayID display, CGDisplayModeRef mode)
{
    CGDisplayModeRef originalMode = CGDisplayCopyDisplayMode (display); // 8
    CGDisplayHideCursor (display);
    CGDisplaySetDisplayMode (display, mode, NULL); // 9
    CGDisplayCapture (display); // 10
	
    /* full screen drawing/game loop here */
	
    //CGDisplaySetDisplayMode (display, originalMode, NULL); // 11
    CGDisplayModeRelease(originalMode);
    CGDisplayRelease (display); // 12
    //CGDisplayShowCursor (display);
}

#else

/*
 * setgetscreenres.m
 * 
 * juanfc 2009-04-13
 * jawsoftware 2009-04-17
 * Based on newscreen
 *    Created by Jeffrey Osterman on 10/30/07.
 *    Copyright 2007 Jeffrey Osterman. All rights reserved. 
 *    PROVIDED AS IS AND WITH NO WARRANTIES WHATSOEVER
 *    http://forums.macosxhints.com/showthread.php?t=59575
 *
 * COMPILE:
 *    c++ setgetscreenres.m -framework ApplicationServices -o setgetscreenres
 * USE:
 *    setgetscreenres [ -l | 1..9] [ 1440 900 ]
 */

#include <ApplicationServices/ApplicationServices.h>

//#define	DEBUG_RES

bool MyDisplaySwitchToMode (CGDirectDisplayID display, CFDictionaryRef mode);
void ListDisplays( CGDisplayCount dispCount, CGDirectDisplayID *dispArray );
void usage(const char *argv[]);
void GetDisplayParms(CGDirectDisplayID *dispArray,  CGDisplayCount dispNum, int *width, int *height, int *depth, int *freq);

int main (int argc, const char * argv[])
{
	int	h; 							// horizontal resolution
	int v; 							// vertical resolution
	int depth, freq;
	
	CFDictionaryRef switchMode; 	// mode to switch to
	CGDirectDisplayID theDisplay;  // ID of  display, display to set
	int displayNum; //display number requested by user
	
	CGDisplayCount maxDisplays = 10;
	CGDirectDisplayID onlineDspys[maxDisplays];
	CGDisplayCount dspyCnt;
	
	CGGetOnlineDisplayList (maxDisplays, onlineDspys, &dspyCnt);

	if (argc == 1) {
#ifndef DEBUG_RES
	    CGRect screenFrame = CGDisplayBounds(kCGDirectMainDisplay);
		CGSize screenSize  = screenFrame.size;
		printf("%.0f %.0f\n", screenSize.width, screenSize.height);
#else
		theDisplay = CGMainDisplayID();
		h = 1024;
		v = 768;
		switchMode = CGDisplayBestModeForParameters(theDisplay, 32, h, v, NULL);
		
		if (! MyDisplaySwitchToMode(theDisplay, switchMode)) {
			fprintf(stderr, "Error changing resolution to %d %d\n", h, v);
			DLog(@"Error changing resolution to %d %d\n", h, v);
			return 1;
		}
#endif
		return 0;
	}
	
	if (argc == 2) {
		if (! strcmp(argv[1],"-l")) {
			ListDisplays( dspyCnt, onlineDspys );
			return 0;
		}
		else if (! strcmp(argv[1],"-?")) {
			usage(argv);
			return 0;
		}
		else if (displayNum = atoi(argv[1])) {
			if (displayNum <= dspyCnt) {
				GetDisplayParms(onlineDspys, displayNum-1, &h, &v, &depth, &freq);
				printf("%d %d\n", h, v);
				DLog(@"%d %d\n", h, v);
				return 0;
			}
			else {
				fprintf(stderr, "ERROR: display number out of bounds; displays on this mac: %d.\n", dspyCnt);
				DLog(@"ERROR: display number out of bounds; displays on this mac: %d.\n", dspyCnt);
				return -1;
			}
		}
	}
	
	
	if (argc == 4 && (displayNum = atoi(argv[1])) && (h = atoi(argv[2])) && (v = atoi(argv[3])) ) {
		if (displayNum <= dspyCnt) {
			theDisplay= onlineDspys[displayNum-1];
		}
		else return -1;
	}
	else {
		if (argc != 3 || !(h = atoi(argv[1])) || !(v = atoi(argv[2])) ) {
			fprintf(stderr, "ERROR: syntax error.\n", argv[0]);
			DLog(@"ERROR: syntax error.\n", argv[0]);
			usage(argv);
			return -1;
		}
		theDisplay = CGMainDisplayID();
	}
	
	
	switchMode = CGDisplayBestModeForParameters(theDisplay, 32, h, v, NULL);
	
	if (! MyDisplaySwitchToMode(theDisplay, switchMode)) {
	    fprintf(stderr, "Error changing resolution to %d %d\n", h, v);
		DLog(@"Error changing resolution to %d %d\n", h, v);
		return 1;
	}
	
	return 0;
}


void ListDisplays( CGDisplayCount dispCount, CGDirectDisplayID *dispArray )
{
	int	h, v, depth, freq, i;
	CGDirectDisplayID mainDisplay = CGMainDisplayID();
	
	printf("Displays found: %d\n", dispCount);
	for	(i = 0 ; i < dispCount ;  i++ ) {
		
		GetDisplayParms(dispArray, i, &h, &v, &depth, &freq);
		printf("Display %d (id %d):  %d x %d x %d @ %dHz", i+1, dispArray[i], h, v, depth, freq);
		DLog(@"Display %d (id %d):  %d x %d x %d @ %dHz", i+1, dispArray[i], h, v, depth, freq);
		if ( mainDisplay == dispArray[i] ) 
		{
			printf(" (main)\n");
			DLog(@" (main)\n");
		}
		else
		{
			printf("\n");
			DLog(@"\n");
		}
	}
}


void GetDisplayParms(CGDirectDisplayID *dispArray,  CGDisplayCount dispNum, int *width, int *height, int *depth, int *freq)
{
	CFDictionaryRef currentMode = CGDisplayCurrentMode (dispArray[dispNum]);
	CFNumberRef number = CFDictionaryGetValue (currentMode, kCGDisplayRefreshRate);
	CFNumberGetValue (number, kCFNumberLongType, freq);
	number = CFDictionaryGetValue (currentMode, kCGDisplayWidth);
	CFNumberGetValue (number, kCFNumberLongType, width);
	number = CFDictionaryGetValue (currentMode, kCGDisplayHeight);
	CFNumberGetValue (number, kCFNumberLongType, height);
	number = CFDictionaryGetValue (currentMode, kCGDisplayBitsPerPixel);
	CFNumberGetValue (number, kCFNumberLongType, depth);
}

bool MyDisplaySwitchToMode (CGDirectDisplayID display, CFDictionaryRef mode)
{
	CGDisplayConfigRef config;
	if (CGBeginDisplayConfiguration(&config) == kCGErrorSuccess) {
		CGConfigureDisplayMode(config, display, mode);
		CGCompleteDisplayConfiguration(config, kCGConfigureForSession );
		return true;
	}
	return false;
}


void usage(const char *argv[])
{
	printf("\nUsage: %s [-l | 1..9 ] [ hor_res vert_res]\n\n", argv[0]);
	printf("      -l  list resolution, depth and refresh rate of all displays\n");
	printf("    1..9  display # (default: main display)\n");
	printf(" hor_res  horizontal resolution\n");
	printf("vert_res  vertical resolution\n\n");
	printf("Examples:\n");
	printf("%s 800 600      set resolution of main display to 800x600\n", argv[0]);
	printf("%s 2 800 600    set resolution of secondary display to 800x600\n", argv[0]);
	printf("%s 3            get resolution of third display\n", argv[0]);
	printf("%s -l           get resolution, bit depth and refresh rate of all displays\n\n", argv[0]);
}

#endif
#endif