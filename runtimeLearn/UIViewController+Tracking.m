//
//  UIViewController+Tracking.m
//  runtimeLearn
//
//  Created by caodaxun_iMac on 15/10/15.
//  Copyright © 2015年 SWCM. All rights reserved.
//  Method Swizzing
//  Method swizzling指的是改变一个已存在的选择器对应的实现的过程，它依赖于Objectvie-C中方法的调用能够在运行时进改变——通过改变类的调度表（dispatch table）中选择器到最终函数间的映射关系。

#import "UIViewController+Tracking.h"
#import <objc/runtime.h>

@implementation UIViewController (Tracking)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(xxx_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        
    });
    
}

#pragma mark - Method Swizzling
//这段代码看起来像会导致一个死循环
//但其实并没有，在Swizzling的过程中，xxx_viewWillAppear:会被重新分配给UIViewController的-viewWillAppear:的原始实现
- (void)xxx_viewWillAppear:(BOOL)animated {
    
    [self xxx_viewWillAppear:animated];
    NSLog(@"viewWillAppear2: %@", self);
}

@end
