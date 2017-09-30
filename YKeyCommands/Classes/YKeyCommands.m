//
//  YKeyCommands.m
//  Pods
//
//  Created by 李遵源 on 2017/9/28.
//
//

#import "YKeyCommands.h"
#import <UIKit/UIDevice.h>
#import <objc/runtime.h>
#import "YKeyCommoandUtils.h"


static BOOL YIsIOS8OrEarlier()
{
    return [UIDevice currentDevice].systemVersion.floatValue < 9;
}

@interface YKeyCommand : NSObject

@property (nonatomic, strong) UIKeyCommand *keyCommand;
@property (nonatomic, copy) void (^block)(UIKeyCommand *);


- (instancetype)initWithKeyCommand:(UIKeyCommand *)keyCommand
                             block:(void (^)(UIKeyCommand *))block;

- (BOOL)matchesInput:(NSString *)input flags:(UIKeyModifierFlags)flags;
@end


@implementation YKeyCommand


- (instancetype)initWithKeyCommand:(UIKeyCommand *)keyCommand
                             block:(void (^)(UIKeyCommand *))block
{
    if ((self = [super init])) {
        _keyCommand = keyCommand;
        _block = block;
    }
    return self;
}

- (id)copyWithZone:(__unused NSZone *)zone
{
    return self;
}

- (NSUInteger)hash
{
    return _keyCommand.input.hash ^ _keyCommand.modifierFlags;
}

- (BOOL)isEqual:(YKeyCommand *)object
{
    if (![object isKindOfClass:[YKeyCommand class]]) {
        return NO;
    }
    return [self matchesInput:object.keyCommand.input
                        flags:object.keyCommand.modifierFlags];
}

- (BOOL)matchesInput:(NSString *)input flags:(UIKeyModifierFlags)flags
{
    return [_keyCommand.input isEqual:input] && _keyCommand.modifierFlags == flags;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p input=\"%@\" flags=%lld hasBlock=%@>",
            [self class], self, _keyCommand.input, (long long)_keyCommand.modifierFlags,
            _block ? @"YES" : @"NO"];
}


@end

@interface YKeyCommands ()
@property (nonatomic, strong) NSMutableSet<YKeyCommand *> *commands;
@end

@implementation YKeyCommands

+ (instancetype)sharedInstance
{
    static YKeyCommands *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

+ (void)initialize
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (YIsIOS8OrEarlier()) {
            swapInstanceMethods([UIResponder class], @selector(keyCommands), @selector(y_keyCommands));
            swapInstanceMethods([UIApplication class], @selector(sendAction:to:from:forEvent:), @selector(y_sendAction:to:from:forEvent:));
        } else {
            swapInstanceMethods([UIResponder class], @selector(keyCommands), @selector(y_keyCommands));
        }
    });
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _commands = [NSMutableSet new];
    }
    return self;
}

void swapInstanceMethods(Class cls, SEL original, SEL replacement)
{
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    method_exchangeImplementations(originalMethod, replacementMethod);
}


- (void)registerKeyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)flags
                             action:(void (^)(UIKeyCommand *))block
{
    YAssertMainQueue();
    
    if (input.length && flags && YIsIOS8OrEarlier()) {
        
        // Workaround around the first cmd not working: http://openradar.appspot.com/19613391
        // You can register just the cmd key and do nothing. This ensures that
        // command-key modified commands will work first time. Fixed in iOS 9.
        
        [self registerKeyCommandWithInput:@"" modifierFlags:flags action:nil];
    }
    
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:input
                                                modifierFlags:flags
                                                       action:@selector(y_handleKeyCommand:)];
    
    YKeyCommand *keyCommand = [[YKeyCommand alloc] initWithKeyCommand:command block:block];
    [_commands removeObject:keyCommand];
    [_commands addObject:keyCommand];
}

- (void)unregisterKeyCommandWithInput:(NSString *)input
                        modifierFlags:(UIKeyModifierFlags)flags
{
    YAssertMainQueue();
    
    for (YKeyCommand *command in _commands.allObjects) {
        if ([command matchesInput:input flags:flags]) {
            [_commands removeObject:command];
            break;
        }
    }
}

- (BOOL)isKeyCommandRegisteredForInput:(NSString *)input
                         modifierFlags:(UIKeyModifierFlags)flags
{
    YAssertMainQueue();
    
    for (YKeyCommand *command in _commands) {
        if ([command matchesInput:input flags:flags]) {
            return YES;
        }
    }
    return NO;
}

