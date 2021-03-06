//
//  MUImageCacheManager.m
//  ZPWIM_Example
//
//  Created by Jekity on 2018/7/31.
//  Copyright © 2018年 392071745@qq.com. All rights reserved.
//

#import "MUImageCacheManager.h"
#import "MUImageRenderer.h"
#import "MUImageCacheUtils.h"
#import "MUImageIconCache.h"
#import "MUImageCache.h"
#import "MUImageDataFileManager.h"

@interface MUImageCacheManager()<MUImageRendererDelegate>

@property (nonatomic,strong) NSMutableDictionary  *renderDictionary;
@property (nonatomic,strong) NSMutableDictionary  *iconRenderDictionary;
@end


#define kRenderInfoIndex 0
#define kImageCompletedBlockInfoIndex 1
#define kImagCcornerRadiusInfoIndex 2
@implementation MUImageCacheManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static MUImageCacheManager* __instance;
    dispatch_once(&onceToken, ^{
        __instance = [[[self class] alloc] initWithData];
    });
    
    return __instance;
}
- (instancetype)initWithData{
    if (self = [super init]) {
        _renderDictionary      = [NSMutableDictionary dictionary];
        _iconRenderDictionary      = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)downloadImageWithURL:(NSString *)imageURL drawSize:(CGSize)drawSize cornerRadius:(CGFloat)cornerRadius completed:(MUImageCacheDownloadCompleted)completed{
    
    
    if (!imageURL||imageURL.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:imageURL];
    //    NSLog(@"urlString====%@",imageURL.absoluteString);
    id object = [_renderDictionary valueForKey:url.absoluteString];
    MUImageRenderer *render = nil;
    if (!object) {
        render = [MUImageRenderer new];
        render.delegate = self;
        render.downloading = YES;
        NSMutableArray *completeds = [@[completed] mutableCopy];
        NSMutableArray *info = [@[render,completeds] mutableCopy];
        [_renderDictionary setObject:info forKey:imageURL];
    }else{
        NSMutableArray *info = object;
        render = info[kRenderInfoIndex];
        render.downloading = YES;
        NSMutableArray *complecteds = info[kImageCompletedBlockInfoIndex];
        [complecteds addObject:completed];
    }
    
    [render setPlaceHolderImageName:nil
                        originalURL:url
                           drawSize:drawSize
                    contentsGravity:kCAGravityResizeAspectFill
                       cornerRadius:cornerRadius
     progress:YES
     ];
}

- (void)downloadIconImageWithURL:(NSString *)iconURL drawSize:(CGSize)drawSize completed:(MUImageCacheDownloadCompleted)completed{
    if (!iconURL) {
        return;
    }
    NSURL *url = [NSURL URLWithString:iconURL];
    id object = [_iconRenderDictionary valueForKey:url.absoluteString];
    MUImageRenderer *render = nil;
    if (!object) {
        render = [MUImageRenderer new];
        render.delegate = self;
        render.downloading = YES;
        NSMutableArray *completeds = [@[completed] mutableCopy];
        NSMutableArray *info = [@[render,completeds] mutableCopy];
        [_iconRenderDictionary setObject:info forKey:url.absoluteString];
    }else{
        NSMutableArray *info = object;
        render = info[kRenderInfoIndex];
        render.downloading = YES;
        NSMutableArray *complecteds = info[kImageCompletedBlockInfoIndex];
        [complecteds addObject:completed];
    }
    
    [render setPlaceHolderImageName:nil iconURL:url drawSize:drawSize cornerRadius:0];
}

#pragma mark - MUImageIconRendererDelegate

- (void)MUImageIconRenderer:(MUImageRenderer*)render willRenderImage:(UIImage*)image imageKey:(NSString *)imageKey imageFilePath:(NSString *)imageFilePath{
    
    if (_iconRenderDictionary.allKeys.count > 0&&imageKey&&imageFilePath) {
        id object = [_iconRenderDictionary valueForKey:imageKey];
        if (object) {
            NSMutableArray *info = object;
            NSMutableArray *completeds = info[kImageCompletedBlockInfoIndex];
            for (MUImageCacheDownloadCompleted completed in completeds) {
                completed(imageKey,image,imageFilePath);
            }
            [_iconRenderDictionary removeObjectForKey:imageKey];
        }
        
    }
}

- (void)MUImageRenderer:(MUImageRenderer *)render willRenderImage:(UIImage *)image imageKey:(NSString *)imageKey imageFilePath:(NSString *)imageFilePath{
    
    
    if (_renderDictionary.allKeys.count > 0&&imageKey&&imageFilePath) {
        id object = [_renderDictionary valueForKey:imageKey];
        if (object) {
            NSMutableArray *info = object;
            NSMutableArray *completeds = info[kImageCompletedBlockInfoIndex];
            for (MUImageCacheDownloadCompleted completed in completeds) {
                completed(imageKey,image,imageFilePath);
            }
            [_renderDictionary removeObjectForKey:imageKey];
        }
        
    }
    
}

- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger))block{
    __block NSUInteger size = 0;
    
    [[MUImageCache sharedInstance].dataFileManager calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        size += totalSize;
        if (block) {
            block(size);
        }
    }];
    [[MUImageIconCache sharedInstance].dataFileManager calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        size += totalSize;
        if (block) {
            block(size);
        }
    }];
}

#pragma mark - Get image
- (void)asyncGetImageWithKey:(NSString *)key drawSize:(CGSize)drawSize completed:(MUImageCacheRetrieveBlock)completed{
    [self asyncGetImageWithKey:key drawSize:drawSize cornerRadius:0 completed:completed];
}
- (void)asyncGetImageWithKey:(NSString *)key drawSize:(CGSize)drawSize cornerRadius:(CGFloat)cornerRadius completed:(MUImageCacheRetrieveBlock)completed{
    [[MUImageCache sharedInstance] asyncGetImageWithKey:key drawSize:drawSize contentsGravity:kCAGravityResizeAspectFill cornerRadius:cornerRadius completed:completed];
}

- (void)asyncGetImageWithKey:(NSString *)key completed:(MUImageCacheRetrieveBlock)completed{
    [[MUImageCache sharedInstance] asyncGetImageWithKey:key completed:completed];
}

# pragma mark - Get icon
- (void)asyncGetIconWithKey:(NSString *)key completed:(MUImageCacheRetrieveBlock)completed{
    [[MUImageIconCache sharedInstance] asyncGetImageWithKey:key completed:completed];
}
- (void)clearCache{
    [[MUImageCache sharedInstance] purge];
    [[MUImageIconCache sharedInstance] purge];
}
@end
