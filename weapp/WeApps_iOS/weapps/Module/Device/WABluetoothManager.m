//
//  WABluetoothManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WABluetoothManager.h"
#import <objc/runtime.h>
#import "WACallbackModel.h"
#import "NSData+Base64.h"
#import "IdGenerator.h"

/**
******** 外设(CBPeripheral)、服务(CBService)、特征(CBCharacteristic)间的关系 ********
*
*  CBPeripheral
*       |
*       |
*       | ----- CBService
*       |           |
*       |           |
*       |           | ---- CBCharacteristic
*       |           |
*       |           |
*       |           | ---- CBCharacteristic
*       |           |             .
*       |                         .
*       |                         .
*       | ----- CBService
*       |           .
*       |           .
*       |           .
*
------------------------------- 这里应该要有一条华丽的分割线 -------------------------------
*
******** 蓝牙中心模式流程（以app作为中心，连接外设）********
* 1. 建立中心角色CBCentralManager
* 2. 扫描外设(discover)
* 3. 连接外设(connect)
* 4. 扫描外设中的服务和特征(discover)
*  - 4.1 获取外设服务(services)
*  - 4.2 连接外设的特征(characteristics)
* 5.与外设做数据交互(explore and interact)
* 6. 订阅characteristics通知(用于读取动态变化数据)
* 7. 断开连接(disconnect)
*/

#define kRequestCallbackId @"requestCallbackId"

typedef enum : NSUInteger {
    WABlueToothErrorCodeSuccess = 0,                  // 成功
    WABlueToothErrorCodeAlreadyConnect = 1,           // 已连接
    WABlueToothErrorCodeNotInit = 10000,              // 未初始化蓝牙适配器
    WABlueToothErrorCodeNotAvailable = 10001,         // 当前蓝牙适配器不可用
    WABlueToothErrorCodeNoDevice = 10002,             // 没有找到指定设备
    WABlueToothErrorCodeConnectionFailed = 10003,     // 连接失败
    WABlueToothErrorCodeNoService = 10004,            // 没有找到指定服务
    WABlueToothErrorCodeNoCharacteristic = 10005,     // 没有找到指定特征值
    WABlueToothErrorCodeNoConnection = 10006,         // 当前连接已断开
    WABlueToothErrorCodePropertyNotSupported = 10007, // 当前特征值不支持此操作
    WABlueToothErrorCodeSystemError = 10008,          // 其余所有系统上报的异常
    WABlueToothErrorCodeSystemNotSupport = 10009,     // Android 系统特有，系统版本低于 4.3 不支持BLE
    WABlueToothErrorCodeNoDescriptor = 10010,         // 没有找到指定描述符
    WABlueToothErrorCodeOperateTimeOut = 10012,       // 连接超时
    WABlueToothErrorCodeInvalidData = 10013,          // 连接 deviceId 为空或者是格式不正确

} WABlueToothErrorCode; // 蓝牙错误码 参考（https://mp.weixin.qq.com/debug/wxadoc/dev/api/bluetooth.html#蓝牙错误码errcode列表）

#ifndef WABlueToothTimeOut
#define WABlueToothTimeOut 15 // 默认超时为15秒
#endif

@interface WABlueToothDevice : NSObject
@property (nonatomic, copy) NSString *name; // 蓝牙设备名称，某些设备可能没有
@property (nonatomic, copy) NSString *deviceId; // 用于区分设备的 id
@property (nonatomic, assign) int RSSI; // 当前蓝牙设备的信号强度
@property (nonatomic, copy) NSString *advertisData; // 蓝牙设备的广播数据段中的 ManufacturerData 数据段(Base64编码)
@property (nonatomic, copy) NSDictionary *serviceData; //蓝牙设备的广播数据段中的 ServiceData 数据段
@property (nonatomic, copy) NSArray *advertisServiceUUIDs; //前蓝牙设备的广播数据段中的 ServiceUUIDs 数据段
@property (nonatomic, copy) NSString *localName; //蓝牙设备的广播数据段中的 LocalName 数据段
@end

@implementation WABlueToothDevice

@end

@interface WABlueToothService : NSObject
@property (nonatomic, copy) NSString *uuid; // 蓝牙设备服务的 uuid
@property (nonatomic, assign) BOOL isPrimary; // 该服务是否为主服务

@end

@implementation WABlueToothService
@end

@interface WABlueToothProperties : NSObject
@property (nonatomic, assign) BOOL read; // 是否支持 read 操作
@property (nonatomic, assign) BOOL write; // 是否支持 write 操作
@property (nonatomic, assign) BOOL notify; // 是否支持 notify 操作
@property (nonatomic, assign) BOOL indicate; // 是否支持 indicate 操作
@end

@implementation WABlueToothProperties

@end


@interface WABlueToothCharacteristic : NSObject
@property (nonatomic, copy) NSString *uuid; // 蓝牙设备特征值的 uuid
@property (nonatomic, copy) NSString *serviceUUID; // 蓝牙设备特征值对应服务的 uuid
@property (nonatomic, copy) NSString *value; // 蓝牙设备特征值对应的值(Base64编码)
@property (nonatomic, strong) WABlueToothProperties *properties; // 该特征值支持的操作类型

@end

@implementation WABlueToothCharacteristic
@end

@interface WABlueToothCentralModel : WACallbackModel

@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *bluetoothDeviceFoundCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *bluetoothAdapterStateChangeCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *BLEConnectionStateChangeCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *BLECharacteristicValueChangeCallbackDict;

@end

@implementation WABlueToothCentralModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bluetoothDeviceFoundCallbackDict = [NSMutableDictionary dictionary];
        _bluetoothAdapterStateChangeCallbackDict = [NSMutableDictionary dictionary];
        _BLEConnectionStateChangeCallbackDict = [NSMutableDictionary dictionary];
        _BLECharacteristicValueChangeCallbackDict = [NSMutableDictionary dictionary];
    }
    return self;
}

@end

typedef NS_ENUM(NSUInteger, CBATTRequestType) {
    CBATTRequestTypeRead,
    CBATTRequestTypeWrite,
};

@interface CBATTTypeRequest : NSObject

@property (nonatomic, assign) CBATTRequestType type;
@property (nonatomic, strong, readonly) CBATTRequest *request;

- (instancetype)initWithRequest:(CBATTRequest *)request andType:(CBATTRequestType)type;

@end

@implementation CBATTTypeRequest

- (instancetype)initWithRequest:(CBATTRequest *)request andType:(CBATTRequestType)type
{
    self = [super init];
    if (self) {
        _request = request;
        _type = type;
    }
    return self;
}

@end

@interface WABlueToothPeripheralModel : WACallbackModel <CBPeripheralManagerDelegate>

@property (nonatomic, strong, readonly) CBPeripheralManager *manager;
@property (nonatomic, assign, readonly) NSUInteger peripheralModelId;
@property (nonatomic, strong) NSMutableArray *addedServices;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *BLEPeripheralConnectionStateChangedCallbacks;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *characteristicReadRequestCallbacks;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *characteristicWriteRequestCallbacks;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *characteristicSubscribedCallbacks;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> *characteristicUnsubscribedCallbacks;
@property (nonatomic, strong) NSMutableDictionary *tempCallbacks;
@property (nonatomic, strong) NSMutableDictionary *requestDict;
@property (nonatomic, strong) NSMutableArray *subscribedCharacteristics;
@property (nonatomic, strong) NSMutableDictionary *subscribedCentral;
- (void)close;

- (void)addService:(CBMutableService *)service withCompletionHandler:(WABlueToothCompletionHandler)completionHandler;

- (void)removeService:(NSString *)serviceId
withCompletionHandler:(WABlueToothCompletionHandler)completionHandler;

- (void)BLEPeripheralServerStartAdvertising:(NSDictionary *)advertisementData
                      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

- (void)BLEPeripheralServerStopAdvertising;

- (void)BLEPeripheralServerWriteCharacteristicValue:(NSString *)value
                                           toSevice:(NSString *)serviceId
                                 withCharacteristic:(NSString *)characteristicId
                                         needNotify:(BOOL)needNotify
                                           callback:(NSNumber *)callbackId
                                  completionHandler:(WABlueToothCompletionHandler)completionHandler;

- (void)webView:(WebView *)webView onCharacteristicReadRequestCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCharacteristicReadRequestCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onCharacteristicWriteRequestCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCharacteristicWriteRequestCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onCharacteristicSubscribedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCharacteristicSubscribedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onCharacteristicUnsubscribedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCharacteristicUnsubscribedCallback:(NSString *)callback;
@end

@implementation WABlueToothPeripheralModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CBPeripheralManager alloc] init];
        _manager.delegate = self;
        _peripheralModelId = [IdGenerator generateIdWithClass:[self class]];
        _BLEPeripheralConnectionStateChangedCallbacks = [NSMutableDictionary dictionary];
        _characteristicReadRequestCallbacks = [NSMutableDictionary dictionary];
        _characteristicWriteRequestCallbacks = [NSMutableDictionary dictionary];
        _characteristicUnsubscribedCallbacks = [NSMutableDictionary dictionary];
        _characteristicSubscribedCallbacks = [NSMutableDictionary dictionary];
        _tempCallbacks = [NSMutableDictionary dictionary];
        _requestDict = [NSMutableDictionary dictionary];
        _subscribedCharacteristics = [NSMutableArray array];
        _subscribedCentral = [NSMutableDictionary dictionary];
        _addedServices = [NSMutableArray array];
    }
    return self;
}

