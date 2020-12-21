#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "QQAudioSessionManager"
#pragma clang diagnostic pop
//
//  QQAudioSessionManager.m
//  QQMSFContact
//
//  Created by xuepingwu on 17-3-2.
//
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
#import "QQAudioSessionManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIDevice.h>
#import <vector>
#import "AudioRouteMonitor.h"

typedef std::vector<__weak id<QQAudioSessionManagerDelegate>> CategoryModelVectorType;
@interface QQAudioSessionManager ()<AudioRouteChangeProtocol>
{
    CategoryModelVectorType _listeningVector;                             //需要监听的音频集合
    NSMutableSet<AudioCategoryModel*>* _activingSet;                      //正在播放音频的业务集合
    BOOL _isOtherAppNeedRecovery;                                         //第三方声音是否需要恢复
    NSTimeInterval _lastRecoveryOtherAppTime;                             //上次恢复第三方声音的时间
}
@property (nonatomic,assign) BOOL isActived;
@property (atomic,assign) NSTimeInterval lastEnterBackGroundTime;         //上次退后台时间
@end
@implementation QQAudioSessionManager
+(QQAudioSessionManager*)getInstance
{
    static QQAudioSessionManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [QQAudioSessionManager new];
    });
    return instance;
}
#pragma mark 第三方app打断通知
- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = (AVAudioSessionInterruptionType)[[[notification userInfo]
                                                                                        objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (AVAudioSessionInterruptionTypeBegan == interruptionType)
    {
        [self notifyIntterruptBegin];
    }
    else if (AVAudioSessionInterruptionTypeEnded == interruptionType)
    {
        [self notifyIntterruptEnd];
    }
}
- (void)audioSessionMediaServicesWereLostNotification:(NSNotification *)notification
{
    _mediaServicesLostTime = [[NSDate date]timeIntervalSince1970];
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,notification:%s",__FUNCTION__,[[notification description]UTF8String]);
}
- (void)audioSessionMediaServicesWereResetNotification:(NSNotification *)notification
{
    _mediaServicesResetTime = [[NSDate date]timeIntervalSince1970];
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,notification:%s",__FUNCTION__,[[notification description]UTF8String]);
}
#pragma mark 退前后台通知
-(void)willEnterForeground
{
    //到前台时，把_lastEnterBackGroundTime状态清空
    self.lastEnterBackGroundTime = 0;
}
-(void)didEnterBackground
{
    self.lastEnterBackGroundTime = [[NSDate date] timeIntervalSince1970];
    //延迟10s检测app是否还在后台，检测是否可以setActive NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),dispatch_get_global_queue(0, 0), ^{
        [self setAudioSessionInActiveWhenBackground];
    });
}
-(void)setAudioSessionInActiveWhenBackground
{
    //如果退后台时间不够10s，或者当前在前台则直接返回。
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if(now - self.lastEnterBackGroundTime <10 || self.lastEnterBackGroundTime == 0)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,now - self.lastEnterBackGroundTime too short",__FUNCTION__);
        return;
    }
    //如果当前在前台，则直接return
    BOOL applicationActive = ([UIApplication sharedApplication].applicationState == UIApplicationStateActive);
    if(applicationActive)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,appliacationActive",__FUNCTION__);
        return;
    }
    //打断其他声音的播放,除了需要在后台播放声音的业务。
     if(self.interruptOtherAudioWhenBackgroundDpc)
     {
         [self interruptOthers:0 backGroundStrategy:YES];
     }
    //如果当前激活音频有webview，则直接return
    BOOL webViewTop = NO;
    if([self.delegate respondsToSelector:@selector(webViewOnTop)])
    {
        webViewTop = [_delegate webViewOnTop];
    }
    if(webViewTop)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,webViewOnTop",__FUNCTION__);
        return;
    }
    //如果当前音频管理队列为空，则直接setActive NO;
    if([self isAudioSessionIdle])
    {
        if(self.deactiveWhenBackgroundDpc)
        {
            [[AVAudioSession sharedInstance]setActive:NO error:nil];
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,setActive no",__FUNCTION__);
        }
        else
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,deactive dpc off",__FUNCTION__);
        }
    }
    else
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s,self:%s",__FUNCTION__,[[self description] UTF8String]);
    }
}
-(void)dealloc
{
    [[AudioRouteMonitor getInstance] removeListerner:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [_activingSet removeAllObjects];
    _activingSet = nil;
    _listeningVector.clear();
}
-(id)init
{
    if (self = [super init]) {
        _activingSet = [NSMutableSet set];
        _isOtherAppNeedRecovery = NO;
        _lastRecoveryOtherAppTime = 0;
        _mediaServicesLostTime = 0;
        _mediaServicesResetTime = 0;
        _lastEnterBackGroundTime = 0;
        [[AudioRouteMonitor getInstance] addListener:self];
        NSError *err = nil;
        [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&err];
        [self activeAudioSession:YES notifyOther:NO];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionDidChangeInterruptionType:)
                                  name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesWereLostNotification:)
                                  name:AVAudioSessionMediaServicesWereLostNotification object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesWereResetNotification:)
                                  name:AVAudioSessionMediaServicesWereResetNotification object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}
