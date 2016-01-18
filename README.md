# runtimeLearn
runtime

学习runtime的理解和心得<http://www.cocoachina.com/ios/20150901/13173.html>

OC Runtime 运行时之一：类与对象<http://www.cocoachina.com/ios/20141031/10105.html>

OC Runtime 运行时之二：成员变量与属性<http://www.cocoachina.com/ios/20141105/10134.html>

OC Runtime 运行时之三：方法与消息<http://www.cocoachina.com/ios/20141106/10150.html>

OC Runtime 运行时之四：Method Swizzling <http://www.cocoachina.com/ios/20140225/7880.html>

OC Runtime 运行时之五：协议与分类<http://www.cocoachina.com/ios/20141110/10174.html>

OC Runtime 运行时之六：<http://www.cocoachina.com/ios/20141111/10186.html>

Runtime初涉之消息转发 <http://www.cocoachina.com/ios/20151015/13769.html>

使用runtime解决UIButton 重复点击问题 <http://www.cocoachina.com/ios/20150911/13260.html>

* 获取列表
* 方法调用
* 拦截调用
* 动态添加方法
* 关联对象
* 方法交换
	
	不咋会用啊除了会用关联
#####相关的定义：
	
	/// 描述类中的一个方法
	typedef struct objc_method *Method;
	/// 实例变量
	typedef struct objc_ivar *Ivar;
	/// 类别Category
	typedef struct objc_category *Category;
	/// 类中声明的属性
	typedef struct objc_property *objc_property_t;
	类在runtime中的表示

	//类在runtime中的表示
	
	struct objc_class {
    	Class isa;//指针，顾名思义，表示是一个什么，
    	//实例的isa指向类对象，类对象的isa指向元类
		#if !__OBJC2__
    	Class super_class;  		//指向父类
    	const char *name;  			//类名
    	long version;
    	long info;
    	long instance_size						 //类的实例变量大小
    	struct objc_ivar_list *ivars 			 //成员变量列表
    	struct objc_method_list **methodLists;  //方法列表
    	struct objc_cache *cache;				 //缓存
    	//一种优化，调用过的方法存入缓存列表，下次调用先找缓存
    	struct objc_protocol_list *protocols 	 //协议列表
    	#endif
	} OBJC2_UNAVAILABLE;
	/* Use `Class` instead of `struct objc_class *` */


##### 获取列表
我们可以通过runtime的一系列方法获取类的一些信息（包括属性列表，方法列表，成员变量列表，和遵循的协议列表）。

	#import <objc/runtime.h>
	
	@interface ViewController : UIViewController <UITableViewDelegate> {
    	NSString *name;
	}
	@property (nonatomic, strong) NSString *testString;
	- (void)testMethod;
	@end
	
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
    
	打印：
	propertyname --> testString
	propertyname --> hash
	propertyname --> superclass
	propertyname --> description
	propertyname --> debugDescription
	method --> testMethod
	method --> testString
	method --> setTestString:
	method --> .cxx_destruct
	method --> viewDidLoad
	ivar --> name
	ivar --> _testString
	protocol --> UITableViewDelegate

##### 方法调用
	让我们看一下方法调用在运行时的过程（参照前文类在runtime中的表示）

	如果用实例对象调用实例方法，会到实例的isa指针指向的对象（也就是类对象）操作。

	如果调用的是类方法，就会到类对象的isa指针指向的对象（也就是元类对象）中操作。

	1、首先，在相应操作的对象中的缓存方法列表中找调用的方法，如果找到，转向相应实现并执行。
	2、如果没找到，在相应操作的对象中的方法列表中找调用的方法，如果找到，转向相应实现执行
	3、如果没找到，去父类指针所指向的对象中执行1，2.
	4、以此类推，如果一直到根类还没找到，转向拦截调用。
	5、如果没有重写拦截调用的方法，程序报错。

	针对cache，我们用下面例子来说明其执行过程：

	NSArray *array = [[NSArray alloc] init];
	其流程是：

	[NSArray alloc]先被执行。因为NSArray没有+alloc方法，于是去父类NSObject去查找。

	检测NSObject是否响应+alloc方法，发现响应，于是检测NSArray类，并根据其所需的内存空间大小开始分配内存空间，然后把isa指针指向NSArray类。同时，+alloc也被加进cache列表里面。

	接着，执行-init方法，如果NSArray响应该方法，则直接将其加入cache；如果不响应，则去父类查找。

	在后期的操作中，如果再以[[NSArray alloc] init]这种方式来创建数组，则会直接从cache中取出相应的方法，直接调用
	