- (void)close
{
    if ([_manager isAdvertising]) {
        [_manager stopAdvertising];
    }
    [_manager removeAllServices];
}

- (void)addService:(CBMutableService *)service withCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (!service) {
        return;
    }
    [self.tempCallbacks setObject:completionHandler forKey:[NSString stringWithFormat:@"addServiceUUID%@",service.UUID]];
    [self.manager addService:service];
}

- (void)removeService:(NSString *)serviceId
withCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    
    for (CBMutableService *service in _addedServices) {
        if ([service.UUID.UUIDString isEqualToString:serviceId]) {
            [self.manager removeService:service];
            if (completionHandler) {
                completionHandler(YES, nil, nil);
            }
            return;
        }
    }
    if (completionHandler) {
        completionHandler(NO, nil,  [NSError errorWithDomain:@"removeService" code:WABlueToothErrorCodeNoCharacteristic userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find service with serviceId :{%@}", serviceId]
        }]);
    }
    
}


- (void)BLEPeripheralServerStartAdvertising:(NSDictionary *)advertisementData
                      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    [self.tempCallbacks setObject:completionHandler forKey:@"startAdvertising"];
    [self.manager startAdvertising:advertisementData];
}

- (void)BLEPeripheralServerStopAdvertising
{
    [self.manager stopAdvertising];
}

- (void)BLEPeripheralServerWriteCharacteristicValue:(NSString *)value
                                           toSevice:(NSString *)serviceId
                                 withCharacteristic:(NSString *)characteristicId
                                         needNotify:(BOOL)needNotify
                                           callback:(NSNumber *)callbackId
                                  completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    CBATTTypeRequest *request = nil;
    if (callbackId) {
        request = _requestDict[callbackId];
        if (request && request.type == CBATTRequestTypeRead && request.request.characteristic.properties & CBCharacteristicPropertyRead) {
            //central读请求，回应central读请求并把数据传给central
            request.request.value = [NSData dataWithBase64String:value];
            [self.manager respondToRequest:request.request withResult:CBATTErrorSuccess];
            if (completionHandler) {
                completionHandler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
            }
        } else if (request && request.type == CBATTRequestTypeWrite && request.request.characteristic.properties & CBCharacteristicPropertyWrite){
            //central写请求，回应central写成功
            [self.manager respondToRequest:request.request withResult:CBATTErrorSuccess];
            if (completionHandler) {
                completionHandler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
            }
        }
    }
    CBCharacteristic *characteristic = nil;
    for (CBCharacteristic *c in self.subscribedCharacteristics) {
        if (kStringEqualToString([c.UUID UUIDString], characteristicId) && kStringEqualToString([c.service.UUID UUIDString], serviceId)) {
            characteristic = c;
        }
    }
    if (characteristic) {
        NSArray *centrals = nil;
        if (needNotify) {
            centrals = [self subscribedCentralsOfCharacteristic:characteristic];
        }
        [self.manager updateValue:[NSData dataWithBase64String:value]
                forCharacteristic:(CBMutableCharacteristic *)characteristic
             onSubscribedCentrals:centrals];
        if (completionHandler) {
            completionHandler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
        }
    } else {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"writeCharacteristicValue" code:WABlueToothErrorCodeNoCharacteristic userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find characteristic with characteristicId:{%@}", characteristicId]
            }]);
        }
    }
    
}

- (void)webView:(WebView *)webView onCharacteristicReadRequestCallback:(NSString *)callback
{
    [self webView:webView
  onEventWithDict:self.characteristicReadRequestCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView offCharacteristicReadRequestCallback:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.characteristicReadRequestCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView onCharacteristicWriteRequestCallback:(NSString *)callback
{
    [self webView:webView
  onEventWithDict:self.characteristicWriteRequestCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView offCharacteristicWriteRequestCallback:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.characteristicWriteRequestCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView onCharacteristicSubscribedCallback:(NSString *)callback
{
    [self webView:webView
  onEventWithDict:self.characteristicSubscribedCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView offCharacteristicSubscribedCallback:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.characteristicSubscribedCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView onCharacteristicUnsubscribedCallback:(NSString *)callback
{
    [self webView:webView
  onEventWithDict:self.characteristicUnsubscribedCallbacks
         callback:callback];
}

- (void)webView:(WebView *)webView offCharacteristicUnsubscribedCallback:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.characteristicUnsubscribedCallbacks
         callback:callback];
}

- (NSArray<CBCentral *>*)subscribedCentralsOfCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *key = [NSString stringWithFormat:@"%@-%@",characteristic.service.UUID,characteristic.UUID];
    NSMutableDictionary *centralDict = _subscribedCentral[key];
    if (centralDict) {
        return [centralDict allValues];
    } else {
        return nil;
    }
}

- (void)addSubscribedCentral:(CBCentral *)central ofCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *key = [NSString stringWithFormat:@"%@-%@",characteristic.service.UUID,characteristic.UUID];
    NSMutableDictionary *centralDict = _subscribedCentral[key];
    if (!centralDict) {
        centralDict = [NSMutableDictionary dictionary];
        _subscribedCentral[key] = centralDict;
    }
    centralDict[[central.identifier UUIDString]] = central;
}

- (void)removeSubscribedCentral:(CBCentral *)central ofCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *key = [NSString stringWithFormat:@"%@-%@",characteristic.service.UUID,characteristic.UUID];
    NSMutableDictionary *centralDict = _subscribedCentral[key];
    if (centralDict) {
        [centralDict removeObjectForKey:[central.identifier UUIDString]];
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error
{
    NSString *key = @"startAdvertising";
    WABlueToothCompletionHandler handler = self.tempCallbacks[key];
    if (handler) {
        if (error) {
            handler(NO, nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeSystemError userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]);
        } else {
            handler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
        }
        [self.tempCallbacks removeObjectForKey:key];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"addServiceUUID%@",service.UUID];
    WABlueToothCompletionHandler handler = self.tempCallbacks[key];
    [_addedServices addObject:service];
    if (handler) {
        if (error) {
            handler(NO, nil, [NSError errorWithDomain:@"addService" code:WABlueToothErrorCodeSystemError userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]);
        } else {
            handler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
        }
        [self.tempCallbacks removeObjectForKey:key];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [_subscribedCharacteristics addObject:characteristic];
    [self addSubscribedCentral:central ofCharacteristic:characteristic];
    
    [self doCallbackInCallbackDict:self.characteristicSubscribedCallbacks
                         andResult:@{
                             @"serviceId"       : [characteristic.service.UUID UUIDString],
                             @"characteristicId": [characteristic.UUID UUIDString],
                         }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    [_subscribedCharacteristics removeObject:characteristic];
    [self removeSubscribedCentral:central ofCharacteristic:characteristic];
    
    [self doCallbackInCallbackDict:self.characteristicUnsubscribedCallbacks
                         andResult:@{
                             @"serviceId"       : [characteristic.service.UUID UUIDString],
                             @"characteristicId": [characteristic.UUID UUIDString],
                         }];
}


//收到central 读操作
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSNumber *callbackId = @([IdGenerator generateIdWithClassName:kRequestCallbackId]);
    _requestDict[callbackId] = [[CBATTTypeRequest alloc] initWithRequest:request andType:CBATTRequestTypeRead];
    [self doCallbackInCallbackDict:self.characteristicReadRequestCallbacks
                         andResult:@{
                             @"serviceId"       : [request.characteristic.service.UUID UUIDString],
                             @"characteristicId": [request.characteristic.UUID UUIDString],
                             @"callbackId"      : callbackId

                         }];
    
}

//收到central 写操作
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    for (CBATTRequest * request in requests) {
        NSNumber *callbackId = @([IdGenerator generateIdWithClassName:kRequestCallbackId]);
        _requestDict[callbackId] = [[CBATTTypeRequest alloc] initWithRequest:request andType:CBATTRequestTypeWrite];
        [self doCallbackInCallbackDict:self.characteristicWriteRequestCallbacks
        andResult:@{
            @"serviceId"        : [request.characteristic.service.UUID UUIDString],
            @"characteristicId" : [request.characteristic.UUID UUIDString],
            @"value"            : [request.value base64String] ?: @"",
            @"callbackId"       :   callbackId
        }];
        
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    
}


@end


@interface WABlueToothManager () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    CBCentralManager *_centralManager; // 系统蓝牙设备管理对象，主设备（用于扫描和连接外设）
    NSMutableDictionary *_foundPeripheralDictionary; // 发现的外设 以 peripheral.identifier.UUIDString(即设备UUID) 为 key : peripheral 为 value
    NSMutableDictionary *_newFoundPeripheralDictionary; // 新发现的外设，周期性上报 以 peripheral.identifier.UUIDString(即设备UUID) 为 key : peripheral 为 value
    NSMutableDictionary *_callbackDictionary; // 存储所有回调函数，以方法名为key 回调函数为value 如：@"openBluetoothAdapter" : callback
    NSTimeInterval _interval; // 上报设备间隔（单位秒）
    NSTimer *_timer; // 计时器，用于上报发现的设备，当_interval == 0 时，该属性为nil
    NSMutableDictionary *_deviceRSSIDictionary; // 存储信号强度，以device uuid 为key 信号强度为value 如：@"RSSI" : @(-51)
    NSMutableDictionary *_deviceAdvertiseServiceDataDictionary;
    NSMutableDictionary *_deviceAdvertiseLocalNameDictionary;
    NSMutableDictionary *_deviceAdvertiseServiceUUIDsDictionary;
    NSMutableDictionary *_deviceAdvertisDataDictionary; // 存储设备广播值，以device uuid 为key 广播中的以CBAdvertisementDataManufacturerDataKey为key的值转为Base64为value 参考：https://stackoverflow.com/questions/22139867/using-corebluetooth-is-it-possible-to-get-the-raw-scan-record-of-a-bluetooth-le
}

@property (nonatomic, strong) WABlueToothCentralModel *blueToothModel;
@property (nonatomic, assign) WABluetoothMode mode;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, WABlueToothPeripheralModel *> *peripheralModels;
@property (nonatomic, strong) NSLock *peripheralModelsLock;
@end

@implementation WABlueToothManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _peripheralModels = [NSMutableDictionary dictionary];
    }
    return self;
}

