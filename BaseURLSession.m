//
//  BaseURLSession.m
//  URLSessionTest
//
//  Created by SADF on 16/10/18.
//  Copyright © 2016年 SADF. All rights reserved.
//

#import "BaseURLSession.h"

static NSURLSession * session = nil;
static BaseURLSession * bus = nil;

@interface BaseURLSession ()<NSURLSessionDelegate>

@end

@implementation BaseURLSession

+(BaseURLSession *)shareBase {
    @synchronized (self) {
        if (bus == nil) {
            bus = [super allocWithZone:NULL];
            bus.taskRequsetForGET = [NSMutableDictionary dictionaryWithCapacity:5];
            bus.taskRequsetForPOST = [NSMutableDictionary dictionaryWithCapacity:5];
        }
        return bus;
    }
}

+(NSURLSession *)shareSession {
    if (session == nil) {
        //创建session配置对象
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 15;
        config.timeoutIntervalForResource = 15;
        session = [NSURLSession sessionWithConfiguration:config delegate:[BaseURLSession shareBase] delegateQueue:[NSOperationQueue mainQueue]];
    }
    return session;
}

+(NSURLSessionTask *)startTask:(NSMutableURLRequest *)request utfURL:(NSString *)utfURL completion:(void(^)(id data))backData failure:(void(^)(NSError * error))failure mode:(NSString *)mode {
    NSURLSessionTask * task = [[BaseURLSession shareSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //移除
        
        if ([mode isEqualToString:@"POST"]) {
            NSLog(@"%@", [BaseURLSession shareBase].taskRequsetForPOST);
            for (NSURLSessionDataTask * tempTask in [[BaseURLSession shareBase].taskRequsetForPOST allValues]) {
                if (tempTask == task) {
                    [[BaseURLSession shareBase].taskRequsetForPOST removeObjectForKey:utfURL];
                }
            }
        }else {
            NSLog(@"%@", [BaseURLSession shareBase].taskRequsetForGET);
            for (NSString * url in [[BaseURLSession shareBase].taskRequsetForGET allKeys]) {
                if (utfURL == url) {
                    [[BaseURLSession shareBase].taskRequsetForGET removeObjectForKey:utfURL];
                }
            }
        }
        
        if (error) {
            [task resume];
            NSLog(@"失败:%@", error);
            if (failure) {
                failure(error);
            }
        }else {
            NSLog(@"\nResponse:%@\n", response);
            id dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (backData) {
                    backData(dataDic);
                }
            });
            
        }
    }];
    return task;
}

+(void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary * data))backData failure:(void(^)(NSError * error))failure {
    NSLog(@"GET:URLString->%@\n<--------------------------------------->\nparameters->%@\n", URLString, parameters);
    if (URLString == nil || ![URLString isKindOfClass:[NSString class]]) {
        NSLog(@"无网址");
        return;
    }
    
    NSMutableString * URLAppend = [NSMutableString stringWithString:URLString];
    if (parameters != nil) {
        NSMutableString * parameter = [NSMutableString string];
        for (int i=0; i<parameters.count; i++) {
            NSString * key = parameters.allKeys[i];
            NSString * value = parameters.allValues[i];
            if (i == 0) {
                [parameter appendString:[NSString stringWithFormat:@"?%@=%@", key, value]];
            }else {
                [parameter appendString:[NSString stringWithFormat:@"&%@=%@", key, value]];
            }
        }
        [URLAppend appendString:parameter];
    }
    NSLog(@"%@", [BaseURLSession shareBase].taskRequsetForGET);
    //以免有中文进行UTF编码
    NSString * utfURL = [URLAppend stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //是否有请求
    for (NSString * temp in [[BaseURLSession shareBase].taskRequsetForGET allKeys]) {
        if ([utfURL isEqualToString:temp]) {
            return;
        }
    }
    //请求路径 请求对象
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:utfURL]];
    //设置请求超时
    request.timeoutInterval = 15;
    