-(BOOL)isAudioSessionActived
{
    return self.isActived;
}
-(BOOL)getOtherAppIsPlayingFlag
{
//    NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
    BOOL isplaying = NO;
    isplaying = [AVAudioSession sharedInstance].secondaryAudioShouldBeSilencedHint;
//    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:isplaying:%d, consume time = %.3f",__FUNCTION__,isplaying,end-begin);
    return isplaying;
}
/*
 插入categoryModel到集合，如果找到同样的obj，则更新，如果没有，则直接插入
 */
-(void)insertAudioCategoryToActivingSet:(AudioCategoryModel *)categoryModel
{
    @synchronized (self) {
        [self removeAudioCategoryFromActivingSet:categoryModel.businessDelegatePtr];
        [_activingSet addObject:categoryModel];
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:insertAudioCategoryToActivingSet:{%s}",__FUNCTION__,categoryModel.description.UTF8String);
    }
}
/*
 移除obj对应的category
 */
-(void)removeAudioCategoryFromActivingSet:(int64_t)objPtr
{
    @synchronized (self) {
        for(AudioCategoryModel *model in _activingSet )
        {
            if(model.businessDelegatePtr == objPtr)
            {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:removeAudioCategoryFromActivingSet:{%s}",__FUNCTION__,model.description.UTF8String);
                [_activingSet removeObject:model]; //不能写成_activingSet.erase(it);
                break;
            }
        }
    }
}
/*
 objPtr查找AudioCategoryModel
 */
