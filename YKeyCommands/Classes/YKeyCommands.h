//
//  YKeyCommands.h
//  Pods
//
//  Created by 李遵源 on 2017/9/28.
//
//

#import <Foundation/Foundation.h>

@interface YKeyCommands : NSObject

+ (instancetype)sharedInstance;

/**
 * Register a single-press keyboard command.
 */
- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)flags
                             action:(void (^)(UIKeyCommand *command))block;

/**
 * Unregister a single-press keyboard command.
 */
- (void)unregisterKeyCommandWithInput:(NSString *)input
                        modifierFlags:(UIKeyModifierFlags)flags;


/**
 * Register a double-press keyboard command.
 */
- (void)registerDoublePressKeyCommandWithInput:(NSString *)input
                                 modifierFlags:(UIKeyModifierFlags)flags
                                        action:(void (^)(UIKeyCommand *command))block;

/**
 * Unregister a double-press keyboard command.
 */
- (void)unregisterDoublePressKeyCommandWithInput:(NSString *)input
                                   modifierFlags:(UIKeyModifierFlags)flags;


@end
