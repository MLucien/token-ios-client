// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Contacts/Contacts.h>
#import <Foundation/Foundation.h>
#import <SignalServiceKit/ContactsManagerProtocol.h>
#import <SignalServiceKit/PhoneNumber.h>
#import "CollapsingFutures.h"
#import "Contact.h"

/**
 Get Signal or Token contacts. 
 */

@class TokenContact;

@interface ContactsManager : NSObject <ContactsManagerProtocol>

+ (BOOL)name:(NSString * _Nonnull)nameString matchesQuery:(NSString * _Nonnull)queryString;

- (NSString * _Nonnull)displayNameForPhoneIdentifier:(NSString * _Nullable)phoneNumber;

- (NSArray<Contact *> * _Nonnull)signalContacts;

- (NSArray<TokenContact *> * _Nonnull)tokenContacts;

- (TokenContact * _Nullable)tokenContactForAddress:(NSString * _Nullable)address;

- (UIImage * _Nullable)imageForPhoneIdentifier:(NSString * _Nullable)phoneNumber;

@end
