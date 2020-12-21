//
//  WABluetoothManager.h
//  weapps
//
//  Created by tommywwang on 2020/9/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "WebView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WABluetoothMode) {
    WABluetoothModeCentral,
    WABluetoothModePeripheral
};

typedef void(^WABlueToothCompletionHandler)(BOOL success ,NSDictionary *_Nullable resultDictionary, NSError * _Nullable error);

@interface WABlueToothManager : NSObject

// 初始化蓝牙适配器
- (void)openBluetoothAdapterWithMode:(WABluetoothMode)mode
                    completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 关闭蓝牙模块。调用该方法将断开所有已建立的链接并释放系统资源
- (void)closeBluetoothAdapterWithCompletionHandler:(_Nullable WABlueToothCompletionHandler)completionHandler;

// 获取本机蓝牙适配器状态
- (void)getBluetoothAdapterStateWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler;

/**
 开始搜寻附近的蓝牙外围设备。注意，该操作比较耗费系统资源，请在搜索并连接到设备后调用 stop 方法停止搜索

 @param UUIDs 蓝牙设备主 service 的 uuid 列表
 @param allowDuplicates 是否允许重复上报同一设备， 如果允许重复上报，则onDeviceFound 方法会多次上报同一设备，但是 RSSI 值会有不同
 @param interval 上报设备的间隔，默认为0，意思是找到新设备立即上报，否则根据传入的间隔上报
 @param completionHandler 回调block
 */
- (void)startBluetoothDevicesDiscoveryWithServiceUUIDs:(NSArray<NSString *> *)UUIDs
                                       allowDuplicates:(BOOL)allowDuplicates
                                              interval:(NSTimeInterval)interval
                                     completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 停止搜寻附近的蓝牙外围设备。请在确保找到需要连接的设备后调用该方法停止搜索。
- (void)stopBluetoothDevicesDiscoveryWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 获取所有已发现的蓝牙设备，包括已经和本机处于连接状态的设备
- (void)getBluetoothDevicesWithCompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 根据 uuid 获取处于已连接状态的设备
- (void)getConnectedBluetoothDevicesWithServiceUUIDs:(NSArray<NSString *> *)serviceUUIDs
                                   completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 连接低功耗蓝牙设备
//timeout 单位毫秒
- (void)createBLEConnectionWithDeviceUUID:(NSString *)deviceUUID
                                  timeout:(NSTimeInterval)timeout
                        completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 断开与低功耗蓝牙设备的连接
- (void)closeBLEConnectionWithDeviceUUID:(NSString *)deviceUUID
                       completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 获取蓝牙设备所有 service（服务）
- (void)getBLEDeviceServicesWithDeviceUUID:(NSString *)deviceUUID
                         completionHandler:(WABlueToothCompletionHandler)completionHandler;


/// 设置外设mtu。目前iOS没有api支持，只能获取写入外设的mtu，对比用户传入的mtu，若用户传入的小于等于苹果提供的则成功，反之则失败并传回苹果提供的mtu
/// @param MTU 最大传输值
/// @param deviceUUID 设备id
/// @param completionHandler 回调
- (void)setBLEMTU:(NSUInteger)MTU
   withDeviceUUID:(NSString *)deviceUUID
completionHandler:(WABlueToothCompletionHandler)completionHandler;


// 获取蓝牙设备所有 characteristic（特征值）
- (void)getBLEDeviceCharacteristicsWithDeviceUUID:(NSString *)deviceUUID
                                      serviceUUID:(NSString *)serviceUUID
                                completionHandler:(WABlueToothCompletionHandler)completionHandler;

/// 获取蓝牙设备的信号强度。
/// @param deviceUUID 设备uuid
/// @param completionHandler 回调
- (void)getBLEDeviceRSSIWithDeviceUUID:(NSString *)deviceUUID
                     completionHandler:(WABlueToothCompletionHandler)completionHandler;

/**
 读取低功耗蓝牙设备的特征值的二进制数据值
 
 @param deviceUUID 蓝牙设备的 uuid
 @param serviceUUID 蓝牙特征值对应服务的 uuid
 @param characteristicUUID 蓝牙特征值的 uuid
 @param completionHandler 回调block
 */
- (void)readBLECharacteristicValueWithDeviceUUID:(NSString *)deviceUUID
                                     serviceUUID:(NSString *)serviceUUID
                              characteristicUUID:(NSString *)characteristicUUID
                               completionHandler:(WABlueToothCompletionHandler)completionHandler;

/**
 向低功耗蓝牙设备特征值中写入二进制数据
 
 @param deviceUUID 蓝牙设备的 uuid
 @param serviceUUID 蓝牙特征值对应服务的 uuid
 @param characteristicUUID 蓝牙特征值的 uuid
 @param value 字符串Base64编码
 @param completionHandler 回调block
 */
