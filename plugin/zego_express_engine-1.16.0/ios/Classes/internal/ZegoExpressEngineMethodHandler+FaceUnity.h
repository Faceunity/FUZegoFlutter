//
//  ZegoExpressEngineMethodHandler+FaceUnity.h
//  zego_express_engine
//
//  Created by Chen on 2021/9/13.
//

#import "ZegoExpressEngineMethodHandler.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 相芯模块中间件，桥梁形式存在，持有业务模型并且分发方法到具体的业务数据类里面.可以理解成业务插件的容器，否则Plugin 需要引入很多业务插件并且需要持有实例变量耦合度就高了
 */
@interface ZegoExpressEngineMethodHandler (FaceUnity)

@end

NS_ASSUME_NONNULL_END