//    NSURLSessionTask * task = [[BaseURLSession shareSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        //移除
//        NSLog(@"%@", [BaseURLSession shareBase].taskRequsetForGET);
//        for (NSString * url in [[BaseURLSession shareBase].taskRequsetForGET allKeys]) {
//            if (utfURL == url) {
//                [[BaseURLSession shareBase].taskRequsetForGET removeObjectForKey:utfURL];
//            }
//        }
//        if (error) {
//            NSLog(@"失败:%@", error);
//            if (failure) {
//                failure(error);
//            }
//        }else {
//            NSLog(@"\nResponse:%@\n", response);
//            NSDictionary * dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (backData) {
//                    backData(dataDic);
//                }
//            });
//            
//        }
//        
//    }];
    NSURLSessionTask * task = [BaseURLSession startTask:request utfURL:utfURL completion:^(id data) {
        if (backData) {
            backData(data);
        }
    } failure:^(NSError *error) {
        NSLog(@"error:::%@", error.localizedDescription);
        
        if([error.localizedDescription isEqualToString:@"Request failed: unauthorized (401)"]) {
            NSLog(@"");
            if(failure) {
                failure(error);
            }
//            [MBProgressHUD showError:@"登录状态失效"];
        }else if ([error.localizedDescription isEqualToString:@"似乎已断开与互联网的连接。"]) {
            NSLog(@"似乎已断开与互联网的连接。");
            if(failure) {
                failure(error);
            }
//            [MBProgressHUD showError:@"未连接网络"];
        }else if ([error.localizedDescription isEqualToString:@"请求超时。"]) {
            NSLog(@"请求超时。");
            if(failure) {
                failure(error);
            }
//            [MBProgressHUD showError:@"请求超时"];
        }else {
            if(failure) {
                failure(error);
            }
//            [MBProgressHUD showError:NetworkHintStr];
        }
//        if (failure) {
//            failure(error);
//        }
    } mode:@"GET"];
    
    [task resume];
    //添加已经有的请求
    [[BaseURLSession shareBase].taskRequsetForGET setObject:task forKey:utfURL];

}

+(void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary * data))backData failure:(void(^)(NSError * error))failure {
    NSLog(@"POST:URLString->%@\n<--------------------------------------->\nparameters->%@\n", URLString, parameters);
    if (URLString == nil || ![URLString isKindOfClass:[NSString class]]) {
        NSLog(@"无网址");
        return;
    }
    for (NSDictionary * temp in [[BaseURLSession shareBase].taskRequsetForPOST allValues]) {
        if ((NSDictionary *)parameters == temp) {
            return;
        }
    }
    //以免有中文进行UTF编码
    NSString * utfURL = [URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //请求路径 请求对象
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:utfURL]];
    //设置请求超时
    request.timeoutInterval = 15;
    request.HTTPMethod = @"POST";
    if (parameters != nil) {
        NSMutableString * parameter = [NSMutableString string];
        for (NSString * key in [parameters allKeys]) {
            [parameter appendString:[NSString stringWithFormat:@"&%@=%@", key, parameters[key]]];
        }
        
        request.HTTPBody = [parameter dataUsingEncoding:NSUTF8StringEncoding];
    }

//    NSURLSessionTask * task = [[BaseURLSession shareSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        for (NSURLSessionDataTask * tempTask in [[BaseURLSession shareBase].taskRequsetForPOST allValues]) {
//            if (tempTask == task) {
//                [[BaseURLSession shareBase].taskRequsetForPOST removeObjectForKey:URLString];
//            }
//        }
//        
//        if (error) {
//            NSLog(@"失败:%@", error);
//            if (failure) {
//                failure(error);
//            }
//        }else {
//            NSLog(@"\nResponse:%@\n", response);
//            NSDictionary * dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (backData) {
//                    backData(dataDic);
//                }
//            });
//        }
//        
//    }];

    NSURLSessionTask * task = [BaseURLSession startTask:request utfURL:utfURL completion:^(id data) {
        if (backData) {
            backData(data);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    } mode:@"POST"];
    
    [task resume];
    
    [[BaseURLSession shareBase].taskRequsetForPOST setObject:task forKey:URLString];

}

