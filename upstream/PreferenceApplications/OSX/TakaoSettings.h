/*
Copyright (c) 2012, Yahoo! Inc.  All rights reserved.
Copyrights licensed under the New BSD License. See the accompanying LICENSE
file for terms.
*/
// [AUTO_HEADER]


/*!
	@header TakaoSettings
*/

//#define LFLSTR(x)      [[NSBundle mainBundle] localizedStringForKey:x value:nil table:nil]

/*!
	@define PLIST_GLOBAL_FILENAME
	@abstract The file name of the plist file for global settings.
*/
#define	PLIST_GLOBAL_FILENAME	@"io.github.wing.lkkime.plist"
/*!
	@define PLIST_PHONETIC_FILENAME
	@abstract The file name of the plist file for settings of the 
	Traditional Phonetic Input Method.
*/
#define	PLIST_PHONETIC_FILENAME	@"io.github.wing.lkkime.TraditionalMandarin.plist"
/*!
	@define PLIST_SMARTPHONETIC_FILENAME
	@abstract The file name of the plist file for settings of the 
	Smart Phonetic Input Method.
*/
#define	PLIST_SMARTPHONETIC_FILENAME	@"io.github.wing.lkkime.SmartMandarin.plist"
/*!
	@define PLIST_CANGJIE_FILENAME
	@abstract The file name of the plist file for settings of the 
	Cangjie Phonetic Input Method.
*/
#define	PLIST_CANGJIE_FILENAME	@"io.github.wing.lkkime.Generic-cj-cin.plist"
/*!
	@define PLIST_SIMPLEX_FILENAME
	@abstract The file name of the plist file for settings of the 
	Simplex Phonetic Input Method.
*/
#define	PLIST_SIMPLEX_FILENAME	@"io.github.wing.lkkime.Generic-simplex-cin.plist"
#define PLIST_SEARCH_FILENAME	@"io.github.wing.lkkime.OneKey.plist"
#define	PLIST_GENERIC_FILENAME(x)	[NSString stringWithFormat:@"io.github.wing.lkkime.%@.plist", x]
#define PLIST_WORDCOUNT_FILENAME	@"io.github.wing.lkkime.YKAFWordCount.plist"

/*!
	@define CACHE_FOLDER
	@abstract The name of the cache folder
*/
#define CACHE_FOLDER	@"io.github.wing.lkkime"
/*!
	@define OPENVANILLA_DO_CONNECTION_NAME
	@abstract The identifer of the DO connection between OpenVanilla 
	server and the preference tool.
*/
#ifndef OPENVANILLA_DO_CONNECTION_NAME
    #error Must define OPENVANILLA_DO_CONNECTION_NAME
#endif

#import "OpenVanillaService.h"
#import "LFUtilities.h"