- (WABlueToothCentralModel *)blueToothModel
{
    if (!_blueToothModel) {
        _blueToothModel = [[WABlueToothCentralModel alloc] init];
    }
    return _blueToothModel;
}

#pragma mark - Internal
- (BOOL)checkManagerViable:(WABlueToothCompletionHandler)completionHandler withDomain:(NSString *)domain
{
    if (!_centralManager) {
        if (completionHandler) {
            completionHandler(NO ,nil, [NSError errorWithDomain:domain code:WABlueToothErrorCodeNotInit userInfo:@{ NSLocalizedDescriptionKey : @"Blue tooth adapter not init or no viable" }]);
        }
        return NO;
    }
    return YES;
}

- (BOOL)checkPeripheralConnectedWithServiceUUID:(NSString *)serviceUUID completionHandler:(WABlueToothCompletionHandler)completionHandler withDomain:(NSString *)domain
{
    CBPeripheral *peripheral = [self connectedPeripheralForServiceUUID:serviceUUID];
    if (!peripheral) {
        if (completionHandler) {
            completionHandler(NO , nil,[NSError errorWithDomain:domain code:WABlueToothErrorCodeNoConnection userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Device for this serviceId(%@) is no conndection!", serviceUUID] }]);
        }
    }
    return YES;
}

// 必须传入serviceUUID才能获取已连接设备
- (NSArray<CBPeripheral *> *)connectedPeripheralsWithServiceUUIDs:(NSArray<NSString *> *)serviceUUIDs {
    // 判断一下系统其它App已连接的(由于已连接的设备不会被扫描到)
    NSArray *cbuuids = [self getServiceUUIDs:serviceUUIDs];
    if (!cbuuids) return nil;
    
    return [_centralManager retrieveConnectedPeripheralsWithServices:cbuuids];
}

- (CBPeripheral *)connectedPeripheralForServiceUUID:(nonnull NSString *)serviceID
{
    if (!serviceID || serviceID.length == 0) return nil;
    NSArray *connectedPeripherals = [self connectedPeripheralsWithServiceUUIDs:@[serviceID]];
    if (connectedPeripherals.count > 0) {
        return [connectedPeripherals firstObject];
    }
    return nil;
}

- (id)getObjectInternal:(id)object {
    // 这里指处理常见的数据类型，后续有拓展，只需在这里添加类型即可
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]] ||
        [object isKindOfClass:[NSNull class]]) {
        return object;
    }
    if ([object isKindOfClass:[CBUUID class]]) {
        CBUUID *UUID = (CBUUID *)object;
        return UUID.UUIDString;
    }
    
    if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSMutableArray class]]) {
        NSArray *objectArray = object;
        NSMutableArray *arrayM = [NSMutableArray arrayWithCapacity:objectArray.count];
        for(int i = 0; i < objectArray.count; i++) {
            [arrayM setObject:[self getObjectInternal:[objectArray objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arrayM;
    }
    
    if([object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSMutableDictionary class]]) {
        NSDictionary *objectDictionary = object;
        NSMutableDictionary *dictionaryM = [NSMutableDictionary dictionaryWithCapacity:[objectDictionary count]];
        for(int i = 0; i < objectDictionary.allKeys.count; i++) {
            NSString *key = objectDictionary.allKeys[i];
            if ([key isKindOfClass:[CBUUID class]]) {
                CBUUID *UUID = (CBUUID *)object;
                key = UUID.UUIDString;
            }
            [dictionaryM setObject:[self getObjectInternal:[objectDictionary objectForKey:key]] forKey:key];
        }
        return dictionaryM;
    }
    
    if ([object isKindOfClass:[NSData class]]) { // 使用Base64编码
        return [((NSData *)object) base64String];
    }
    
    return [self object2dictionary:object];
}

- (NSArray *)objectArray2dictionaryArray:(NSArray *)objectArray {
    NSMutableArray *dictionaryArrayM = [NSMutableArray array];
    for (int i = 0; i < objectArray.count; i++) {
        id object = objectArray[i];
        [dictionaryArrayM addObject:[self object2dictionary:object]];
    }
    return dictionaryArrayM;
}

- (NSArray<WABlueToothDevice *> *)getDeviceWithDeviceUUID:(NSString *)deviceUUID fromPeripheralDictionary:(NSMutableDictionary<NSString *, CBPeripheral *> *)peripheralDictionary
{
    NSMutableArray *devices = [NSMutableArray array];
    NSArray *peripherals = [peripheralDictionary allValues];
    NSInteger peripheralsCount = peripherals.count;
    for (NSInteger i = 0; i < peripheralsCount; i++) {
        CBPeripheral *peripheral = peripherals[i];
        if (deviceUUID.length > 0 && ![peripheral.identifier.UUIDString isEqualToString:deviceUUID]) {
            continue;
        }
        WABlueToothDevice *device = [[WABlueToothDevice alloc] init];
        device.name = [peripheral.name copy];
        device.RSSI = [_deviceRSSIDictionary[peripheral.identifier.UUIDString] intValue];
        device.deviceId = [peripheral.identifier.UUIDString copy];
        device.advertisData = [_deviceAdvertisDataDictionary[peripheral.identifier.UUIDString] copy];
        device.serviceData = [_deviceAdvertiseServiceDataDictionary[peripheral.identifier.UUIDString] copy];
        device.advertisServiceUUIDs = [_deviceAdvertiseServiceUUIDsDictionary[peripheral.identifier.UUIDString] copy];
        device.localName = [_deviceAdvertiseLocalNameDictionary[peripheral.identifier.UUIDString] copy];
        [devices addObject:device];
    }
    return devices;
}

- (CBCharacteristic *)getCharacteristicWithDeviceUUID:(NSString *)deviceUUID
                                          serviceUUID:(NSString *)serviceUUID
                                   characteristicUUID:(NSString *)characteristicUUID
{
    CBPeripheral *peripheral = nil;
    // Returns nil for invalid strings.
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:deviceUUID];
    if (uuid) {
        NSArray *peripherals = [_centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
        for (int k = 0; k < peripherals.count; k++) {
            CBPeripheral *aPeripheral = peripherals[k];
            if ([aPeripheral.identifier.UUIDString isEqualToString:deviceUUID]) {
                peripheral = aPeripheral;
                break;
            }
        }
    }
    NSInteger servicesCount = peripheral.services.count;
    for (NSInteger i = 0; i < servicesCount; i++) {
        CBService *service = peripheral.services[i];
        if ([service.UUID.UUIDString isEqualToString:serviceUUID]) {
            NSInteger characteristicsCount = service.characteristics.count;
            for (NSInteger j = 0; j < characteristicsCount; j++) {
                CBCharacteristic *characteristic = service.characteristics[j];
                if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID]) {
                    return characteristic;
                }
            }
        }
    }
    return nil;
}

 //上报设备调用此方法
- (void)bluetoothDeviceFound
{
    NSArray *devices = [self getDeviceWithDeviceUUID:nil fromPeripheralDictionary:_newFoundPeripheralDictionary];
    [_newFoundPeripheralDictionary removeAllObjects];
    [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.bluetoothDeviceFoundCallbackDict
                                        andResult:@{@"devices" : [self objectArray2dictionaryArray:devices]}];
    
}

#pragma mark - Interface

- (void)openBluetoothAdapterWithMode:(WABluetoothMode)mode 
                   completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    [self closeBluetoothAdapterWithCompletionHandler:nil];
    self.mode = mode;
    if (mode == WABluetoothModeCentral) {
        // 初始化适配器
        NSDictionary *dic = @{CBCentralManagerOptionShowPowerAlertKey : @YES};
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:dic];
        _callbackDictionary = [[NSMutableDictionary alloc] init];
        _foundPeripheralDictionary = [[NSMutableDictionary alloc] init];
        _newFoundPeripheralDictionary = [[NSMutableDictionary alloc] init];
        _deviceRSSIDictionary = [[NSMutableDictionary alloc] init];
        _deviceAdvertisDataDictionary = [[NSMutableDictionary alloc] init];
        _deviceAdvertiseServiceUUIDsDictionary = [[NSMutableDictionary alloc] init];
        _deviceAdvertiseServiceDataDictionary = [[NSMutableDictionary alloc] init];
        _deviceAdvertiseLocalNameDictionary = [[NSMutableDictionary alloc] init];
        [self setBlock:completionHandler forKey:@"openBluetoothAdapter"];
    } else {
        if (completionHandler) {
            completionHandler(YES, nil, nil);
        }
    }
    
}
    