+(void)uploadImage:(NSString*)url uploadImage:(UIImage *)uploadImage uploadImageName:(NSString *)uploadImageName uploadType:(NSString *)uploadType quality:(float)quality params:(NSMutableDictionary *)params completion:(void(^)(NSDictionary * data))backData failure:(void(^)(NSError * error))failure {
    if (params == nil) {
        params = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    [params setObject:uploadImage forKey:uploadImageName];
    
    //分界线的标识符
    NSString *TWITTERFON_FORM_BOUNDARY = @"Boundary+BD4A5B6B32832B69";
    //根据url初始化request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    //分界线 --AaB03x
    NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
    //结束符 AaB03x--
    NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
    //要上传的图片
    UIImage *image=[params objectForKey:uploadImageName];
    //得到图片的data
    NSData* data;
    if ([uploadType isEqualToString:@"png"]) {
        data = UIImagePNGRepresentation(image);
    }else if ([uploadType isEqualToString:@"jpg"]) {
        data = UIImageJPEGRepresentation(image, quality);
    }else {
        NSAssert(NO, @"uploadType：图片格式传入值错误");
        NSError * error = [NSError errorWithDomain:@"com.ztd.NaHu" code:-789 userInfo:@{@"Failure" : @"传入值错误"}];
        failure(error);
    }
    
    //http body的字符串
    NSMutableString *body=[[NSMutableString alloc]init];
    //参数的集合的所有key的集合
    NSArray *keys= [params allKeys];
    
    //遍历keys
    for(int i = 0; i < [keys count]; i++)
    {
        //得到当前key
        NSString *key = [keys objectAtIndex:i];
        //如果key不是file，说明value是字符类型，比如name：Boris
        if(![key isEqualToString:uploadImageName])
        {
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            //添加字段名称，换2行
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
            //添加字段的值
            [body appendFormat:@"%@\r\n",[params objectForKey:key]];
        }
    }
    
    ////添加分界线，换行
    [body appendFormat:@"%@\r\n",MPboundary];
    //声明file字段，文件名为image.png
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *imageName = [formatter stringFromDate:[NSDate date]];
    [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.png\"\r\n", uploadImageName, imageName];
    //声明上传文件的格式
    [body appendFormat:@"Content-Type: multipart/form-data\r\n\r\n"];
    //声明结束符：--AaB03x--
    NSString *end=[[NSString alloc] initWithFormat:@"\r\n%@",endMPboundary];
    //声明myRequestData，用来放入http body
    NSMutableData *myRequestData = [NSMutableData data];
    //将body字符串转化为UTF8格式的二进制
    [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    //将image的data加入
    [myRequestData appendData:data];
    //加入结束符--AaB03x--
    [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    //设置HTTPHeader中Content-Type的值
    NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
    //设置HTTPHeader
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
    //设置Content-Length
    [request setValue:[NSString stringWithFormat:@"%ld", [myRequestData length]] forHTTPHeaderField:@"Content-Length"];
    //设置http body
    //    [request setHTTPBody:myRequestData];
    //http method
    [request setHTTPMethod:@"POST"];
    
    //    AFHTTPSessionManager * session = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.baidu.com"] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    //    session.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    //    session.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/x-www-form-urlencoded", @"text/html", @"text/json", @"text/javascript", @"text/plain", @"multipart/form-data", nil];
    //    NSURLSessionUploadTask * task = [session uploadTaskWithRequest:request fromData:myRequestData progress:^(NSProgress * _Nonnull uploadProgress) {
    //
    //    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    //        NSDictionary * dic = responseObject;
    //        [MyMBProgressHUD hudForText:dic[@"data"][@"tips"]];
    //        if ([dic[@"data"][@"result"] boolValue]) {
    //            [weakSelf setUserHeadImage:image];
    //        }else {
    ////            [MyMBProgressHUD hudForText:@"修改失败"];
    //        }
    //        NSLog(@"responseObject:%@\n\n---error:%@\n\n----response:%@\n", dic, error, response);
    //    }];
    //    [task resume];
    
    
    NSURLSessionUploadTask * uploadtask = [[BaseURLSession shareSession] uploadTaskWithRequest:request fromData:myRequestData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"response:%@", response);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"error:%@", error);
                if (failure) {
                    failure(error);
                }
            }else {
                NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
                if (backData) {
                    backData(dic);
                }
                NSLog(@"json:%@", dic);
            }
        });
        
    }];
    [uploadtask resume];
    

}

#pragma mark - NSURLSessionDataDelegate

// 只要访问的是HTTPS的路径就会调用
// 该方法的作用就是处理服务器返回的证书, 需要在该方法中告诉系统是否需要安装服务器返回的证书
// NSURLAuthenticationChallenge : 授权质问
//+ 受保护空间
//+ 服务器返回的证书类型
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSLog(@"didReceiveChallenge");
    NSLog(@"%@", challenge.protectionSpace.authenticationMethod);
    
    // 1.从服务器返回的受保护空间中拿到证书的类型
    // 2.判断服务器返回的证书是否是服务器信任的
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"是服务器信任的证书");
        // 3.根据服务器返回的受保护空间创建一个证书
        //         void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *)
        //         代理方法的completionHandler block接收两个参数:
        //         第一个参数: 代表如何处理证书
        //         第二个参数: 代表需要处理哪个证书
        //创建证书
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 4.安装证书
        completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
    }else {
//        [CommonTools showAlertViewTo:[UIApplication sharedApplication].keyWindow title:nil text:@"因为证书无效，无法访问" cancel:0];
        NSLog(@"不是服务器信任的证书");
    }
}

//- (void)URLSession:(NSURLSession *)session
//didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
//{
//    //AFNetworking中的处理方式
//    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
//    __block NSURLCredential *credential = nil;
//    //判断服务器返回的证书是否是服务器信任的
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
//        NSLog(@"是服务器信任的证书");
//        /*disposition：如何处理证书
//         NSURLSessionAuthChallengePerformDefaultHandling:默认方式处理
//         NSURLSessionAuthChallengeUseCredential：使用指定的证书    NSURLSessionAuthChallengeCancelAuthenticationChallenge：取消请求
//         */
//        if (credential) {
//            disposition = NSURLSessionAuthChallengeUseCredential;
//        } else {
//            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
//        }
//    } else {
//        NSLog(@"不是服务器信任的证书");
//        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
//    }
//    //安装证书
//    if (completionHandler) {
//        completionHandler(disposition, credential);
//    }
//}

@end
