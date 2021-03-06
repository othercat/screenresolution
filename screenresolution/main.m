
#define VERSION "1.9.4"
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
#import <QuartzCore/CVDisplayLink.h>
#import <IOKit/graphics/IOGraphicsLib.h>


// Number of modes to list per line.
#define MODES_PER_LINE 3
#define IS_SILENT YES

#define LCD_MONITOR 1
#define CRT_MONITOR 0

// I have written an alternate list routine that spits out WAY more info
// #define LIST_DEBUG 1

struct config {
    size_t w; // width
    size_t h; // height
    size_t d; // colour depth
    double r; // refresh rate
};

struct sLIST {  
	double width, height;  
	CGDisplayModeRef mode;  
};  
typedef int (*compfn)(const void*, const void*);
int modecompare(struct sLIST *elem1, struct sLIST *elem2);
int GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight);
int GetModeParms (CGDisplayModeRef mode, double *width, double *height, double *depth, double *freq, int *flag);  

typedef unsigned char byte;

unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode);
int configureDisplay(CGDirectDisplayID display, struct config *config, int displayNum) ;
unsigned int listCurrentMode(CGDirectDisplayID display, int displayNum);
unsigned int listAvailableModes(CGDirectDisplayID display, int displayNum);
unsigned int parseStringConfig(const char *string, struct config *out);
double CGDisplayGetRefreshRate(CGDisplayModeRef mode, CGDirectDisplayID displayID, BOOL isSilent);
size_t bitDepth(CGDisplayModeRef mode);
unsigned int isDisplayLCD(CGDirectDisplayID display);


extern int parse_edid( byte* edid,int isSilent);
extern float vfreq;
int isLCD = -1;


// http://stackoverflow.com/questions/3060121/core-foundation-equivalent-for-NSLog/3062319#3062319
//void NSLog(CFStringRef format, ...);