// 关闭蓝牙模块。调用该方法将断开所有已建立的链接并释放系统资源
- (void)closeBluetoothAdapterWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"closeBluetoothAdapter"]) return;
    // 停止扫描
    if ([_centralManager isScanning]) {
        [_centralManager stopScan];
    }
    _centralManager = nil;
    _callbackDictionary = nil;
    _foundPeripheralDictionary = nil;
    _newFoundPeripheralDictionary = nil;
    _deviceRSSIDictionary = nil;
    _deviceAdvertisDataDictionary = nil;
    _deviceAdvertiseServiceUUIDsDictionary = nil;
    _deviceAdvertiseServiceDataDictionary = nil;
    _deviceAdvertiseLocalNameDictionary = nil;
    _interval = 0;
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

// 获取本机蓝牙适配器状态
- (void)getBluetoothAdapterStateWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getBluetoothAdapterState"]) return;
    
    if (completionHandler) {
        if (@available(iOS 10.0, *)) {
            completionHandler(YES ,@{ @"code" : @(WABlueToothErrorCodeSuccess), @"available" : [NSNumber numberWithBool:_centralManager.state == CBManagerStatePoweredOn], @"discovering" : @(_centralManager.isScanning) }, nil);
        } else {
            // Fallback on earlier versions
            completionHandler(YES ,@{ @"code" : @(WABlueToothErrorCodeSuccess), @"available" : [NSNumber numberWithBool:_centralManager.state == CBCentralManagerStatePoweredOn], @"discovering" : @(_centralManager.isScanning) }, nil);
        }
    }
}

// 开始搜寻附近的蓝牙外围设备。注意，该操作比较耗费系统资源，请在搜索并连接到设备后调用 stop 方法停止搜索
- (void)startBluetoothDevicesDiscoveryWithServiceUUIDs:(NSArray<NSString *> *)UUIDs
                                       allowDuplicates:(BOOL)allowDuplicates
                                              interval:(NSTimeInterval)interval
                                     completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"startBluetoothDevicesDiscovery"]) return;
    
//    // Native NSArray类型 为 __NSSingleObjectArrayI
//    // OCS NSArray类型 为 __NSArrayI
//    if (UUIDs && !([NSStringFromClass([UUIDs class]) isEqualToString:@"__NSSingleObjectArrayI"] || [NSStringFromClass([UUIDs class]) isEqualToString:@"__NSArrayI"])) { // 参数类型错误
//        if (completionHandler) {
//            completionHandler(NO ,nil, [NSError errorWithDomain:@"startBluetoothDevicesDiscovery" code:WABlueToothErrorCodeSystemError userInfo:@{NSLocalizedDescriptionKey : @"Parameter type error!" }]);
//        }
//        return;
//    }
//
    if (@available(iOS 10.0, *)) {
        if (_centralManager.state != CBManagerStatePoweredOn) {
            if (completionHandler) {
                completionHandler(NO, nil, [NSError errorWithDomain:@"startBluetoothDevicesDiscovery" code:WABlueToothErrorCodeNotAvailable userInfo:@{ @"code" : @(WABlueToothErrorCodeNotAvailable), NSLocalizedDescriptionKey : @"Can only accept this command while in the powered on state" }]);
            }
            return;
        }
    } else {
        if (_centralManager.state != CBCentralManagerStatePoweredOn) {
            if (completionHandler) {
                completionHandler(NO, nil, [NSError errorWithDomain:@"startBluetoothDevicesDiscovery" code:WABlueToothErrorCodeNotAvailable userInfo:@{ @"code" : @(WABlueToothErrorCodeNotAvailable), NSLocalizedDescriptionKey : @"Can only accept this command while in the powered on state" }]);
            }
            return;
        }
        // Fallback on earlier versions
    }
    
    if (interval > 0) { // 间隔上报
        _interval = interval;
        // 重置计时器
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        _timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(bluetoothDeviceFound) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    
    NSArray *cbuuids = [self getServiceUUIDs:UUIDs];
    
    if (!cbuuids && UUIDs) { // service uuid 非法
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"startBluetoothDevicesDiscovery" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : @"service uuid is invalid!"}]);
        }
    } else { // 转换成功
        // 开始扫描
        [_centralManager scanForPeripheralsWithServices:cbuuids options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @(allowDuplicates) }];
        if (completionHandler) {
            completionHandler(YES ,@{ @"code" : @(WABlueToothErrorCodeSuccess), @"isDiscovering" : @(_centralManager.isScanning) }, nil);
        }
    }
}


// 停止搜寻附近的蓝牙外围设备。请在确保找到需要连接的设备后调用该方法停止搜索。
- (void)stopBluetoothDevicesDiscoveryWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"stopBluetoothDevicesDiscovery"]) return;
    
    [_centralManager stopScan];
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    if (completionHandler) {
        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess) }, nil);
    }
}

// 获取所有已发现的蓝牙设备，包括已经和本机处于连接状态的设备(只能处理自己扫描到的蓝牙设备)
- (void)getBluetoothDevicesWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getBluetoothDevices"]) return;
    
    if (completionHandler) {
        NSArray *devices = [self getDeviceWithDeviceUUID:nil fromPeripheralDictionary:_foundPeripheralDictionary];
        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess), @"devices" : [self objectArray2dictionaryArray:devices] }, nil);
    }
}

// 根据service uuid 获取处于已连接状态的设备
- (void)getConnectedBluetoothDevicesWithServiceUUIDs:(NSArray<NSString *> *)serviceUUIDs
                                   completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getConnectedBluetoothDevices"]) return;
    if (completionHandler) {
        NSMutableArray *devicesM = [NSMutableArray array];
        if (serviceUUIDs.count > 0) {
            NSArray *connectedPeriphers = [self connectedPeripheralsWithServiceUUIDs:serviceUUIDs];
            for (int j = 0; j < connectedPeriphers.count; j++) {
                CBPeripheral *peripheral = connectedPeriphers[j];
                WABlueToothDevice *device = [[WABlueToothDevice alloc] init];
                device.name = [peripheral.name copy];
                device.RSSI = [_deviceRSSIDictionary[peripheral.identifier.UUIDString] intValue];
                device.deviceId = [peripheral.identifier.UUIDString copy];
                device.advertisData = [_deviceAdvertisDataDictionary[peripheral.identifier.UUIDString] copy];
                device.serviceData = [_deviceAdvertiseServiceDataDictionary[peripheral.identifier.UUIDString] copy];
                device.advertisServiceUUIDs = [_deviceAdvertiseServiceUUIDsDictionary[peripheral.identifier.UUIDString] copy];
                device.localName = [_deviceAdvertiseLocalNameDictionary[peripheral.identifier.UUIDString] copy];
                [devicesM addObject:device];
            }
        }
        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess), @"devices" : [self objectArray2dictionaryArray:devicesM] }, nil);
    }
}

// 连接低功耗蓝牙设备
- (void)createBLEConnectionWithDeviceUUID:(NSString *)deviceUUID
                                  timeout:(NSTimeInterval)timeout
                        completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"createBLEConnection"]) return;
    
    CBPeripheral *perpheral = _foundPeripheralDictionary[deviceUUID];
    if (perpheral) {
        NSDictionary *connectOptions = @{ CBConnectPeripheralOptionNotifyOnConnectionKey : @YES,
                                          CBConnectPeripheralOptionNotifyOnDisconnectionKey : @YES,
                                          CBConnectPeripheralOptionNotifyOnNotificationKey : @YES };
        [_centralManager connectPeripheral:perpheral options:connectOptions];
        NSString *key = [NSString stringWithFormat:@"createBLEConnectionWithDeviceUUID%@", deviceUUID];
        [self setBlock:completionHandler forKey:key];
        if (timeout) {
            // timeout非0时，设置超时
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                if (self->_callbackDictionary[key]) { // 仍存在回调
                    if (perpheral.state == CBPeripheralStateConnected) {
                        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess)}, nil);
                    } else {
                        completionHandler(NO, nil, [NSError errorWithDomain:@"createBLEConnection" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : @"create device connection failed" }]);
                    }
                    [self->_callbackDictionary removeObjectForKey:key];
                }
            });
        }
        return;
    }
    if (completionHandler) { // 未发现对应设备
        completionHandler(NO, nil, [NSError errorWithDomain:@"createBLEConnection" code:WABlueToothErrorCodeNoDevice userInfo:@{ @"code" : @(WABlueToothErrorCodeNoDevice), NSLocalizedDescriptionKey : @"no device for this uuid" }]);
    }
}