-(AudioCategoryModel*)getAudioCategoryFromActivingSet:(int64_t)objPtr
{
    @synchronized (self) {
        for(AudioCategoryModel *model in _activingSet )
        {
            if(model.businessDelegatePtr == objPtr)
            {
                return model;
            }
        }
        return nil;
    }
}
-(QQAVInteruptPriority)getNowInterruptPriority
{
    @synchronized (self) {
        QQAVInteruptPriority maxPriority = QQAVInteruptPriorityPlay;
        for(AudioCategoryModel *model in _activingSet)
        {
            if(maxPriority < model.interruptPriority && model.mix == NO)
            {
                maxPriority = model.interruptPriority;
            }
        }
        return maxPriority;
    }
}
//当前actve集合里有需要静音控制
-(BOOL)hasSilentControllPropertyInActiveSet
{
    @synchronized (self) {
        BOOL ret = NO;
        for(AudioCategoryModel *model in _activingSet)
        {
            BOOL needRecoveryBusiInterrupting = (model.needRecovery && [model isInterrupting]);
            if(needRecoveryBusiInterrupting)
                continue;
            if(model.silentControll == QQAVSilentCategoryControll)
            {
                ret = YES;
                break;
            }
        }
        return ret;
    }
}
//当前actve集合里有非混合音频行为
-(BOOL)hasInterruptPropertyInActiveSet
{
    @synchronized (self) {
        BOOL ret = NO;
        for(AudioCategoryModel *model in _activingSet)
        {
            BOOL needRecoveryBusiInterrupting = (model.needRecovery && [model isInterrupting]);
            if(needRecoveryBusiInterrupting)
                continue;
            if(!model.mix)
            {
                ret = YES;
                break;
            }
        }
        return ret;
    }
}
-(BOOL)audioCategorySetContains:(int64_t)objPtr
{
    @synchronized (self) {
        BOOL ret = NO;
        for(AudioCategoryModel *model in _activingSet)
        {
            if(model.businessDelegatePtr == objPtr)
            {
                ret = YES;
                break;
            }
        }
        return ret;
    }
}
//标记obj正在被打断
-(void)setInterruptState:(int64_t)objPtr interrupt:(QQInterruptStateCategory)interruptState
{
    @synchronized (self) {
        for(AudioCategoryModel *model in _activingSet)
        {
            if(model.businessDelegatePtr == objPtr)
            {
                [model setInterruptState:interruptState];
                break;
            }
        }
    }
}
-(BOOL)isInterruptState:(int64_t)objPtr
{
    @synchronized (self) {
        BOOL ret = NO;
        for(AudioCategoryModel *model in _activingSet)
        {
            if(model.businessDelegatePtr == objPtr)
            {
                ret = [model isInterrupting];
                break;
            }
        }
        return ret;
    }
}
-(BOOL)hasVoiceOnly
{
    @synchronized (self) {
        BOOL ret = YES;
        for(AudioCategoryModel *model in _activingSet)
        {
            if(!model.bVoice)
            {
                ret = NO;
                break;
            }
        }
        return ret;
    }
}
//是否需要切换听筒扬声器模式
-(BOOL)needChangeAudioRoute
{
    @synchronized (self) {
        if(_activingSet.count == 0)
            return NO;
        BOOL ret = YES;
        for(AudioCategoryModel *model in _activingSet)
        {
            if([model isInterrupting])
            {
                continue;
            }
            if(!model.autoEarPhoneSwitchSpeakerAndReceive)
            {
                ret = NO;
                break;
            }
        }
        return ret;
    }
}
-(void)checkActiveAndListeningSet
{
    @synchronized (self) {
        NSMutableArray *needRemovedArr = [NSMutableArray array];
        for(AudioCategoryModel *itModel in _activingSet)
        {
            int64_t businessDelegatePtr = itModel.businessDelegatePtr;
            if(businessDelegatePtr && !itModel.businessDelegate)
            {
                [needRemovedArr addObject:itModel];
            }
        }
        
        //如果当前激活的业务的delegate指针非空但是delegate为空，主干版本crash，发布版本remove
        for (AudioCategoryModel *itNeedRemoveModel in needRemovedArr) {
            int64_t businessDelegatePtr = itNeedRemoveModel.businessDelegatePtr;
//            NSString *businessName = [itNeedRemoveModel.businessName copy];
            [self removeRecoveryListener:businessDelegatePtr];
            [self removeAudioCategoryFromActivingSet:businessDelegatePtr];
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:remove object from active and listening set,0x%llx",__FUNCTION__,businessDelegatePtr);
#if !GRAY_OR_APPSTORE
            {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:itModel.businessDelegate(0x%llx) businessName(%s) 被释放时没有deative",__FUNCTION__,businessDelegatePtr,businessName.UTF8String);
//                assert(0);// 请看上一条日志，并检查itModel.businessDelegate对象有没有在析构时调用deactive方法。或者把日志发给xuepingwu.
            }
#endif
        }
        
        for(AudioCategoryModel *itModel in _activingSet)
        {
            if(itModel.interruptPriority == QQAVInteruptPriorityChat)
            {
//                BOOL isChatting = [[serviceFactoryInstance() getGroupAudioChatService] InOneGroup]|| [[serviceFactoryInstance() getVideoChatService] IsVideoChat];
//                if(!isChatting)
//                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s: 没有在音视频通话中,但还存在队列中，业务检查是否有调用endCall",__FUNCTION__);
//#ifdef DEBUG
//                    assert(0);//没有在音视频通话中,但还存在队列中，业务检查是否有调用endCall
//#endif
//                    continue;
//                }
            }
        }
    }
}
//是否需要恢复其他业务，如果当前激活的业务有不需要恢复的或者不在恢复列表的，则不用恢复
-(BOOL)needRecovery
{
    @synchronized (self) {
        if(_activingSet.count==0)
            return NO;
        BOOL ret = YES;
        for(AudioCategoryModel *itModel in _activingSet)
        {
            //如果当前激活的业务有不需要恢复的，则不用恢复
            if(!itModel.needRecovery)
            {
                ret = NO;
                break;
            }
            //不在恢复列表的，则不用恢复
            BOOL exist = NO;
            for(CategoryModelVectorType::iterator it=_listeningVector.begin(); it!=_listeningVector.end();it++)
            {
                if((int64_t)*it == itModel.businessDelegatePtr)
                {
                    exist = YES;
                    break;
                }
            }
            if(!exist)
            {
                ret = NO;
                break;
            }
        }
        return ret;
    }
}
//是否允许激活，是否允许设置音频行为
-(BOOL)canActiveOrSetCategory:(AudioCategoryModel*)categoryModel;
{
    @synchronized (self) {
        BOOL ret = NO;
        if (categoryModel.interruptPriority < [self getNowInterruptPriority])
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:requestDevice_error, priority is lower then now.self:{%s}",__FUNCTION__,self.description.UTF8String);
            ret = NO;
        }
        else
        {
            ret = YES;
        }
        return ret;
    }
}
#pragma mark 需要打断的,不要打断的都要调用此函数，首先必须获取权限,然后激活audiosession
-(BOOL)requestDeviceWithModel:(AudioCategoryModel*)categoryModel
{
    @synchronized(self)
    {
        BOOL ret = [self canActiveOrSetCategory:categoryModel];
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s: businessDelegate:%s, actived count:%ld,ret=%d",__FUNCTION__,categoryModel.businessDelegate.description.UTF8String, (unsigned long)_activingSet.count,ret);
        return ret;
    }
}
//打断其他业务
- (void)interruptOthers:(int64_t)currentObjPtr  backGroundStrategy:(BOOL)backGroundStrategy
{
    @synchronized(self)
    {
        for(AudioCategoryModel *itModel in _activingSet)
        {
            int64_t localVarPtr = itModel.businessDelegatePtr;
            if (localVarPtr == currentObjPtr)
                continue;
            //如果是退后台时的打断,不打断能在后台播放的业务
            if(backGroundStrategy && itModel.canBackground)
            {
                continue;
            }
            if ([itModel.businessDelegate respondsToSelector:@selector(onAudioSessionActive)] &&![self isInterruptState:localVarPtr])
            {
                if(itModel.needRecovery)
                {
                    [self addRecoveryListener:itModel.businessDelegate];
                }
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s: interrupt obj:{%s}",__FUNCTION__,itModel.description.UTF8String);
                [(NSObject*)itModel.businessDelegate performSelectorOnMainThread:@selector(onAudioSessionActive) withObject:nil waitUntilDone:NO];
                [self setInterruptState:localVarPtr interrupt:QQInterruptByInner];
            }
        }
    }
}
//恢复其他业务
-(void)recoveryOthers:(int64_t)currentObjPtr
{
    @synchronized(self)
    {
        CategoryModelVectorType cpvector = _listeningVector;
        //因为恢复只是恢复最后一个，所以倒序遍历
        for (long i = cpvector.size()-1; i >= 0; i--)
        {
            NSObject* localVar = (NSObject*)cpvector.at(i);
            int64_t localVarPtr = (int64_t)localVar;
            if (localVarPtr == currentObjPtr)
                continue;
            AudioCategoryModel* categoryModel = [self getAudioCategoryFromActivingSet:localVarPtr];
            if ([localVar respondsToSelector:@selector(onAudioSessionDeactive)] && categoryModel.interruptState == QQInterruptByInner)
            {
                //这里恢复其他业务的播放，仅恢复一个。
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s: recovery obj:%s",__FUNCTION__,localVar.description.UTF8String);
                [localVar performSelectorOnMainThread:@selector(onAudioSessionDeactive) withObject:nil waitUntilDone:NO];
                [self setInterruptState:localVarPtr interrupt:QQInterruptNone];
                break;
            }
        }
    }
}
- (void)notifyActive:(BOOL)active currentObjPtr:(int64_t)currentObjPtr
{
    @synchronized(self)
    {
        //active = YES,打断active集合里的所有业务音频；active = NO,恢复listening数组里最后一个音频业务。
        if(active)
        {
            [self interruptOthers:currentObjPtr backGroundStrategy:NO];
        }
        else
        {
            [self recoveryOthers:currentObjPtr];
        }
    }
}
-(BOOL)active:(AudioCategoryModel*)categoryModel
{
    @synchronized(self)
    {
        BOOL success = YES;
        success = [self activeAudioSession:YES notifyOther:NO];
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:success:%d",__FUNCTION__,success);
        if(success)
        {
            if (categoryModel.businessDelegate)
            {
                //非混合模式才需要打断其他业务
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:categoryModel:{%s}",__FUNCTION__,categoryModel.description.UTF8String);
                if(categoryModel.canInterrptOthers)
                {
                    [self notifyActive:YES currentObjPtr:categoryModel.businessDelegatePtr];
                }
                [self insertAudioCategoryToActivingSet:categoryModel];
            }
        }
        return success;
    }
}
//外部调用
-(void)deactive:(id<QQAudioSessionManagerDelegate>)obj delay:(BOOL)delay notifyOtherApp:(BOOL)notifyOtherApp
{
    @synchronized(self)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:deactive:%s, actived set:%s,delay:%d,notifyOtherApp:%d", __FUNCTION__,[(NSObject*)obj description].UTF8String,_activingSet.description.UTF8String,delay,notifyOtherApp);
        
        int64_t objPtr = (int64_t)obj;
        
        if (!obj || [self audioCategorySetContains:objPtr])
        {
            BOOL resetAudioSessionCategory = ![self getAudioCategoryFromActivingSet:objPtr].keepAudioSessionCategoryWhenDeativeWithSystem;
            [self removeRecoveryListener:objPtr];
            [self removeAudioCategoryFromActivingSet:objPtr];
            [self checkActiveAndListeningSet];
            if(delay)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),dispatch_get_global_queue(0, 0), ^{
                    if ([self needRecovery]) { //当有一个actived的对象不需要恢复，则等待
                        [self notifyActive:NO currentObjPtr:objPtr];
                    }
                    [self deactiveWithSystem:notifyOtherApp resetAudioSessionCategory:resetAudioSessionCategory];
                });
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if ([self needRecovery]) { //当有一个actived的对象不需要恢复，则等待
                        [self notifyActive:NO currentObjPtr:objPtr];
                    }
                    [self deactiveWithSystem:notifyOtherApp resetAudioSessionCategory:resetAudioSessionCategory];
                });
            }
        }
    }
}
-(void)deactiveWithSystem:(BOOL)notifyOtherApp resetAudioSessionCategory:(BOOL)resetAudioSessionCategory
{
    @synchronized(self)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:self={%s}", __FUNCTION__,self.description.UTF8String);
        if ([self isAudioSessionIdle])
        {
            if(resetAudioSessionCategory)
            {
                NSError *err = nil;
                [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&err];
            }
            else
            {
                [[AudioRouteMonitor getInstance]setAudioSessionMix:YES];
                [[AudioRouteMonitor getInstance]autoSwitchAudioOutputRouteForVoice];
            }
            
            if(notifyOtherApp && _isOtherAppNeedRecovery)
            {
//                BOOL ret = [self activeAudioSession:NO notifyOther:YES];
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:ret=%d",__FUNCTION__,ret);
                [self activeAudioSession:NO notifyOther:YES];
                _isOtherAppNeedRecovery = NO;
                _lastRecoveryOtherAppTime = [[NSDate date] timeIntervalSince1970];
            }
            if(!self.isActived)
            {
//                BOOL success = [self activeAudioSession:YES notifyOther:NO];
                [self activeAudioSession:YES notifyOther:NO];
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:success=%d",__FUNCTION__,success);
            }
        }
    }
}
#pragma mark - 监听内部打断和恢复
-(void)addRecoveryListener:(__weak id<QQAudioSessionManagerDelegate>)obj
{
    @synchronized(self)
    {
        [self removeRecoveryListener:(int64_t)obj];
        if (obj)
        {
            _listeningVector.push_back(obj);
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:add listenner:%s",__FUNCTION__,obj.description.UTF8String);
        }
    }
}
-(void) removeRecoveryListener:(int64_t)objPtr
{
    @synchronized(self)
    {
        if (objPtr)
        {
            for(CategoryModelVectorType::iterator it=_listeningVector.begin(); it!=_listeningVector.end();)
            {
                if((int64_t)*it == objPtr)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:remove listenner:%s",__FUNCTION__,[(NSObject*)*it description].UTF8String);
                    it = _listeningVector.erase(it); //不能写成arr.erase(it);
                }
                else
                {
                    ++it;
                }
            }
        }
    }
}
#pragma mark - 处理与第三方app打断和恢复的通知
-(void)notifyIntterruptBegin
{
    @synchronized (self) {
        self.isActived = NO;
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s",__FUNCTION__);
        for(AudioCategoryModel *itModel in _activingSet)
        {
            NSObject* localVar = itModel.businessDelegate;
            int64_t localVarPtr = itModel.businessDelegatePtr;
            if ([localVar respondsToSelector:@selector(onIntterruptBegin)] && ![self isInterruptState:localVarPtr])
            {
                __weak NSObject* busiNessObj = localVar;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
                    [busiNessObj performSelector:@selector(onIntterruptBegin)];
                    [self setInterruptState:localVarPtr interrupt:QQInterruptByOuter];
                    if(itModel.needRecovery)
                    {
                        [self addRecoveryListener:itModel.businessDelegate];
                    }
                });
            }
        }
    }
}
-(void)notifyIntterruptEnd
{
    @synchronized (self) {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s",__FUNCTION__);
        CategoryModelVectorType cpvector = _listeningVector;
        for (long i = cpvector.size()-1; i >= 0; i--)
        {
            NSObject* localVar = (NSObject*)cpvector.at(i);
            int64_t localVarPtr = (int64_t)localVar;
            AudioCategoryModel* categoryModel = [self getAudioCategoryFromActivingSet:localVarPtr];
            if ([localVar respondsToSelector:@selector(onIntterruptEnd)] && categoryModel.interruptState == QQInterruptByOuter)
            {
                //这里恢复其他业务的播放
                __weak NSObject* busiNessObj = localVar;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
                    [busiNessObj performSelector:@selector(onIntterruptEnd)];
                });
                [self setInterruptState:localVarPtr interrupt:QQInterruptNone];
            }
        }
    }
}
/*
参见 enum QQAudioSessionCategory
 */
