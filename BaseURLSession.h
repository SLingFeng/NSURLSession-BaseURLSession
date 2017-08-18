//
//  BaseURLSession.h
//  URLSessionTest
//
//  Created by SADF on 16/10/18.
//  Copyright © 2016年 SADF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BaseURLSession : NSObject

/**
 基础本单类

 @return nsobject
 */
+(BaseURLSession *)shareBase;
/**
 请求单类

 @return 请求
 */
+(NSURLSession *)shareSession;

/**
 * @author LingFeng, 2016-10-18 10:49:47
 *
 * 所有的请求，key是URLstring、value是task
 */
@property (strong, nonatomic) NSMutableDictionary * taskRequsetForGET;

/**
 * @author LingFeng, 2016-10-18 10:49:47
 *
 * 所有的请求，key是URLstring、value是dic
 */
@property (strong, nonatomic) NSMutableDictionary * taskRequsetForPOST;

/**
 get请求

 @param URLString 请求地址
 @param parameters 追加
 @param backData  返回的JSON数据
 @param failure   错误
 */
+(void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary * data))backData  failure:(void(^)(NSError * error))failure;
/**
 post请求

 @param URLString  请求地址
 @param parameters 追加
 @param backData   返回的JSON数据
 @param failure   错误
 */
+(void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary * data))backData  failure:(void(^)(NSError * error))failure;

/**
 post上传图片

 @param url             上传地址
 @param uploadImage     上传图片
 @param uploadImageName 上传图片名字
 @param uploadType      上传图片类型 jpg png
 @param quality         压缩率 0-1
 @param params          需要的参数
 @param backData        返回的JSON数据
 @param failure         错误
 */
+(void)uploadImage:(NSString*)url uploadImage:(UIImage *)uploadImage uploadImageName:(NSString *)uploadImageName uploadType:(NSString *)uploadType quality:(float)quality params:(NSMutableDictionary *)params completion:(void(^)(NSDictionary * data))backData failure:(void(^)(NSError * error))failure;
@end