// 断开与低功耗蓝牙设备的连接
- (void)closeBLEConnectionWithDeviceUUID:(NSString *)deviceUUID completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"closeBLEConnection"]) return;
    
    CBPeripheral *perpheral = _foundPeripheralDictionary[deviceUUID];
    
    if (perpheral) {
        // Note that this is non-blocking, and any <code>CBPeripheral</code> commands that are still pending to <i>peripheral</i> may or may not complete.
        [_centralManager cancelPeripheralConnection:perpheral];
        if (completionHandler) {
            NSString *key = [NSString stringWithFormat:@"closeBLEConnectionWithDeviceUUID%@", deviceUUID];
            [self setBlock:completionHandler forKey:key];
            // 设置超时 15秒
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WABlueToothTimeOut * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self->_callbackDictionary[key]) { // 仍存在回调
                    if (perpheral.state == CBPeripheralStateDisconnected) {
                        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess)}, nil);
                    } else {
                        completionHandler(NO, nil, [NSError errorWithDomain:@"closeBLEConnection" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : @"cancel device connection failed" }]);
                    }
                    [self->_callbackDictionary removeObjectForKey:key];
                }
            });
        }
        return;
    }
    if (completionHandler) { // 蓝牙未连接
        completionHandler(NO , nil, [NSError errorWithDomain:@"closeBLEConnection" code:WABlueToothErrorCodeNoConnection userInfo:@{ @"code" : @(WABlueToothErrorCodeNoConnection), NSLocalizedDescriptionKey : @"no connection" }]);
    }
}

// 获取蓝牙设备所有 service（服务）
- (void)getBLEDeviceServicesWithDeviceUUID:(NSString *)deviceUUID completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getBLEDeviceServices"]) return;
    
    CBPeripheral *peripheral = _foundPeripheralDictionary[deviceUUID];
    if (!peripheral) {
        if (completionHandler) { // 未发现对应设备
            completionHandler(NO , nil, [NSError errorWithDomain:@"getBLEDeviceServices" code:WABlueToothErrorCodeNoDevice userInfo:@{ @"code" : @(WABlueToothErrorCodeNoDevice), NSLocalizedDescriptionKey : @"no device for this  uuid" }]);
        }
        return;
    }
    if (peripheral.state == CBPeripheralStateConnected) {
        // 发现外设服务
        [peripheral discoverServices:nil];
        NSString *key = [NSString stringWithFormat:@"getBLEDeviceServicesWithDeviceUUID%@", deviceUUID];
        [self setBlock:completionHandler forKey:key];
    } else { // 未连接
        if (completionHandler) {
            completionHandler(NO , nil, [NSError errorWithDomain:@"getBLEDeviceServices" code:WABlueToothErrorCodeNoConnection userInfo:@{ @"code" : @(WABlueToothErrorCodeNoConnection), NSLocalizedDescriptionKey : @"Can only accept command while in the connected state" }]);
        }
    }
}

- (void)setBLEMTU:(NSUInteger)MTU
   withDeviceUUID:(NSString *)deviceUUID
completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"setBLEMTU"]) return;
    
    CBPeripheral *peripheral = _foundPeripheralDictionary[deviceUUID];
    if (!peripheral) {
        if (completionHandler) { // 未发现对应设备
            completionHandler(NO , nil, [NSError errorWithDomain:@"setBLEMTU" code:WABlueToothErrorCodeNoDevice userInfo:@{ @"code" : @(WABlueToothErrorCodeNoDevice), NSLocalizedDescriptionKey : @"no device for this  uuid" }]);
        }
        return;
    }
    if (peripheral.state == CBPeripheralStateConnected) {
        NSUInteger mtu = [peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse];
        if (completionHandler) {
            if (mtu >= MTU) {
                completionHandler(YES, @{@"code": @(WABlueToothErrorCodeSuccess)}, nil);
            } else {
                completionHandler(NO, nil, [NSError errorWithDomain:@"setBLEMTU" code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"the maximum write value length is %lu",(unsigned long)mtu]
                }]);
            }
        }
    } else { // 未连接
        if (completionHandler) {
            completionHandler(NO , nil, [NSError errorWithDomain:@"setBLEMTU" code:WABlueToothErrorCodeNoConnection userInfo:@{ @"code" : @(WABlueToothErrorCodeNoConnection), NSLocalizedDescriptionKey : @"Can only accept command while in the connected state" }]);
        }
    }
}

// 获取蓝牙设备所有 characteristic（特征值）
- (void)getBLEDeviceCharacteristicsWithDeviceUUID:(NSString *)deviceUUID
                                      serviceUUID:(NSString *)serviceUUID
                                completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getBLEDeviceCharacteristics"]) return;
    if (![self checkPeripheralConnectedWithServiceUUID:serviceUUID completionHandler:completionHandler withDomain:@"getBLEDeviceCharacteristics"]) return;
    
    CBPeripheral *peripheral = [self connectedPeripheralForServiceUUID:serviceUUID];
    // 如果是已连接，设备就有服务值，需要先获取服务才能获取特征值
    for (int i = 0; i < peripheral.services.count; i++) {
        CBService *service = peripheral.services[i];
        if ([service.UUID.UUIDString isEqualToString:serviceUUID]) { // 找到服务
            // 扫描服务的相关特征
            [peripheral discoverCharacteristics:nil forService:service];
            if (completionHandler) {
                NSString *key = [NSString stringWithFormat:@"getBLEDeviceCharacteristicsWithDeviceUUID%@serviceUUID%@", deviceUUID, serviceUUID];
                [self setBlock:completionHandler forKey:key];
                return;
            }
        }
    }
    if (completionHandler) {
        completionHandler(NO , nil, [NSError errorWithDomain:@"getBLEDeviceCharacteristics" code:WABlueToothErrorCodeNoCharacteristic userInfo:@{ @"code" : @(WABlueToothErrorCodeNoCharacteristic), NSLocalizedDescriptionKey : @"no characteristic for this uuid" }]);
    }
}

- (void)getBLEDeviceRSSIWithDeviceUUID:(NSString *)deviceUUID
                     completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"getBLEDeviceCharacteristics"]) return;
    CBPeripheral *peripheral = _foundPeripheralDictionary[deviceUUID];
    
    if (!peripheral) {
        if (completionHandler) { // 未发现对应设备
            completionHandler(NO , nil, [NSError errorWithDomain:@"getBLEDeviceRSSI" code:WABlueToothErrorCodeNoDevice userInfo:@{ @"code" : @(WABlueToothErrorCodeNoDevice), NSLocalizedDescriptionKey : @"no device for this  uuid" }]);
        }
        return;
    }
    NSString *key = [NSString stringWithFormat:@"getBLEDeviceRSSIWithDeviceUUID%@", deviceUUID];
    [self setBlock:completionHandler forKey:key];
    [peripheral readRSSI];
}


// 读取低功耗蓝牙设备的特征值的二进制数据值
- (void)readBLECharacteristicValueWithDeviceUUID:(NSString *)deviceUUID
                                     serviceUUID:(NSString *)serviceUUID
                              characteristicUUID:(NSString *)characteristicUUID
                               completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"readBLECharacteristicValue"]) return;
    if (![self checkPeripheralConnectedWithServiceUUID:serviceUUID completionHandler:completionHandler withDomain:@"readBLECharacteristicValue"]) return;
    
    CBPeripheral *peripheral = [self connectedPeripheralForServiceUUID:serviceUUID];
    CBCharacteristic *characteristic = [self getCharacteristicWithDeviceUUID:deviceUUID serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
    if (characteristic.properties & CBCharacteristicPropertyRead) { // 支持 read 操作
        // 读取二进制数据
        NSString *key = [NSString stringWithFormat:@"readBLECharacteristicValueWithDeviceUUID%@characteristicUUID%@", deviceUUID, characteristicUUID];
        [self setBlock:completionHandler forKey:key];
        
        [peripheral readValueForCharacteristic:characteristic];
        return;
    }
    if (completionHandler) { // 不支持read操作(原因可能有：未找到设备、未找到服务、未找到特征)
        completionHandler(NO, nil, [NSError errorWithDomain:@"readBLECharacteristicValue" code:WABlueToothErrorCodePropertyNotSupported userInfo:@{ @"code" : @(WABlueToothErrorCodePropertyNotSupported), NSLocalizedDescriptionKey : @"read property not supported (may be no device || service || characteristic)" }]);
    }
}

