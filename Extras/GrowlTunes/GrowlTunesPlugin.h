/*
 Copyright (c) The Growl Project, 2004
 All rights reserved.


 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:


 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

/*
 *  GrowlTunesProtocol.h
 *  GrowlTunes
 *
 *  Created by Kevin Ballard on 10/5/04.
 *  Copyright 2004 Kevin Ballard. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@protocol GrowlTunesPlugin <NSObject>
- (NSImage *) artworkForTitle:(NSString *)track
					 byArtist:(NSString *)artist
					  onAlbum:(NSString *)album
				   composedBy:(NSString *)composer
				isCompilation:(BOOL)compilation;

- (BOOL) usesNetwork;
@end

@protocol GrowlTunesPluginArchive <NSObject>
- (BOOL) archiveImage:(NSImage *)image
				track:(NSString *)track
			   artist:(NSString *)artist
				album:(NSString *)album
			 composer:(NSString *)composer
		  compilation:(BOOL)compilation;
@end