- (void)writeBLECharacteristicValueWithDeviceUUID:(NSString *)deviceUUID
                                      serviceUUID:(NSString *)serviceUUID
                               characteristicUUID:(NSString *)characteristicUUID
                                            value:(NSString *)value
                                completionHandler:(WABlueToothCompletionHandler)completionHandler;

/**
 启用低功耗蓝牙设备特征值变化时的 notify 功能
 
 @param deviceUUID 蓝牙设备的 uuid
 @param serviceUUID 蓝牙特征值对应服务的 uuid
 @param characteristicUUID 蓝牙特征值的 uuid
 @param isUse 是否开启通知
 @param completionHandler 回调block
 */
- (void)notifyBLECharacteristicValueChangeWithDeviceUUID:(NSString *)deviceUUID
                                             serviceUUID:(NSString *)serviceUUID
                                      characteristicUUID:(NSString *)characteristicUUID
                                                     use:(BOOL)isUse
                                       completionHandler:(WABlueToothCompletionHandler)completionHandler;


// 监听低功耗蓝牙连接的错误事件，包括设备丢失，连接异常断开等等
- (void)webView:(WebView *)webView onBluetoothAdapterStateChangeCallback:(NSString *)callback;

// 移除监听低功耗蓝牙连接的错误事件，包括设备丢失，连接异常断开等等
- (void)webView:(WebView *)webView offBluetoothAdapterStateChangeCallback:(NSString *)callback;

// 监听寻找到新设备的事件
- (void)webView:(WebView *)webView onBluetoothDeviceFoundCallback:(NSString *)callback;

// 移除监听寻找到新设备的事件
- (void)webView:(WebView *)webView offBluetoothDeviceFoundCallback:(NSString *)callback;

// 监听低功耗蓝牙连接状态变化。
- (void)webView:(WebView *)webView onBLEConnectionStateChangeCallback:(NSString *)callback;

// 移除监听低功耗蓝牙连接状态变化。
- (void)webView:(WebView *)webView offBLEConnectionStateChangeCallback:(NSString *)callback;

// 监听低功耗蓝牙设备的特征值变化。必须先启用notify接口才能接收到设备推送的notification
- (void)webView:(WebView *)webView onBLECharacteristicValueChangeCallback:(NSString *)callback;

// 移除监听低功耗蓝牙设备的特征值变化。
- (void)webView:(WebView *)webView offBLECharacteristicValueChangeCallback:(NSString *)callback;


#pragma mark - ***********************BLEPeripheralServer**********************

// 创建外围设备服务端
- (void)createBLEPeripheralServerWithcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

//关闭外围服务
- (void)closeBLEPeripheralServer:(NSUInteger)serverId withcompletionHandler:(WABlueToothCompletionHandler)completionHandler;;

// 外围服务添加service
- (void)BLEPeripheralServer:(NSUInteger)serverId addService:(NSDictionary *)service
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 外围服务删除service
- (void)BLEPeripheralServer:(NSUInteger)serverId removeService:(NSString *)serviceId
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 外围服务开始广播
- (void)BLEPeripheralServer:(NSUInteger)serverId
           startAdvertising:(NSDictionary *)advertisementData
      withcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 外围服务停止广播
- (void)BLEPeripheralServer:(NSUInteger)serverId
     stopAdvertisingWithcompletionHandler:(WABlueToothCompletionHandler)completionHandler;

// 往指定特征值写入数据，并通知已连接的主机，从机的特征值已发生变化，该接口会处理是走回包还是走订阅
- (void)BLEPeripheralServer:(NSUInteger)serverId
   writeCharacteristicValue:(NSString *)value
                   toSevice:(NSString *)serviceId
             withCharacteristic:(NSString *)characteristicId
                 needNotify:(BOOL)needNotify
                   callback:(NSNumber *)callbackId
          completionHandler:(WABlueToothCompletionHandler)completionHandler;

// 添加监听已连接的设备请求读当前外围设备的特征值事件。收到该消息后需要立刻调用 writeCharacteristicValue 写回数据，否则主机不会收到响应。
- (void)webView:(WebView *)webView onCharacteristicReadRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

// 移除添加监听已连接的设备请求读当前外围设备的特征值事件。
- (void)webView:(WebView *)webView offCharacteristicReadRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

// 添加监听已连接的设备请求写当前外围设备的特征值事件。收到该消息后需要立刻调用 writeCharacteristicValue 写回数据，否则主机不会收到响应。
- (void)webView:(WebView *)webView onCharacteristicWriteRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

// 移除监听已连接的设备请求写当前外围设备的特征值事件。
- (void)webView:(WebView *)webView offCharacteristicWriteRequestCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

- (void)webView:(WebView *)webView onCharacteristicSubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

- (void)webView:(WebView *)webView offCharacteristicSubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

- (void)webView:(WebView *)webView onCharacteristicUnsubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;

- (void)webView:(WebView *)webView offCharacteristicUnsubscribedCallback:(NSString *)callback withPeripheralServerId:(NSUInteger)serverId;
@end
NS_ASSUME_NONNULL_END