// 向低功耗蓝牙设备特征值中写入二进制数据
- (void)writeBLECharacteristicValueWithDeviceUUID:(NSString *)deviceUUID
                                      serviceUUID:(NSString *)serviceUUID
                               characteristicUUID:(NSString *)characteristicUUID
                                            value:(NSString *)value
                                completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"writeBLECharacteristicValue"]) return;
    if (![self checkPeripheralConnectedWithServiceUUID:serviceUUID completionHandler:completionHandler withDomain:@"writeBLECharacteristicValue"]) return;
    
    CBPeripheral *peripheral = [self connectedPeripheralForServiceUUID:serviceUUID];
    CBCharacteristic *characteristic = [self getCharacteristicWithDeviceUUID:deviceUUID serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
    NSData *valueData = [NSData dataWithBase64String:value];
    if (characteristic.properties & CBCharacteristicPropertyWrite) { // 支持 write 操作
        // 写入二进制数据
        [peripheral writeValue:valueData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        NSString *key = [NSString stringWithFormat:@"writeBLECharacteristicValueWithDeviceUUID%@characteristicUUID%@", deviceUUID, characteristicUUID];
        [self setBlock:completionHandler forKey:key];
        return;
    }
    if (completionHandler) { // 不支持write操作(原因可能有：未找到设备、未找到服务、未找到特征)
        completionHandler(NO , nil, [NSError errorWithDomain:@"writeBLECharacteristicValue" code:WABlueToothErrorCodePropertyNotSupported userInfo:@{ @"code" : @(WABlueToothErrorCodePropertyNotSupported), NSLocalizedDescriptionKey : @"write property not supported (may be no device || service || characteristic)" }]);
    }
}

// 启用低功耗蓝牙设备特征值变化时的 notify 功能
- (void)notifyBLECharacteristicValueChangeWithDeviceUUID:(NSString *)deviceUUID
                                             serviceUUID:(NSString *)serviceUUID
                                      characteristicUUID:(NSString *)characteristicUUID
                                                     use:(BOOL)isUse
                                       completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    if (![self checkManagerViable:completionHandler withDomain:@"notifyBLECharacteristicValueChange"]) return;
    if (![self checkPeripheralConnectedWithServiceUUID:serviceUUID completionHandler:completionHandler withDomain:@"notifyBLECharacteristicValueChange"]) return;
    
    CBPeripheral *peripheral = [self connectedPeripheralForServiceUUID:serviceUUID];
    CBCharacteristic *characteristic = [self getCharacteristicWithDeviceUUID:deviceUUID serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
    // The Client Characteristic Configuration descriptor‘UUID is 0x2902
    // 第0位 Notifications 0(disabled)/1(enabled)
    // 第1位 Indications 0(disabled)/1(enabled)
    // 参考：https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
    BOOL notifyEnable = characteristic.properties & CBCharacteristicPropertyNotify;
    BOOL indicateEnable = characteristic.properties & CBCharacteristicPropertyIndicate;
    if (notifyEnable || indicateEnable) {
        for (int i = 0; i < characteristic.descriptors.count; i++) {
            CBDescriptor *descriptor = characteristic.descriptors[i];
            if ([descriptor.UUID.UUIDString isEqualToString:@"2902"]) {
                if (notifyEnable) {
                    [descriptor setValue:@(0x01) forKey:@"value"];
                }
                if (indicateEnable) {
                    [descriptor setValue:@(0x03) forKey:@"value"];
                }
                break;
            }
        }
        // 订阅通知，数据通知会调用didUpdateValueForCharacteristic方法
        [peripheral setNotifyValue:isUse forCharacteristic:characteristic];
        if (completionHandler) {
            completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess)}, nil);
            return;
        }
    }
    if (completionHandler) { // 订阅通知失败
        completionHandler(NO, nil, [NSError errorWithDomain:@"notifyBLECharacteristicValueChange" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : @"notify characteristic value change fialed (may be no device || service || characteristic)" }]);
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    
    if (@available(iOS 10.0, *)) {
        if (central.state != CBManagerStatePoweredOn) {
            [central stopScan];
        }
    } else {
        if (central.state != CBCentralManagerStatePoweredOn) {
            [central stopScan];
        }
        // Fallback on earlier versions
    }
    if (@available(iOS 10.0, *)) {
        [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.bluetoothAdapterStateChangeCallbackDict andResult:@{
            @"code" : @(WABlueToothErrorCodeSuccess),
            @"available" : [NSNumber numberWithBool:_centralManager.state == CBManagerStatePoweredOn],
            @"discovering" : @(_centralManager.isScanning)
        }];
    } else {
        [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.bluetoothAdapterStateChangeCallbackDict andResult:@{
            @"code" : @(WABlueToothErrorCodeSuccess),
            @"available" : [NSNumber numberWithBool:_centralManager.state == CBCentralManagerStatePoweredOn],
            @"discovering" : @(_centralManager.isScanning)
        }];
        // Fallback on earlier versions
    }
    NSString *key = @"openBluetoothAdapter";
    WABlueToothCompletionHandler openCallback = [self getBlockForKey:key];
    if (openCallback) {
        switch (central.state) {
            case CBManagerStateUnknown:
                openCallback(NO , nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeNotInit userInfo:@{ @"code" : @(WABlueToothErrorCodeNotInit), NSLocalizedDescriptionKey : @"state unkonwn" }]);
                break;
            case CBManagerStatePoweredOn:
                openCallback(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess) }, nil);
                break;
            case CBManagerStateResetting:
                openCallback(NO, nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeNotInit userInfo:@{ @"code" : @(WABlueToothErrorCodeNotInit), NSLocalizedDescriptionKey : @"state reseting" }]);
                break;
            case CBManagerStatePoweredOff:
                openCallback(NO, nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeNotInit userInfo:@{ @"code" : @(WABlueToothErrorCodeNotInit), NSLocalizedDescriptionKey : @"state powered off" }]);
                break;
            case CBManagerStateUnsupported:
                openCallback(NO, nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeNotAvailable userInfo:@{ @"code" : @(WABlueToothErrorCodeNotAvailable), NSLocalizedDescriptionKey : @"state unsupported" }]);
                break;
            case CBManagerStateUnauthorized:
                openCallback(NO, nil, [NSError errorWithDomain:key code:WABlueToothErrorCodeNotAvailable userInfo:@{ @"code" : @(WABlueToothErrorCodeNotAvailable), NSLocalizedDescriptionKey : @"state unauthorized" }]);
                break;
            default:
                break;
        }
        [_callbackDictionary removeObjectForKey:key];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!peripheral.name) return;

    _deviceRSSIDictionary[peripheral.identifier.UUIDString] = RSSI;
    _deviceAdvertisDataDictionary[peripheral.identifier.UUIDString] = advertisementData[CBAdvertisementDataManufacturerDataKey] ? [advertisementData[CBAdvertisementDataManufacturerDataKey] base64String] : [NSNull null];
    _deviceAdvertiseServiceDataDictionary[peripheral.identifier.UUIDString] = advertisementData[CBAdvertisementDataServiceDataKey] ?: [NSNull null];
    _deviceAdvertiseLocalNameDictionary[peripheral.identifier.UUIDString] = advertisementData[CBAdvertisementDataLocalNameKey] ?: [NSNull null];
    _deviceAdvertiseServiceUUIDsDictionary[peripheral.identifier.UUIDString] = advertisementData[CBAdvertisementDataServiceUUIDsKey] ?: [NSNull null];
    [_foundPeripheralDictionary setValue:peripheral forKey:peripheral.identifier.UUIDString];
    [_newFoundPeripheralDictionary setValue:peripheral forKey:peripheral.identifier.UUIDString];

    if (_interval == 0) { // 立刻上报
        WABlueToothDevice *device = [[WABlueToothDevice alloc] init];
        device.name = [peripheral.name copy];
        device.RSSI = [_deviceRSSIDictionary[peripheral.identifier.UUIDString] intValue];
        device.deviceId = [peripheral.identifier.UUIDString copy];
        device.advertisData = [_deviceAdvertisDataDictionary[peripheral.identifier.UUIDString] copy];
        device.serviceData = [_deviceAdvertiseServiceDataDictionary[peripheral.identifier.UUIDString] copy];
        device.localName = [_deviceAdvertiseLocalNameDictionary[peripheral.identifier.UUIDString] copy];
        device.advertisServiceUUIDs = [_deviceAdvertiseServiceUUIDsDictionary[peripheral.identifier.UUIDString] copy];
        [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.bluetoothDeviceFoundCallbackDict andResult:@{ @"code" : @(WABlueToothErrorCodeSuccess), @"devices" : [self objectArray2dictionaryArray:@[device]] }];
        [_newFoundPeripheralDictionary removeAllObjects];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSString *key = [NSString stringWithFormat:@"createBLEConnectionWithDeviceUUID%@", peripheral.identifier.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    // 设置外设代理
    [peripheral setDelegate:self];
    if (completionHandler) {
        completionHandler(YES ,@{ @"code" : @(WABlueToothErrorCodeSuccess) }, nil);
        [_callbackDictionary removeObjectForKey:key];
    }
    [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.BLEConnectionStateChangeCallbackDict
                                        andResult:@{ @"deviceId" : peripheral.identifier.UUIDString,
                                                     @"connected" : @(YES) }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"createBLEConnectionWithDeviceUUID%@", peripheral.identifier.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        completionHandler(NO, nil, [NSError errorWithDomain:@"createBLEConnection" code:WABlueToothErrorCodeConnectionFailed userInfo:@{ @"code" : @(WABlueToothErrorCodeConnectionFailed), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        [_callbackDictionary removeObjectForKey:key];
    }
    [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.BLEConnectionStateChangeCallbackDict andResult:@{ @"deviceId" : peripheral.identifier.UUIDString, @"connected" : @(NO) }];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"closeBLEConnectionWithDeviceUUID%@", peripheral.identifier.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"closeBLEConnection" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        } else if (peripheral.state == CBPeripheralStateDisconnected) {
            completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess) }, nil);
        }
        [_callbackDictionary removeObjectForKey:key];
    }
    [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.BLEConnectionStateChangeCallbackDict andResult:@{ @"deviceId" : peripheral.identifier.UUIDString, @"connected" : @(NO)}];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"getBLEDeviceServicesWithDeviceUUID%@", peripheral.identifier.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBLEDeviceServices" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        } else {
            NSMutableArray *servicesM = [NSMutableArray array];
            NSArray *services = peripheral.services;
            NSInteger servicesCount = services.count;
            for (NSInteger i = 0; i < servicesCount; i++) {
                CBService *service = services[i];
                WABlueToothService *btService = [[WABlueToothService alloc] init];
                btService.uuid = [service.UUID.UUIDString copy];
                btService.isPrimary = service.isPrimary;
                [servicesM addObject:btService];
            }
            completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess), @"services" : [self objectArray2dictionaryArray:servicesM] }, nil);
        }
        [_callbackDictionary removeObjectForKey:key];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if (!error) {
        //更新对应RSSI
        _deviceRSSIDictionary[peripheral.identifier.UUIDString] = RSSI;
    }
    NSString *key = [NSString stringWithFormat:@"getBLEDeviceRSSIWithDeviceUUID%@", peripheral.identifier.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBLEDeviceRSSIWithDeviceUUID" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        } else {
            completionHandler(YES, @{@"RSSI": RSSI}, nil);
        }
        [_callbackDictionary removeObjectForKey:key];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"getBLEDeviceCharacteristicsWithDeviceUUID%@serviceUUID%@", peripheral.identifier.UUIDString, service.UUID.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBLEDeviceCharacteristics" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        } else {
            NSMutableArray *characteristicsM = [NSMutableArray array];
            NSArray *characteristics = service.characteristics;
            NSInteger characteristicsCount = characteristics.count;
            for (NSInteger i = 0; i < characteristicsCount; i++) {
                CBCharacteristic *characteristic = characteristics[i];
                WABlueToothCharacteristic *btCharacteristic = [[WABlueToothCharacteristic alloc] init];
                btCharacteristic.uuid = [characteristic.UUID.UUIDString copy];
                WABlueToothProperties *btProperties = [[WABlueToothProperties alloc] init];
                btProperties.read = characteristic.properties & CBCharacteristicPropertyRead;
                btProperties.write = characteristic.properties & CBCharacteristicPropertyWrite;
                btProperties.notify = characteristic.properties & CBCharacteristicPropertyNotify;
                btProperties.indicate = characteristic.properties & CBCharacteristicPropertyIndicate;
                btCharacteristic.properties = btProperties;
                [characteristicsM addObject:btCharacteristic];
            }
            completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess), @"characteristics" : [self objectArray2dictionaryArray:characteristicsM] }, nil);
        }
        [_callbackDictionary removeObjectForKey:key];
    }
}