***
	当我们向一个Objective-C对象发送消息时，运行时库会根据实例对象的isa指针找到这个实例对象所属的类。Runtime库会在类的方法
	列表及父类的方法列表中去寻找与消息对应的selector指向的方法。找到后即运行这个方法

	当我们向一个对象发送消息时，runtime会在这个对象所属的这个类的方法列表中查找方法；而向一个类发送消息时，会在这个类的
	meta-class的方法列表中查找
	
	meta-class之所以重要，是因为它存储着一个类的所有类方法。每个类都会有一个单独的meta-class，因为每个类的类方法基本不可能完全相同
	
	Objective-C的设计者让所有的meta-class的isa指向基类的meta-class，以此作为它们的所属类。即，任何NSObject继承体系下的meta-class都使用NSObject的meta-class作为自己的所属类，而基类的meta-class的isa指针是指向它自己

##### 拦截调用
在方法调用中说到了，如果没有找到方法就会转向拦截调用。

那么什么是拦截调用呢。

拦截调用就是，在找不到调用的方法程序崩溃之前，你有机会通过重写NSObject的四个方法来处理

	+ (BOOL)resolveClassMethod:(SEL)sel;
	+ (BOOL)resolveInstanceMethod:(SEL)sel;
	//后两个方法需要转发到其他的类处理
	- (id)forwardingTargetForSelector:(SEL)aSelector;
	- (void)forwardInvocation:(NSInvocation *)anInvocation;
	
	第一个方法是当你调用一个不存在的类方法的时候，会调用这个方法，默认返回NO，你可以加上自己的处理然后返回YES。
	第二个方法和第一个方法相似，只不过处理的是实例方法。
	第三个方法是将你调用的不存在的方法重定向到一个其他声明了这个方法的类，只需要你返回一个有这个方法的target。
	第四个方法是将你调用的不存在的方法打包成NSInvocation传给你。做完你自己的处理后，调用invokeWithTarget:方法让某个target触发这个方法。
	
##### 动态添加方法
重写了拦截调用的方法并且返回了YES，我们要怎么处理呢？

有一个办法是根据传进来的SEL类型的selector动态添加一个方法。

	首先从外部隐式调用一个不存在的方法：

	//隐式调用方法
	[target performSelector:@selector(resolveAdd:) withObject:@"test"];
	然后，在target对象内部重写拦截调用的方法，动态添加方法。
	
	//一个Objective-C方法是一个简单的C函数，它至少包含两个参数—self和_cmd。所以，我们的实现函数(IMP参数指向的函数)至少需要两个参数
	void runAddMethod(id self, SEL _cmd, NSString *string){
    	NSLog(@"add C IMP ", string);
	}
	+ (BOOL)resolveInstanceMethod:(SEL)sel{
    	//给本类动态添加一个方法
    	if ([NSStringFromSelector(sel) isEqualToString:@"resolveAdd:"]) {
    	    class_addMethod(self, sel, (IMP)runAddMethod, "v@:*");
    	}
    	return [super resolveInstanceMethod:sel];
	}
	
	如果上一步无法处理消息，则runtime会继续调用下面方法
	- (id)forwardingTargetForSelector:(SEL)aSelector {
    
    	NSString *selectorString = NSStringFromSelector(aSelector);
    	//将消息转发给 customClass来处理
    	if ([selectorString isEqualToString:@"resolvedAdd:"]) {
        	return _customClass;
    	}
    	return [super forwardingTargetForSelector:aSelector];
	}
	如果上一步还不能处理未知消息 会调用 forwardInvocation 启用完整的消息转发机制了
	要重写methodSigna...这个方法
	- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        if ([CustomClass instancesRespondToSelector:aSelector]) {
            signature = [CustomClass instanceMethodSignatureForSelector:aSelector];
        }
    }
    return signature;
	}

	- (void)forwardInvocation:(NSInvocation *)anInvocation {
    	if ([CustomClass instancesRespondToSelector:anInvocation.selector]) {
        	[anInvocation invokeWithTarget:_customClass];
    	}
    
	}
	
	其中class_addMethod的四个参数分别是：

	Class cls 给哪个类添加方法，本例中是self
	SEL name 添加的方法，本例中是重写的拦截调用传进来的selector。
	IMP imp 方法的实现，C方法的方法实现可以直接获得。如果是OC方法，可以用+ (IMP)instanceMethodForSelector:(SEL)aSelector;获得方法的实现。
	"v@:*"方法的签名，代表有一个参数的方法。