NSString * const ActiveCategoryModelErrorDomain = @"com.tencent.audioSessionManager.error";
#pragma mark 激活audiosession，打断别人，把自己加入队列，并且设置音频行为
-(BOOL)activeCategoryModel:(AudioCategoryModel*)categoryModel error:(NSError **)error
{
    @synchronized (self) {
        BOOL ret = [self canActiveOrSetCategory:categoryModel];
        if(!ret)
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:canActiveOrSetCategory = NO",__FUNCTION__);
            if(error)
            {
               *error = [[NSError alloc] initWithDomain:ActiveCategoryModelErrorDomain code:ACTICE_CATEGORY_MODEL_ERROR_CODE_LOW_PRIORITY userInfo:nil];
            }
            return NO;
        }
        else
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:begin categoryModel:{%s},\nself:{%s}",__FUNCTION__,categoryModel.description.UTF8String,self.description.UTF8String);
        
            //_isOtherAppNeedRecovery赋值
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if(now-_lastRecoveryOtherAppTime<=2)
            {
                _isOtherAppNeedRecovery = YES;
            }
            if(!_isOtherAppNeedRecovery)
            {
                if(NO == categoryModel.mix)
                {
                    _isOtherAppNeedRecovery = [self getOtherAppIsPlayingFlag];
                }
            }
            
            NSError *categoryError = nil;
            //打断的audioSession比较好设置。混合的需要根据当前activingSet的元素来设置
            switch (categoryModel.qAudioSessionCategory) {
                case QQAudioSessionPlayMusicSolo:
                case QQAudioSessionPlayVideoSolo:
                {
                    [[AudioRouteMonitor getInstance]setPlaybackCategory:&categoryError];
                }
                    break;
                case QQAudioSessionPlayVoiceSpeaker:
                {
                    [[AudioRouteMonitor getInstance]overrideAudioRouteToSpeaker];
                    [[AudioRouteMonitor getInstance]setPlaybackCategory:&categoryError];
                }
                    break;
                case QQAudioSessionPlayMusicSoloAmbient:
                case QQAudioSessionPlayVoiceSoloAmbient:
                    [[AudioRouteMonitor getInstance]setSoloAmbientCategory:&categoryError];
                    break;
                case QQAudioSessionPlayVoiceReceiver:
                {
                    [[AudioRouteMonitor getInstance]setPlayAndRecordCategory:&categoryError];
                    [[AudioRouteMonitor getInstance]setVoiceChatMode];
                    [[AudioRouteMonitor getInstance]overrideAudioRouteToNormal];
                }
                    break;
                case QQAudioSessionPlayAndRecordVideoSolo:
                {
                    [[AudioRouteMonitor getInstance]setPlayAndRecordCategory:&categoryError];
                    [[AudioRouteMonitor getInstance]setDefaultMode];
                }
                    break;
                case QQAudioSessionRecordVoice:
                {
                    [[AudioRouteMonitor getInstance]setRecordAudioCategory:&categoryError];
                    [[AudioRouteMonitor getInstance]setDefaultMode];
                }
                    break;
                    //混合播放场景
                case QQAudioSessionPlayMusicMix:
                {
                    [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&categoryError];
                }
                    break;
                    //静音播放视频，根据当前activingSet的元素来设置
                case QQAudioSessionPlayVideoMixMute:
                {
                    if([self hasInterruptPropertyInActiveSet])
                    {
                        if([self hasSilentControllPropertyInActiveSet])
                        {
                            [[AudioRouteMonitor getInstance]setSoloAmbientCategory:&categoryError];
                        }
                        else if([AVAudioSession sharedInstance].category == AVAudioSessionCategoryPlayAndRecord)
                        {
                            [[AudioRouteMonitor getInstance]setPlayAndRecordCategory:&categoryError];
                        }
                        else if([AVAudioSession sharedInstance].category == AVAudioSessionCategoryAmbient)
                        {
                            [[AudioRouteMonitor getInstance]setSoloAmbientCategory:&categoryError];
                        }
                        else
                        {
                            [[AudioRouteMonitor getInstance]setPlaybackCategory:&categoryError];
                        }
                        
                    }
                    else
                    {
                        if([self hasSilentControllPropertyInActiveSet])
                        {
                            [[AudioRouteMonitor getInstance]setAmbientCategory:&categoryError];
                        }
                        else if([AVAudioSession sharedInstance].category == AVAudioSessionCategoryPlayAndRecord)
                        {
                            [[AudioRouteMonitor getInstance]setPlayAndRecordCategoryMix:&categoryError];
                        }
                        else if([AVAudioSession sharedInstance].category == AVAudioSessionCategoryAmbient)
                        {
                            [[AudioRouteMonitor getInstance]setAmbientCategory:&categoryError];
                        }
                        else
                        {
                            [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&categoryError];
                        }
                    }
                }
                    break;
                case QQAudioSessionPlayAudioBackGroundMixMute:
                {
                    if([self isAudioSessionIdle])
                    {
                        [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&categoryError];
                    }
                }
                    break;
                case QQAudioSessionWebView:
                {
                    if([self isAudioSessionIdle])
                    {
                        BOOL nowPlayAndRecord = ([AVAudioSession sharedInstance].category == AVAudioSessionCategoryPlayAndRecord);
                        BOOL isOtherAppPlaying = [self getOtherAppIsPlayingFlag];
                        if([self hasSilentControllPropertyInActiveSet])
                        {
                            [[AudioRouteMonitor getInstance]setAmbientCategory:&categoryError];
                        }
                        else
                        {
                            [[AudioRouteMonitor getInstance]setPlaybackCategoryMix:&categoryError];
                        }
                        if(nowPlayAndRecord && isOtherAppPlaying)
                        {
                            [self activeAudioSession:NO notifyOther:YES];
                        }
                    }
                }
                    break;
                case QQAudioSessionPlayAndRecordVideoMixSpeaker:
                {
                    BOOL nowPlayAndRecord = ([AVAudioSession sharedInstance].category == AVAudioSessionCategoryPlayAndRecord);
                    [[AudioRouteMonitor getInstance]setPlayAndRecordCategoryMix:&categoryError];
                    [[AudioRouteMonitor getInstance]setDefaultMode];
                    if(!nowPlayAndRecord)
                    {
                        [self activeAudioSession:NO notifyOther:YES];
                    }
                }
                    break;
                case QQAudioSessionAVChat:
                {
                    [[AudioRouteMonitor getInstance]setPlayAndRecordCategoryChat:&categoryError];
                    [[AudioRouteMonitor getInstance]setDefaultMode];
                }
                    break;
                default:
                {
                    ret = NO;
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:unkown category!!!",__FUNCTION__);
                    categoryError = [[NSError alloc] initWithDomain:ActiveCategoryModelErrorDomain code:ACTICE_CATEGORY_MODEL_ERROR_INVALID_CATRGORY userInfo:nil];
                }
                    break;
            }
            if(categoryError)
            {
                if(error)
                {
                    *error = [categoryError copy];
                }
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:SetCategory error!!!,%s",__FUNCTION__,[[categoryError description]UTF8String]);
                // assert(0);
                return NO;
            }
            //AVAudioSession激活，中断其他业务，如果非混合加入active队列
            ret = [self active:categoryModel];
            if(!ret)
            {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:setActive Fail!!!",__FUNCTION__);
                return NO;
            }
            //切换声音输出
            [self checkAudioRoute:categoryModel];
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:end self:{%s}",__FUNCTION__,self.description.UTF8String);
        }
        return ret;
    }
}
-(void)checkAudioRoute:(AudioCategoryModel*)categoryModel
{
    [self onOutputDeviceChanged:0];
}
-(void)onOutputDeviceChanged:(int)currentType
{
    @synchronized (self) {
        if([self isAudioSessionIdle] || [self needChangeAudioRoute])
        {
            [[AudioRouteMonitor getInstance]autoSwitchAudioOutputRouteForVoice];
        }
    }
}
-(BOOL)activeAudioSession:(BOOL)active notifyOther:(BOOL)notifyOther
{
    @synchronized (self) {
        BOOL success = YES;
        if(active)
        {
            if(self.isActived == active)
            {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s: Audio session already active.",__FUNCTION__);
                return success;
            }
            NSError *error = nil;
            [[AVAudioSession sharedInstance]setActive:YES error:&error];
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Active Audio session with system.",__FUNCTION__);
            if (error) {
                self.isActived = NO;
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Active AudioSession failed.With error = %s",__FUNCTION__, error.description.UTF8String);
                //                    assert(0);
                success = NO;
            } else {
                self.isActived = YES;
            }
        }
        else
        {
            NSError *error = nil;
            BOOL ret = YES;
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:DeActive Audio session with system.",__FUNCTION__);
            if(notifyOther)
            {
                ret = [[AVAudioSession sharedInstance]setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
            }
            else
            {
                ret = [[AVAudioSession sharedInstance]setActive:NO withOptions:0 error:&error];
            }
            
            if(error)
            {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:AVAudioSession setActive= NO error = %s ret = %d",__FUNCTION__, error.description.UTF8String,ret);
                //                    assert(0);
                success = NO;
                self.isActived = NO;
            }
            else
            {
                self.isActived = NO;
            }
        }
        return success;
    }
}
-(BOOL)isAudioSessionIdle
{
    @synchronized (self) {
        BOOL idle = NO;
        if(_activingSet.count == 0)
        {
            idle = YES;
        }
        else
        {
            idle = YES;
            for(AudioCategoryModel *model in _activingSet)
            {
                BOOL needRecoveryBusiInterrupting = (model.needRecovery && [model isInterrupting]);
                if(needRecoveryBusiInterrupting)
                {
                    continue;
                }
                else
                {
                    idle = NO;
                    break;
                }
            }
        }
        return idle;
    }
}
-(NSString*)description
{
    NSString *string = [NSString stringWithFormat:@"current category:%s,categoryOptions:%ld,activingSet:%s,listening:%ld,actived:%d",
                        [AVAudioSession sharedInstance].category.UTF8String,(unsigned long)[AVAudioSession sharedInstance].categoryOptions,_activingSet.description.UTF8String,_listeningVector.size(),_isActived];
    return string;
}
@end