// 执行 read 操作后的回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"readBLECharacteristicValueWithDeviceUUID%@characteristicUUID%@", peripheral.identifier.UUIDString, characteristic.UUID.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"readBLECharacteristicValue" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
        } else {
            WABlueToothCharacteristic *btChatacteristic = [[WABlueToothCharacteristic alloc] init];
            btChatacteristic.uuid = [characteristic.UUID.UUIDString copy];
            btChatacteristic.serviceUUID = [characteristic.service.UUID.UUIDString copy];
            btChatacteristic.value = [characteristic.value base64String];
            completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess), @"characteristic" : [self object2dictionary:btChatacteristic] }, nil);
        }
        [_callbackDictionary removeObjectForKey:key];
    }
    [self.blueToothModel doCallbackInCallbackDict:self.blueToothModel.BLECharacteristicValueChangeCallbackDict andResult:@{
        @"code" : @(WABlueToothErrorCodeSuccess),
        @"deviceId" : peripheral.identifier.UUIDString,
        @"serviceId" : characteristic.service.UUID.UUIDString,
        @"characteristicId" : characteristic.UUID.UUIDString,
        @"value" : [characteristic.value base64String] ?: [NSNull null]
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"writeBLECharacteristicValueWithDeviceUUID%@characteristicUUID%@", peripheral.identifier.UUIDString, characteristic.UUID.UUIDString];
    WABlueToothCompletionHandler completionHandler = [self getBlockForKey:key];
    if (completionHandler) {
        if (error) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"writeBLECharacteristicValue" code:WABlueToothErrorCodeSystemError userInfo:@{ @"code" : @(WABlueToothErrorCodeSystemError), NSLocalizedDescriptionKey : [error localizedDescription] }]);
            return;
        }
        completionHandler(YES, @{ @"code" : @(WABlueToothErrorCodeSuccess) }, nil);
        [_callbackDictionary removeObjectForKey:key];
    }
}

#pragma mark - **********************Callbacks***********************

- (void)webView:(WebView *)webView onBluetoothAdapterStateChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                 onEventWithDict:self.blueToothModel.bluetoothAdapterStateChangeCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView offBluetoothAdapterStateChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                offEventWithDict:self.blueToothModel.bluetoothAdapterStateChangeCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView onBluetoothDeviceFoundCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                 onEventWithDict:self.blueToothModel.bluetoothDeviceFoundCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView offBluetoothDeviceFoundCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                offEventWithDict:self.blueToothModel.bluetoothDeviceFoundCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView onBLEConnectionStateChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                 onEventWithDict:self.blueToothModel.BLEConnectionStateChangeCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView offBLEConnectionStateChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                offEventWithDict:self.blueToothModel.BLEConnectionStateChangeCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView onBLECharacteristicValueChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                 onEventWithDict:self.blueToothModel.BLECharacteristicValueChangeCallbackDict
                        callback:callback];
}

- (void)webView:(WebView *)webView offBLECharacteristicValueChangeCallback:(NSString *)callback
{
    [self.blueToothModel webView:webView
                offEventWithDict:self.blueToothModel.BLECharacteristicValueChangeCallbackDict
                        callback:callback];
}


#pragma mark - ********************BLEPeripheralServer****************************

- (void)createBLEPeripheralServerWithcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [[WABlueToothPeripheralModel alloc] init];
    [self addBlueToothPeripheralModel:model withKey:@(model.peripheralModelId)];
    if (completionHandler) {
        completionHandler(YES, @{@"server": [@(model.peripheralModelId) stringValue]}, nil);
    }
}

- (void)closeBLEPeripheralServer:(NSUInteger)serverId
           withcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"close" completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model close];
    [self removeBlueToothPeripheralModelWithKey:@(serverId)];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

- (void)BLEPeripheralServer:(NSUInteger)serverId
                 addService:(NSDictionary *)service
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"addService" completionHandler:completionHandler];
    if (!model) {
        return;
    }
//    Characteristics with cached values must be read-only
    NSError *error = nil;
    CBMutableService *cnService = [self serviceDict2Service:service withError:&error];
    if (error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
        }
        return;
    }
    [model addService:cnService withCompletionHandler:completionHandler];
    
}


- (void)BLEPeripheralServer:(NSUInteger)serverId
              removeService:(NSString *)serviceId
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"removeService" completionHandler:completionHandler];
    if (!model) {
        return;
    }
    
    [model removeService:serviceId withCompletionHandler:completionHandler];
}

- (void)BLEPeripheralServer:(NSUInteger)serverId
           startAdvertising:(NSDictionary *)advertisementData
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"startAdvertising"
                                                         completionHandler:completionHandler];
    if (!model) {
        return;
    }
    NSString *deviceName = advertisementData[@"deviceName"];
    NSArray *UUIDs = advertisementData[@"serviceUuids"];
    
    NSMutableDictionary *adData = [NSMutableDictionary dictionary];
    if (deviceName) {
        adData[CBAdvertisementDataLocalNameKey] = deviceName;
    }
    if (UUIDs) {
        NSMutableArray *CBUUIDs = [NSMutableArray array];
        for (NSString *uuid in UUIDs) {
            [CBUUIDs addObject:[CBUUID UUIDWithString:uuid]];
        }
        adData[CBAdvertisementDataServiceUUIDsKey] = CBUUIDs;
    }
    //startAdvertising只支持CBAdvertisementDataLocalNameKey和CBAdvertisementDataServiceUUIDsKey
    [model BLEPeripheralServerStartAdvertising:adData
                         withcompletionHandler:completionHandler];
}

- (void)BLEPeripheralServer:(NSUInteger)serverId
stopAdvertisingWithcompletionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"stopAdvertising"
                                                         completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model BLEPeripheralServerStopAdvertising];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

- (void)BLEPeripheralServer:(NSUInteger)serverId
   writeCharacteristicValue:(NSString *)value
                   toSevice:(NSString *)serviceId
         withCharacteristic:(NSString *)characteristicId
                 needNotify:(BOOL)needNotify
                   callback:(NSNumber *)callbackId
          completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self checkModelExistWithServiceId:serverId
                                                                    domain:@"writeCharacteristicValue"
                                                         completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model BLEPeripheralServerWriteCharacteristicValue:value
                                              toSevice:serviceId
                                    withCharacteristic:characteristicId
                                            needNotify:needNotify
                                              callback:callbackId
                                     completionHandler:completionHandler];
}

// 添加监听已连接的设备请求读当前外围设备的特征值事件。收到该消息后需要立刻调用 writeCharacteristicValue 写回数据，否则主机不会收到响应。
- (void)webView:(WebView *)webView onCharacteristicReadRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView onCharacteristicReadRequestCallback:callback];
    }
}

// 移除添加监听已连接的设备请求读当前外围设备的特征值事件。
- (void)webView:(WebView *)webView offCharacteristicReadRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView offCharacteristicReadRequestCallback:callback];
    }
}

// 添加监听已连接的设备请求写当前外围设备的特征值事件。收到该消息后需要立刻调用 writeCharacteristicValue 写回数据，否则主机不会收到响应。
- (void)webView:(WebView *)webView onCharacteristicWriteRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView onCharacteristicWriteRequestCallback:callback];
    }
}

