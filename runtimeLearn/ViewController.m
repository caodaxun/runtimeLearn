//
//  ViewController.m
//  runtimeLearn
//
//  Created by caodaxun_iMac on 15/10/15.
//  Copyright © 2015年 SWCM. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    unsigned int count;
    //获取属性列表
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        const char *propertyname = property_getName(propertyList[i]);
        NSLog(@"propertyname --> %@", [NSString stringWithUTF8String:propertyname]);
    }
    //获取方法列表
    Method *methodList = class_copyMethodList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        Method method = methodList[i];
        NSLog(@"method --> %@", NSStringFromSelector(method_getName(method)));
    }
    //获取成员变量列表
    Ivar *ivaList = class_copyIvarList([self class], &count);
    for (unsigned int i; i < count; i++) {
        Ivar myivar = ivaList[i];
        const char *ivarName = ivar_getName(myivar);
        NSLog(@"ivar --> %@", [NSString stringWithUTF8String:ivarName]);
    }
    //获取协议列表
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList([self class], &count);
    for (unsigned int i; i < count; i++) {
        Protocol *myprotocol = protocolList[i];
        const char *protocolName = protocol_getName(myprotocol);
        NSLog(@"protocol --> %@", [NSString stringWithUTF8String:protocolName]);
    }
    
    //动态添加方法 调用一个不存在的方法
    [self performSelector:@selector(resolvedAdd:) withObject:@"test"];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    NSLog(@"appear");
}


void runAddMethod(id self, SEL _cmd, NSString *string){
    NSLog(@"add C IMP %@", string);
}
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    //给本类动态添加一个方法
    if ([NSStringFromSelector(sel) isEqualToString:@"resolvedAdd:"]) {
        class_addMethod([self class], sel, (IMP)runAddMethod, "v@:*");
    }
    return YES;
}

- (void)testMethod {}

@end