int main(int argc, const char *argv[]) {
    // http://developer.apple.com/library/IOs/#documentation/CoreFoundation/Conceptual/CFStrings/Articles/MutableStrings.html
    unsigned int exitcode = 0;
    
    if (argc > 1) {
        printf("starting screenresolution argv=");
        for (int i = 1 ; i < argc ; i++) {
            printf("%s ",argv[i]);
        }
        printf("\n");
   
        CGError rc;
        uint32_t displayCount = 0;
        uint32_t activeDisplayCount = 0;
        CGDirectDisplayID *activeDisplays = NULL;
        
        rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
        if (rc != kCGErrorSuccess) {
            printf("Error: failed to get list of active displays\n");
            return 1;
        }
        // Allocate storage for the next CGGetActiveDisplayList call
        activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
        if (activeDisplays == NULL) {
            printf("Error: could not allocate memory for display list\n");
            return 1;
        }
        rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
        if (rc != kCGErrorSuccess) {
            printf("Error: failed to get list of active displays\n");
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
                        printf("Skipping display %d\n", i);
                    } else {
                        struct config newConfig;
                        isDisplayLCD(activeDisplays[i]);
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
                printf("screenresolution sets the screen resolution on Mac computers.\n\n");
                printf("screenresolution version %s Licensed under GPLv2\n", VERSION);
                printf("Copyright (C) 2011  John Ford <john@johnford.info> Modified by Li Richard at 2012\n\n");
                printf("usage: screenresolution [get]    - Show the resolution of all active displays\n");
                printf("       screenresolution [list]   - Show available resolutions of all active displays\n");
                printf("       screenresolution [set [skip] [display1resolution] [display2resolution]]\n");
                printf("                                 - Sets display resolution and refresh rate\n");
                printf("       screenresolution --version - Displays version information for screenresolution\n"); 
                printf("       screenresolution --help    - Displays this help information\n\n"); 
                printf("examples: screenresolution set 800x600x32            - Sets main display to 800x600x32\n");
                printf("          screenresolution set 800x600x32 800x600x32 - Sets both displays to 800x600x32\n");
                printf("          screenresolution set skip 800x600x32       - Sets second display to 800x600x32\n\n");
            } else if (strcmp(argv[1], "--version") == 0) {
                printf("screenresolution version %s\nLicensed under GPLv2\n", VERSION);
   
                break;
            } else {
                printf("I'm sorry %s. I'm afraid I can't do that\n", getlogin());
                // Send help information to stderr
                printf("Error: unable to copy current display mode\n\n");
                printf("screenresolution version %s -- Licensed under GPLv2\n\n\n", VERSION);
                printf("usage: screenresolution [get]  - Show the resolution of all active displays\n");
                printf("       screenresolution [list] - Show available resolutions of all active displays\n");
                printf("       screenresolution [set [skip] [display1resolution] [display2resolution]]\n");
                printf("                                - Sets display resolution and refresh rate\n");
                printf("       screenresolution --version - Displays version information for screenresolution\n");
                printf("       screenresolution --help    - Displays this help information\n\n");
                printf("examples: screenresolution set 800x600x32            - Sets main display to 800x600x32\n");
                printf("          screenresolution set 800x600x32 800x600x32 - Sets both displays to 800x600x32\n");
                printf("          screenresolution set skip 800x600x32       - Sets second display to 800x600x32\n\n");
                exitcode++;
 
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

int modecompare(struct sLIST *elem1, struct sLIST *elem2)  
{  
	if ( elem1->width < elem2->width)  
		return -1;  
	else if (elem1->width > elem2->width) return 1;  
	if (elem1->height < elem2->height) return -1;  
	else if (elem1->height > elem2->height) return 1;  
	else return 0;  
}  

int GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight)  
{  
	CFArrayRef modeList;  
	CGDisplayModeRef mode;  
	CFIndex index, count, scount=0; // sindex, 
	double width, height, depth, freq;  
	//double width1, height1, depth1, freq1;  
	int flag;//, flag1;  
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
		//if (!((width==width1) && (height==height1) && (depth==depth1) && (freq==freq1) && (flag==flag1))) 
        {  
			if (CGDisplayModeIsUsableForDesktopGUI(mode)) {  
				mList[scount].mode=mode; mList[scount].width=width; mList[scount].height=height;  
				//width1=width; height1=height; depth1=depth; freq1=freq; flag1=flag;  
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

/*
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
*/


int configureDisplay(CGDirectDisplayID display, struct config *config, int displayNum) 
{
    if (isLCD == CRT_MONITOR) {
    
        unsigned int returncode = 1;
        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
        if (allModes == NULL) {
            printf("Error: failed trying to look up modes for display %u\n", displayNum);
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
            printf("set mode on display %u to %lux%lux%lu@%.0f\n", displayNum, pw, ph, pd, pr);
            setDisplayToMode(display,newMode);
        } else {
            printf("Error: mode %lux%lux%lu@%f not available on display %u\n", 
              config->w, config->h, config->d, config->r, displayNum);
            returncode = 0;
        }
        return returncode;
    }
    else if (isLCD == LCD_MONITOR) {
        int flag = -1 ; 
        flag = GetBestDisplayMod(displayNum, config->w, config->h);  
		if (flag < 0) {
			fprintf(stderr, "ERROR: flag num error : %d.\n", flag);  
			return -1;  
		}
        
        //CFDictionaryRef switchMode = CGDisplayBestModeForParameters(display, config->d, config->w, config->h, NULL);
        
        //if (! MyDisplaySwitchToMode(display, switchMode)) {
          //  fprintf(stderr, "Error changing resolution to %lu %lu\n", config->d, config->w);
           // return 1;
        //}
    }
    return 0;
}

unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode) {
    CGError rc;
    CGDisplayConfigRef config;
    rc = CGBeginDisplayConfiguration(&config);
    if (rc != kCGErrorSuccess) {
        printf("Error: failed CGBeginDisplayConfiguration err(%u)\n", rc);
        return 0;
    }
    rc = CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
    if (rc != kCGErrorSuccess) {
        printf("Error: failed CGConfigureDisplayWithDisplayMode err(%u)\n", rc);
        return 0;
    }
    rc = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (rc != kCGErrorSuccess) {
        printf("Error: failed CGCompleteDisplayConfiguration err(%u)\n", rc);        
        return 0;
    }
    return 1;
}

unsigned int isDisplayLCD(CGDirectDisplayID display)
{
    
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(display);
    if (currentMode == NULL) {
        printf("Error: unable to copy current display mode\n");
        return 1;
    }
    
    float refreshHz = CGDisplayModeGetRefreshRate(currentMode);
    
    if (refreshHz < 1e-6) 
        isLCD = LCD_MONITOR;
    else
        isLCD = CRT_MONITOR;
    
    CGDisplayModeRelease(currentMode);
    
    return 0;
}

double CGDisplayGetRefreshRate(CGDisplayModeRef mode, CGDirectDisplayID displayID, BOOL isSilent)
{
    
    float refreshHz = CGDisplayModeGetRefreshRate(mode);
    
    if (refreshHz < 1e-6) {
        
        isLCD = LCD_MONITOR;
        if (!isSilent)
            printf("LCD monitor should use EDID to get its refresh rate.\n");
        unsigned char i, EDID[128];
        CFRange allrange =  {0, 128};
        CFDictionaryRef displayDict = nil;
        //CFDataRef EDIDValue = nil;
        
        // Now ask IOKit about the EDID reported in the display device (low level)
        io_connect_t displayPort = CGDisplayIOServicePort(displayID);
        if (displayPort) 
            displayDict = (CFDictionaryRef)IOCreateDisplayInfoDictionary(displayPort, 0);       
        //if (displayDict)
        //    EDIDValue = CFDictionaryGetValue(displayDict, CFSTR(kIODisplayEDIDKey));
        
        //if (EDIDValue)
        {	/* this will fail on i.e. televisions connected to powerbook s-video output */
            CFDataGetBytes(CFDictionaryGetValue(displayDict, CFSTR(kIODisplayEDIDKey)),allrange, EDID);

            if (!isSilent) {
                printf("IOKit reports the following EDID for your main display:\n\n");
                for (i = 0; i < 128; i++){
                    printf("%02X ", EDID[i]);
                    if ((i+1)%16 == 0) printf("\n");
                }
                printf("\n");
            }
                parse_edid(EDID,isSilent);
            
            if (!isSilent) 
                printf("\nIf there is a valid reported 'vfreq' in the EDID,\nand CoreGraphics reported 0.000000,\nthen RADAR #3162841 is still valid.\n");
                refreshHz = vfreq;

        }
        if (!isSilent) 
            printf("IOKit had a problem reading your main display EDID.\nAs long as CoreGraphics did not report 0.000000, this is OK.\n");
        
        
        if (displayDict!= nil)
            CFRelease(displayDict);
        
    }
    else {
        isLCD = CRT_MONITOR;
    }
	
    return refreshHz;
} // prepareCVDisplayLink

unsigned int listCurrentMode(CGDirectDisplayID display, int displayNum) {
    unsigned int returncode = 1;
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(display);
    if (currentMode == NULL) {
        printf("Error: unable to copy current display mode\n");
        return 0;
    }
    
    printf("Display %d: %lux%lux%lu@%.2fHz\n",
          displayNum,
          CGDisplayModeGetWidth(currentMode),
          CGDisplayModeGetHeight(currentMode),
          bitDepth(currentMode),
          //CGDisplayModeGetRefreshRate(currentMode)
           CGDisplayGetRefreshRate(currentMode,display,IS_SILENT)
           );
    CGDisplayModeRelease(currentMode);
    return returncode;
}

unsigned int listAvailableModes(CGDirectDisplayID display, int displayNum) {
    unsigned int returncode = 1;
    int i;
    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
    if (allModes == NULL) {
        printf("Error: unable to copy all display mode\n");
        return  0;
    }
#ifndef LIST_DEBUG
    printf("Available Modes on Display %d\n", displayNum);
    
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
        sprintf(modestr, "%lux%lux%lu@%.2f",
                CGDisplayModeGetWidth(mode),
                CGDisplayModeGetHeight(mode),
                bitDepth(mode),
                //CGDisplayModeGetRefreshRate(mode)
                CGDisplayGetRefreshRate(mode,display,IS_SILENT)
                );
        printf("%-20s ", modestr);
        if (i % MODES_PER_LINE == MODES_PER_LINE - 1) {
            printf("\n");
        }
#else
        uint32_t ioflags = CGDisplayModeGetIOFlags(mode);
        printf("display: %d %4lux%4lux%2lu@%.0f usable:%u ioflags:%4x valid:%u safe:%u default:%u\n",
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
        printf("safety:%u alwaysshow:%u nevershow:%u notresize:%u requirepan:%u int:%u simul:%u\n",
               ioflags & kDisplayModeSafetyFlags ?1:0,
               ioflags & kDisplayModeAlwaysShowFlag ?1:0,
               ioflags & kDisplayModeNeverShowFlag ?1:0,
               ioflags & kDisplayModeNotResizeFlag ?1:0,
               ioflags & kDisplayModeRequiresPanFlag ?1:0,
               ioflags & kDisplayModeInterlacedFlag ?1:0,
               ioflags & kDisplayModeSimulscanFlag ?1:0 );
        printf("builtin:%u notpreset:%u stretched:%u notgfxqual:%u valagnstdisp:%u tv:%u vldmirror:%u\n",
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
    unsigned int rc = 0;
    size_t w;
    size_t h;
    size_t d;
    double r;
    if (isLCD == CRT_MONITOR) {
        
        int numConverted = sscanf(string, "%lux%lux%lu@%lf", &w, &h, &d, &r);
        if (numConverted != 4) {
        rc = 0;
        printf("Error: the mode '%s' couldn't be parsed", string);
        } 
        else {
            out->w = w;
            out->h = h;
            out->d = d;
            out->r = r;
            rc = 1;
        }
    }
    else if (isLCD == LCD_MONITOR) {
        
        int numConverted = sscanf(string, "%lux%lux%lu", &w, &h, &d);
        if (numConverted != 3) {
            rc = 0;
            printf("Error: the mode '%s' couldn't be parsed", string);
        } 
        else {
            out->w = w;
            out->h = h;
            out->d = 32;
            out->r = 60;
            rc = 1;
        }
    }
    return rc;
}