##### 关联对象
现在你准备用一个系统的类，但是系统的类并不能满足你的需求，你需要额外添加一个属性。

这种情况的一般解决办法就是继承。

但是，只增加一个属性，就去继承一个类，总是觉得太麻烦类。

	这个时候，runtime的关联属性就发挥它的作用了。

	//首先定义一个全局变量，用它的地址作为关联对象的key
	static char associatedObjectKey;
	//设置关联对象
	objc_setAssociatedObject(target, &associatedObjectKey, @"添加的字符串属性", OBJC_ASSOCIATION_RETAIN_NONATOMIC); //获取关联对象
	NSString *string = objc_getAssociatedObject(target, &associatedObjectKey);
	NSLog(@"AssociatedObject = %@", string);
	objc_setAssociatedObject的四个参数：

	id object给谁设置关联对象。
	const void *key关联对象唯一的key，获取时会用到。
	id value关联对象。
	objc_AssociationPolicy关联策略，有以下几种策略：

	enum {
    	OBJC_ASSOCIATION_ASSIGN = 0,
    	OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1, 
    	OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
    	OBJC_ASSOCIATION_RETAIN = 01401,
    	OBJC_ASSOCIATION_COPY = 01403 
	};
	如果你熟悉OC，看名字应该知道这几种策略的意思了吧。

	objc_getAssociatedObject的两个参数。
	id object获取谁的关联对象。
	const void *key根据这个唯一的key获取关联对象。

	其实，你还可以把添加和获取关联对象的方法写在你需要用到这个功能的类的类别中，方便使用。


	//添加关联对象
	- (void)addAssociatedObject:(id)object{
    	objc_setAssociatedObject(self, @selector(getAssociatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	//获取关联对象
	- (id)getAssociatedObject{
    	return objc_getAssociatedObject(self, _cmd);
	}
	注意：这里面我们把getAssociatedObject方法的地址作为唯一的key，_cmd代表当前调用方法的地址。

##### 方法交换
方法交换，顾名思义，就是将两个方法的实现交换。例如，将A方法和B方法交换，调用A方法的时候，就会执行B方法中的代码，反之亦然。

method swizzling可以通过选择器来改变它引用的函数指针。
	
	//load方法会在类第一次加载的时候被调用
	//调用的时间比较靠前，适合在这个方法里做方法交换
	+ (void)load {
   
		//方法交换应该被保证，在程序中只会执行一次
    	static dispatch_once_t onceToken;
    	dispatch_once(&onceToken, ^{
        
        	Class class = [self class];
        
        	// When swizzling a class method, use the following:
        	// Class class = object_getClass((id)self);
        
        	SEL originalSelector = @selector(viewWillAppear:);
        	SEL swizzledSelector = @selector(xxx_viewWillAppear:);
        
        	Method originalMethod = class_getInstanceMethod(class, originalSelector);
        	Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        	
        	//首先动态添加方法，实现是被交换的方法，返回值表示添加成功还是失败
        	BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        	if (didAddMethod) {
        		//如果成功，说明类中不存在这个方法的实现
           	    //将被交换方法的实现替换到这个并不存在的实现
            	class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        	} else {
            	method_exchangeImplementations(originalMethod, swizzledMethod);
        	}
    	});
    
	}


	//这段代码看起来像会导致一个死循环
	//但其实并没有，在Swizzling的过程中，xxx_viewWillAppear:会被重新分配给UIViewController的-viewWillAppear:的原始实现
	- (void)xxx_viewWillAppear:(BOOL)animated {
    
    	[self xxx_viewWillAppear:animated];
    	NSLog(@"viewWillAppear2: %@", self);
	}

###### 其它

IMP实际上是一个函数指针，指向方法的实现