// 移除监听已连接的设备请求写当前外围设备的特征值事件。
- (void)webView:(WebView *)webView offCharacteristicWriteRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView offCharacteristicWriteRequestCallback:callback];
    }
}

- (void)webView:(WebView *)webView onCharacteristicSubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView onCharacteristicSubscribedCallback:callback];
    }
}

- (void)webView:(WebView *)webView offCharacteristicSubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView offCharacteristicSubscribedCallback:callback];
    }
}

- (void)webView:(WebView *)webView onCharacteristicUnsubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView onCharacteristicUnsubscribedCallback:callback];
    }
}

- (void)webView:(WebView *)webView offCharacteristicUnsubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serverId)];
    if (model) {
        [model webView:webView offCharacteristicUnsubscribedCallback:callback];
    }
}

////随着webView的销毁，删除对应model
//- (void)addLifeCycleManager:(WebView *)webView peripheralServerId:(NSInteger)peripheralServerId{
//    @weakify(self)
//    [webView addViewWillDeallocBlock:^(WebView * webView) {
//        @strongify(self);
////        WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(peripheralServerId)];
//        [self removeBlueToothPeripheralModelWithKey:@(peripheralServerId)];
//    }];
//}

- (WABlueToothPeripheralModel *)checkModelExistWithServiceId:(NSUInteger)serviceId
                                                      domain:(NSString *)domain
                                           completionHandler:(WABlueToothCompletionHandler)completionHandler
{
    WABlueToothPeripheralModel *model = [self blueToothPeripheralModelWithKey:@(serviceId)];
    if (model) {
        return model;
    }
    if (completionHandler) {
        completionHandler(NO, nil , [NSError errorWithDomain:domain code:WABlueToothErrorCodeNotInit userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"BLEPeripheralServer with id :{%lu} not found",(unsigned long)serviceId]
        }]);
    }
    return nil;
}


- (void)addBlueToothPeripheralModel:(WABlueToothPeripheralModel *)model withKey:(NSNumber *)key
{
    NSParameterAssert(model);
    NSParameterAssert(key);
    [_peripheralModelsLock lock];
    _peripheralModels[key] = model;
    [_peripheralModelsLock unlock];
}

- (void)removeBlueToothPeripheralModelWithKey:(NSNumber *)key
{
    NSParameterAssert(key);
    [_peripheralModelsLock lock];
    [_peripheralModels removeObjectForKey:key];
    [_peripheralModelsLock unlock];
}

- (WABlueToothPeripheralModel *)blueToothPeripheralModelWithKey:(NSNumber *)key
{
    
    NSParameterAssert(key);
    WABlueToothPeripheralModel *model = nil;
    [_peripheralModelsLock lock];
    model = _peripheralModels[key];
    [_peripheralModelsLock unlock];
    return  model;
}


- (CBMutableService *)serviceDict2Service:(NSDictionary *)dict withError:(NSError **)error
{
    
    NSString *serviceId = dict[@"uuid"];
    if (!serviceId) {
        return nil;
    }
    bool hasError = NO;
    CBMutableService *cbService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:serviceId] primary:YES];
    NSArray *characteristics = dict[@"characteristics"];
    NSMutableArray *characteristicArray = [NSMutableArray array];
    for (NSDictionary * characteristic in characteristics) {
        NSDictionary *properties = characteristic[@"properties"];
        NSDictionary *permission = characteristic[@"permission"];
        NSString *value = characteristic[@"value"];
        NSArray *descriptors = characteristic[@"descriptors"];
        CBCharacteristicProperties cbProerties = CBCharacteristicPropertyRead;
        //当value为有值时，只能设置为只读
        if (!value) {
            cbProerties = cbProerties |
            CBCharacteristicPropertyWrite  |
            CBCharacteristicPropertyNotify |
            CBCharacteristicPropertyIndicate;
        }
        if (properties) {
            if (properties[@"read"] && ![properties[@"read"] boolValue]) {
                cbProerties = cbProerties & ~CBCharacteristicPropertyRead;
            }
            if (!value) {
                if (properties[@"write"] && ![properties[@"write"] boolValue]) {
                    cbProerties = cbProerties & ~CBCharacteristicPropertyWrite;
                }
                if (properties[@"notify"] && ![properties[@"notify"] boolValue]) {
                    cbProerties = cbProerties & ~CBCharacteristicPropertyNotify;
                }
                if (properties[@"indicate"] && ![properties[@"indicate"] boolValue]) {
                    cbProerties = cbProerties & ~CBCharacteristicPropertyIndicate;
                }
            } else {
                if (properties[@"write"] == nil || [properties[@"write"] boolValue]) {
                    hasError = YES;
                }
                if (properties[@"notify"] == nil || [properties[@"notify"] boolValue]) {
                    hasError = YES;
                }
                if (properties[@"indicate"] == nil || [properties[@"indicate"] boolValue]) {
                    hasError = YES;
                }
            }
        }
        //当value为有值时，只能设置为只读
        CBAttributePermissions cbPermissions = CBAttributePermissionsReadable |
        CBAttributePermissionsReadEncryptionRequired;
        if (!value) {
            cbPermissions = cbPermissions |
            CBAttributePermissionsWriteable |
            CBAttributePermissionsWriteEncryptionRequired;
        }
        if (permission) {
            if (permission[@"readable"] && ![permission[@"readable"] boolValue]) {
                cbPermissions = cbPermissions & ~CBAttributePermissionsReadable;
            }
            if (permission[@"readEncryptionRequired"] && ![permission[@"readEncryptionRequired"] boolValue]) {
                cbPermissions = cbPermissions & ~CBAttributePermissionsReadEncryptionRequired;
            }
            if (!value) {
                if (permission[@"writeable"] && ![permission[@"writeable"] boolValue]) {
                    cbPermissions = cbPermissions & ~CBAttributePermissionsWriteable;
                }
                
                if (permission[@"writeEncryptionRequired"] && ![permission[@"writeEncryptionRequired"] boolValue]) {
                    cbPermissions = cbPermissions & ~CBAttributePermissionsWriteEncryptionRequired;
                }
            } else {
                if (permission[@"writeable"] == nil || [permission[@"writeable"] boolValue]) {
                    hasError = YES;
                }
                if (permission[@"writeEncryptionRequired"] == nil || [permission[@"writeEncryptionRequired"] boolValue]) {
                    hasError = YES;
                }
            }
        }
        CBMutableCharacteristic *cbCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:characteristic[@"uuid"]]
                                                                                       properties:cbProerties
                                                                                            value:value ? [NSData dataWithBase64String:value] : nil
                                                                                      permissions:cbPermissions];
        if (descriptors) {
            NSMutableArray *cbDescriptors = [NSMutableArray array];
            for (NSDictionary *descriptor in descriptors) {
                CBMutableDescriptor *cbDescriptor = [[CBMutableDescriptor alloc] initWithType:[CBUUID UUIDWithString:descriptor[@"uuid"]] value:[NSData dataWithBase64String:descriptor[@"value"]]];
                [cbDescriptors addObject:cbDescriptor];
            }
            cbCharacteristic.descriptors = cbDescriptors;
        }
        [characteristicArray addObject:cbCharacteristic];
    }
    cbService.characteristics = characteristicArray;
    if (hasError && error) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:-1
                                 userInfo:@{
                                     NSLocalizedDescriptionKey: @"Characteristics with cached values must be read-only"
                                 }];
    }
    return cbService;
}


// 不支持取地址（&）
- (NSDictionary *)object2dictionary:(id)object {
    NSMutableDictionary *dictionaryM = [NSMutableDictionary dictionary];
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList([object class], &ivarCount);
    
    for(int i = 0; i < ivarCount; i++) {
        Ivar ivar = ivars[i];
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        id value = [object valueForKey:ivarName];
        if (value == nil) {
            value = [NSNull null];
        } else {
            value = [self getObjectInternal:value];
        }
        [dictionaryM setObject:value forKey:ivarName];
    }
    
    return dictionaryM;
}

//- (NSString *)jsonStringFromDictionay:(NSDictionary *)dic
//{
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
//    if (error) {
//        NSLog(@"jsonStringFromDictionay error ：%@", [error localizedDescription]);
//        return nil;
//    }
//    NSString *resultString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    [resultString release];
//    return resultString;
//}

- (void)setBlock:(WABlueToothCompletionHandler)callback forKey:(NSString *)key
{
    if (!callback) return;
    
    WABlueToothCompletionHandler callbackCopy = [callback copy];
    [_callbackDictionary setObject:callbackCopy forKey:key];
}

- (WABlueToothCompletionHandler)getBlockForKey:(NSString *)key
{
    return _callbackDictionary[key];
}

- (NSArray<CBUUID *> *)getServiceUUIDs:(NSArray<NSString *> *)serviceIds
{
    if (serviceIds == nil) return nil;
    NSMutableArray *serviceUUIDsM = [NSMutableArray array];
    for (int i = 0; i < serviceIds.count; i++) {
        NSString *servicesId = serviceIds[i];
        if (servicesId.length == 0) continue;
        @try {
            // 字符串必须是 a 16-bit, 32-bit, or 128-bit UUID string 否则会Crash
            CBUUID *uuid = [CBUUID UUIDWithString:servicesId];
            [serviceUUIDsM addObject:uuid];
        } @catch (NSException *exception) {}
    }
    return serviceUUIDsM;
}

@end


 