- (void)registerDoublePressKeyCommandWithInput:(NSString *)input
                                 modifierFlags:(UIKeyModifierFlags)flags
                                        action:(void (^)(UIKeyCommand *))block
{
    YAssertMainQueue();
    
    if (input.length && flags && YIsIOS8OrEarlier()) {
        
        // Workaround around the first cmd not working: http://openradar.appspot.com/19613391
        // You can register just the cmd key and do nothing. This ensures that
        // command-key modified commands will work first time. Fixed in iOS 9.
        
        [self registerDoublePressKeyCommandWithInput:@"" modifierFlags:flags action:nil];
    }
    
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:input modifierFlags:flags action:@selector(y_handleDoublePressKeyCommand:)];
    
    YKeyCommand *keyCommand = [[YKeyCommand alloc] initWithKeyCommand:command block:block];
    [_commands removeObject:keyCommand];
    [_commands addObject:keyCommand];
}

- (void)unregisterDoublePressKeyCommandWithInput:(NSString *)input
                                   modifierFlags:(UIKeyModifierFlags)flags
{
    YAssertMainQueue();
    
    for (YKeyCommand *command in _commands.allObjects) {
        if ([command matchesInput:input flags:flags]) {
            [_commands removeObject:command];
            break;
        }
    }
}

- (BOOL)isDoublePressKeyCommandRegisteredForInput:(NSString *)input
                                    modifierFlags:(UIKeyModifierFlags)flags
{
    YAssertMainQueue();
    
    for (YKeyCommand *command in _commands) {
        if ([command matchesInput:input flags:flags]) {
            return YES;
        }
    }
    return NO;
}
@end

@implementation UIResponder (YKeyCommands)

- (NSArray<UIKeyCommand *> *)y_keyCommands
{
    NSSet<YKeyCommand *> *commands = [YKeyCommands sharedInstance].commands;
    return [[commands valueForKeyPath:@"keyCommand"] allObjects];
}

/**
 * Single Press Key Command Response
 * Command + KeyEvent (Command + R/D, etc.)
 */
- (void)y_handleKeyCommand:(UIKeyCommand *)key
{
    // NOTE: throttle the key handler because on iOS 9 the handleKeyCommand:
    // method gets called repeatedly if the command key is held down.
    static NSTimeInterval lastCommand = 0;
    if (YIsIOS8OrEarlier() || CACurrentMediaTime() - lastCommand > 0.5) {
        for (YKeyCommand *command in [YKeyCommands sharedInstance].commands) {
            if ([command.keyCommand.input isEqualToString:key.input] &&
                command.keyCommand.modifierFlags == key.modifierFlags) {
                if (command.block) {
                    command.block(key);
                    lastCommand = CACurrentMediaTime();
                }
            }
        }
    }
}

/**
 * Double Press Key Command Response
 * Double KeyEvent (Double R, etc.)
 */
- (void)y_handleDoublePressKeyCommand:(UIKeyCommand *)key
{
    static BOOL firstPress = YES;
    static NSTimeInterval lastCommand = 0;
    static NSTimeInterval lastDoubleCommand = 0;
    static NSString *lastInput = nil;
    static UIKeyModifierFlags lastModifierFlags = 0;
    
    if (firstPress) {
        for (YKeyCommand *command in [YKeyCommands sharedInstance].commands) {
            if ([command.keyCommand.input isEqualToString:key.input] &&
                command.keyCommand.modifierFlags == key.modifierFlags &&
                command.block) {
                
                firstPress = NO;
                lastCommand = CACurrentMediaTime();
                lastInput = key.input;
                lastModifierFlags = key.modifierFlags;
                return;
            }
        }
    } else {
        // Second keyevent within 0.2 second,
        // with the same key as the first one.
        if (CACurrentMediaTime() - lastCommand < 0.2 &&
            lastInput == key.input &&
            lastModifierFlags == key.modifierFlags) {
            
            for (YKeyCommand *command in [YKeyCommands sharedInstance].commands) {
                if ([command.keyCommand.input isEqualToString:key.input] &&
                    command.keyCommand.modifierFlags == key.modifierFlags &&
                    command.block) {
                    
                    // NOTE: throttle the key handler because on iOS 9 the handleKeyCommand:
                    // method gets called repeatedly if the command key is held down.
                    if (YIsIOS8OrEarlier() || CACurrentMediaTime() - lastDoubleCommand > 0.5) {
                        command.block(key);
                        lastDoubleCommand = CACurrentMediaTime();
                    }
                    firstPress = YES;
                    return;
                }
            }
        }
        
        lastCommand = CACurrentMediaTime();
        lastInput = key.input;
        lastModifierFlags = key.modifierFlags;
    }
}
@end

@implementation UIApplication (YKeyCommands)

// Required for iOS 8.x
- (BOOL)y_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event
{
    if (action == @selector(y_handleKeyCommand:)) {
        [self y_handleKeyCommand:sender];
        return YES;
    } else if (action == @selector(y_handleDoublePressKeyCommand:)) {
        [self y_handleDoublePressKeyCommand:sender];
        return YES;
    }
    return [self y_sendAction:action to:target from:sender forEvent:event];
}

@end
