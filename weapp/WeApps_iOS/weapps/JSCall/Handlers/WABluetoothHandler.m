//
//  WABluetoothHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WABluetoothHandler.h"
#import "Weapps.h"

//蓝牙
kSELString(openBluetoothAdapter)
kSELString(closeBluetoothAdapter)
kSELString(startBluetoothDevicesDiscovery)
kSELString(stopBluetoothDevicesDiscovery)
kSELString(getBluetoothAdapterState)
kSELString(getBluetoothDevices)
kSELString(getConnectedBluetoothDevices)
kSELString(onBluetoothDeviceFound)
kSELString(offBluetoothDeviceFound)
kSELString(onBluetoothAdapterStateChange)
kSELString(offBluetoothAdapterStateChange)

//低功耗蓝牙
kSELString(getBLEDeviceServices)
kSELString(getBLEDeviceRSSI)
kSELString(getBLEDeviceCharacteristics)
kSELString(createBLEConnection)
kSELString(closeBLEConnection)
kSELString(setBLEMTU)
kSELString(writeBLECharacteristicValue)
kSELString(readBLECharacteristicValue)
kSELString(notifyBLECharacteristicValueChange)
kSELString(onBLEConnectionStateChange)
kSELString(offBLEConnectionStateChange)
kSELString(onBLECharacteristicValueChange)
kSELString(offBLECharacteristicValueChange)

//外围设备
kSELString(onBLEPeripheralConnectionStateChanged)
kSELString(offBLEPeripheralConnectionStateChanged)

kSELString(createBLEPeripheralServer)
kSELString(operateBLEPeripheralServer)



@implementation WABluetoothHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            openBluetoothAdapter,
            closeBluetoothAdapter,
            startBluetoothDevicesDiscovery,
            stopBluetoothDevicesDiscovery,
            getBluetoothAdapterState,
            getBluetoothDevices,
            getConnectedBluetoothDevices,
            onBluetoothDeviceFound,
            offBluetoothDeviceFound,
            onBluetoothAdapterStateChange,
            offBluetoothAdapterStateChange,
            
            getBLEDeviceServices,
            getBLEDeviceRSSI,
            getBLEDeviceCharacteristics,
            createBLEConnection,
            closeBLEConnection,
            setBLEMTU,
            writeBLECharacteristicValue,
            readBLECharacteristicValue,
            notifyBLECharacteristicValueChange,
            onBLEConnectionStateChange,
            offBLEConnectionStateChange,
            onBLECharacteristicValueChange,
            offBLECharacteristicValueChange,
            
            createBLEPeripheralServer,
            operateBLEPeripheralServer
        ];
    }
    return methods;
}


JS_API(openBluetoothAdapter){
    kBeginCheck
    kEndCheck([NSString class], @"mode", YES)
    NSString *mode = @"central";
    if (event.args[@"mode"]) {
        mode = event.args[@"mode"];
    }
    NSArray *modes = @[@"central", @"peripheral"];
    if (![modes containsObject:mode]) {
        NSString *info = [NSString stringWithFormat:@"fail unsupported mode,{%@}", mode];
        kFailWithErrorWithReturn(openBluetoothAdapter, -1, info)
    }
    WABluetoothMode bluetoothMode = WABluetoothModeCentral;
    if (!kStringEqualToString(mode, @"central")) {
        bluetoothMode = WABluetoothModePeripheral;
    }
    [[Weapps sharedApps].bluetoothManager openBluetoothAdapterWithMode:bluetoothMode completionHandler:^(BOOL success,
                                                                                                         NSDictionary * _Nullable resultDictionary,
                                                                                                         NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(closeBluetoothAdapter){
    [[Weapps sharedApps].bluetoothManager closeBluetoothAdapterWithCompletionHandler:^(BOOL success,
                                                                                       NSDictionary * _Nullable resultDictionary,
                                                                                       NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(startBluetoothDevicesDiscovery){
    kBeginCheck
    kCheck([NSArray class], @"services", YES)
    kCheckIsBoolean([NSNumber class], @"allowDuplicatesKey", YES, YES)
    kEndCheck([NSNumber class], @"interval", YES)
    
    NSArray *sevices = event.args[@"services"];
    BOOL allowDuplicatesKey = NO;
    if ([event.args[@"allowDuplicatesKey"] boolValue]) {
        allowDuplicatesKey = YES;
    }
    NSTimeInterval interval = [event.args[@"interval"] floatValue];
    [[Weapps sharedApps].bluetoothManager startBluetoothDevicesDiscoveryWithServiceUUIDs:sevices
                                                                         allowDuplicates:allowDuplicatesKey
                                                                                interval:interval
                                                                       completionHandler:^(BOOL success,
                                                                                           NSDictionary * _Nullable resultDictionary,
                                                                                           NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopBluetoothDevicesDiscovery){
    [[Weapps sharedApps].bluetoothManager stopBluetoothDevicesDiscoveryWithCompletionHandler:^(BOOL success,
                                                                                               NSDictionary * _Nullable resultDictionary,
                                                                                               NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getBluetoothAdapterState){
    [[Weapps sharedApps].bluetoothManager getBluetoothAdapterStateWithCompletionHandler:^(BOOL success,
                                                                                          NSDictionary * _Nullable resultDictionary,
                                                                                          NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getBluetoothDevices){
    [[Weapps sharedApps].bluetoothManager getBluetoothDevicesWithCompletionHandler:^(BOOL success,
                                                                                     NSDictionary * _Nullable resultDictionary,
                                                                                     NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


JS_API(getConnectedBluetoothDevices){
    kBeginCheck
    kEndCheck([NSArray class], @"services", NO)
    NSArray *services = event.args[@"services"];
    [[Weapps sharedApps].bluetoothManager getConnectedBluetoothDevicesWithServiceUUIDs:services
                                                                     completionHandler:^(BOOL success,
                                                                                         NSDictionary * _Nullable resultDictionary,
                                                                                         NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onBluetoothDeviceFound){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
                   onBluetoothDeviceFoundCallback:event.callbacak];
    return @"";
}

JS_API(offBluetoothDeviceFound){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
                  offBluetoothDeviceFoundCallback:event.callbacak];
    return @"";
}

JS_API(onBluetoothAdapterStateChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
            onBluetoothAdapterStateChangeCallback:event.callbacak];
    return @"";
}

JS_API(offBluetoothAdapterStateChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
           offBluetoothAdapterStateChangeCallback:event.callbacak];
    return @"";
}




#pragma mark *************************BEL************************

JS_API(getBLEDeviceServices){
    kBeginCheck
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    [[Weapps sharedApps].bluetoothManager getBLEDeviceServicesWithDeviceUUID:deviceId
                                                           completionHandler:^(BOOL success,
                                                                               NSDictionary * _Nullable resultDictionary,
                                                                               NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


JS_API(getBLEDeviceRSSI){
    kBeginCheck
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    [[Weapps sharedApps].bluetoothManager getBLEDeviceRSSIWithDeviceUUID:deviceId
                                                       completionHandler:^(BOOL success,
                                                                           NSDictionary * _Nullable resultDictionary,
                                                                           NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getBLEDeviceCharacteristics){
    kBeginCheck
    kCheck([NSString class], @"serviceId", NO)
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSString *serviceId = event.args[@"serviceId"];
    [[Weapps sharedApps].bluetoothManager getBLEDeviceCharacteristicsWithDeviceUUID:deviceId
                                                                        serviceUUID:serviceId
                                                                  completionHandler:^(BOOL success,
                                                                                      NSDictionary * _Nullable resultDictionary,
                                                                                      NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


JS_API(createBLEConnection){
    kBeginCheck
    kCheck([NSNumber class], @"timeout", YES)
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSTimeInterval timeout = 0;
    if (event.args[@"timeout"]) {
        timeout = [event.args[@"timeout"] floatValue];
    }
    [[Weapps sharedApps].bluetoothManager createBLEConnectionWithDeviceUUID:deviceId
                                                                    timeout:timeout
                                                          completionHandler:^(BOOL success,
                                                                              NSDictionary * _Nullable resultDictionary,
                                                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
    
}

JS_API(closeBLEConnection){
    kBeginCheck
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    [[Weapps sharedApps].bluetoothManager closeBLEConnectionWithDeviceUUID:deviceId
                                                         completionHandler:^(BOOL success,
                                                                             NSDictionary * _Nullable resultDictionary,
                                                                             NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setBLEMTU){
    kBeginCheck
    kCheck([NSNumber class], @"mtu", NO)
    kEndCheck([NSString class], @"deviceId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSUInteger mtu = [event.args[@"mtu"] unsignedIntegerValue];
    [[Weapps sharedApps].bluetoothManager setBLEMTU:mtu
                                     withDeviceUUID:deviceId
                                  completionHandler:^(BOOL success,
                                                      NSDictionary * _Nullable resultDictionary,
                                                      NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(writeBLECharacteristicValue){
    kBeginCheck
    kCheck([NSString class], @"deviceId", NO)
    kCheck([NSString class], @"serviceId", NO)
    kCheck([NSString class], @"characteristicId", NO)
    kEndCheck([NSString class], @"value", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSString *serviceId = event.args[@"serviceId"];
    NSString *characteristicId = event.args[@"characteristicId"];
    NSString *value = event.args[@"value"];
    [[Weapps sharedApps].bluetoothManager writeBLECharacteristicValueWithDeviceUUID:deviceId
                                                                        serviceUUID:serviceId
                                                                 characteristicUUID:characteristicId
                                                                              value:value
                                                                  completionHandler:^(BOOL success,
                                                                                      NSDictionary * _Nullable resultDictionary,
                                                                                      NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(readBLECharacteristicValue){
    kBeginCheck
    kCheck([NSString class], @"deviceId", NO)
    kCheck([NSString class], @"serviceId", NO)
    kEndCheck([NSString class], @"characteristicId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSString *serviceId = event.args[@"serviceId"];
    NSString *characteristicId = event.args[@"characteristicId"];
    [[Weapps sharedApps].bluetoothManager readBLECharacteristicValueWithDeviceUUID:deviceId
                                                                       serviceUUID:serviceId
                                                                characteristicUUID:characteristicId
                                                                 completionHandler:^(BOOL success,
                                                                                     NSDictionary * _Nullable resultDictionary,
                                                                                     NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(notifyBLECharacteristicValueChange){
    kBeginCheck
    kCheck([NSString class], @"deviceId", NO)
    kCheck([NSString class], @"serviceId", NO)
    kCheckIsBoolean([NSNumber class], @"state", NO, YES)
    kEndCheck([NSString class], @"characteristicId", NO)
    NSString *deviceId = event.args[@"deviceId"];
    NSString *serviceId = event.args[@"serviceId"];
    NSString *characteristicId = event.args[@"characteristicId"];
    BOOL state = [event.args[@"state"] boolValue];
    [[Weapps sharedApps].bluetoothManager notifyBLECharacteristicValueChangeWithDeviceUUID:deviceId
                                                                               serviceUUID:serviceId
                                                                        characteristicUUID:characteristicId
                                                                                       use:state
                                                                         completionHandler:^(BOOL success,
                                                                                             NSDictionary * _Nullable resultDictionary,
                                                                                             NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onBLEConnectionStateChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
               onBLEConnectionStateChangeCallback:event.callbacak];
    return @"";
}

JS_API(offBLEConnectionStateChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
              offBLEConnectionStateChangeCallback:event.callbacak];
    return @"";
}

JS_API(onBLECharacteristicValueChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
           onBLECharacteristicValueChangeCallback:event.callbacak];
    return @"";
}

JS_API(offBLECharacteristicValueChange){
    [[Weapps sharedApps].bluetoothManager webView:event.webView
          offBLECharacteristicValueChangeCallback:event.callbacak];
    return @"";
}


#pragma mark - ***********************外围设备****************************
JS_API(createBLEPeripheralServer){
    [[Weapps sharedApps].bluetoothManager createBLEPeripheralServerWithcompletionHandler:^(BOOL success,
                                                                                           NSDictionary * _Nullable resultDictionary,
                                                                                           NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary);
        } else {
            kFailWithErr(error);
        }
    }];
    return @"";
}

JS_API(operateBLEPeripheralServer){
    kBeginCheck
    kCheck([NSString class], @"serverId", NO)
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"addService")) {
        [self _addService:event];
    } else if (kStringEqualToString(operationType, @"removeService")) {
        [self _removeService:event];
    } else if (kStringEqualToString(operationType, @"startAdvertising")) {
        [self _startAdvertising:event];
    } else if (kStringEqualToString(operationType, @"stopAdvertising")) {
        [self _stopAdvertising:event];
    } else if (kStringEqualToString(operationType, @"writeCharacteristicValue")) {
        [self _writeCharacteristicValue:event];
    } else if (kStringEqualToString(operationType, @"close")) {
        [self _close:event];
    } else if (kStringEqualToString(operationType, @"onCharacteristicReadRequest")) {
        [self _onCharacteristicReadRequest:event];
    } else if (kStringEqualToString(operationType, @"onCharacteristicWriteRequest")) {
        [self _onCharacteristicWriteRequest:event];
    } else if (kStringEqualToString(operationType, @"offCharacteristicReadRequest")) {
        [self _offCharacteristicReadRequest:event];
    } else if (kStringEqualToString(operationType, @"offCharacteristicWriteRequest")) {
        [self _offCharacteristicWriteRequest:event];
    } else if (kStringEqualToString(operationType, @"onCharacteristicSubscribed")) {
        [self _onCharacteristicSubscribed:event];
    } else if (kStringEqualToString(operationType, @"onCharacteristicUnsubscribed")) {
        [self _onCharacteristicUnsubscribed:event];
    } else if (kStringEqualToString(operationType, @"offCharacteristicSubscribed")) {
        [self _offCharacteristicSubscribed:event];
    } else if (kStringEqualToString(operationType, @"offCharacteristicUnsubscribed")) {
        [self _offCharacteristicUnsubscribed:event];
    }
    return @"";
}

PRIVATE_API(addService){
    kBeginCheck
    kCheck([NSString class], @"serverId", NO)
    kCheck([NSDictionary class], @"service", NO)
    kCheckInDict(event.args[@"service"], [NSString class], @"uuid", NO)
    kEndCheckInDict(event.args[@"service"], [NSArray class], @"characteristics", NO)
    NSString *serverId = event.args[@"serverId"];
    
    [[Weapps sharedApps].bluetoothManager BLEPeripheralServer:[serverId integerValue]
                                                   addService:event.args[@"service"]
                                        withcompletionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary);
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(removeService){
    kBeginCheck
    kCheck([NSString class], @"serviceId", NO)
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    NSString *serviceId = event.args[@"serviceId"];
    [[Weapps sharedApps].bluetoothManager BLEPeripheralServer:[serverId integerValue]
                                                removeService:serviceId
                                        withcompletionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(startAdvertising){
    kBeginCheck
    kCheck([NSString class], @"serverId", NO)
    kCheck([NSDictionary class], @"advertiseRequest", NO)
    kCheckInDict(event.args[@"advertiseRequest"], [NSString class], @"deviceName", YES)
    kCheckIsBooleanInDict(event.args[@"advertiseRequest"], [NSNumber class], @"connectable", YES, YES)
    kCheckInDict(event.args[@"advertiseRequest"], [NSArray class], @"serviceUuids", YES)
    kEndCheck([NSString class], @"powerLevel", YES)
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager BLEPeripheralServer:[serverId integerValue]
                                             startAdvertising:event.args withcompletionHandler:^(BOOL success,
                                                                                                 NSDictionary * _Nullable resultDictionary,
                                                                                                 NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary);
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(stopAdvertising){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager BLEPeripheralServer:[serverId integerValue]
                         stopAdvertisingWithcompletionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary);
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(writeCharacteristicValue){
    kBeginCheck
    kCheck([NSString class], @"serviceId", NO)
    kCheck([NSString class], @"characteristicId", NO)
    kCheck([NSString class], @"value", NO)
    kCheckIsBoolean([NSNumber class], @"needNotify", NO, YES)
    kCheck([NSNumber class], @"callbackId", YES)
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    NSString *serviceId = event.args[@"serviceId"];
    NSString *value = event.args[@"value"];
    NSString *characteristicId = event.args[@"characteristicId"];
    BOOL needNotify = [event.args[@"needNotify"] boolValue];
    NSNumber *callbackId = event.args[@"callbackId"];
    [[Weapps sharedApps].bluetoothManager BLEPeripheralServer:[serverId integerValue]
                                     writeCharacteristicValue:value
                                                     toSevice:serviceId
                                           withCharacteristic:characteristicId
                                                   needNotify:needNotify
                                                     callback:callbackId
                                            completionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(close){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager closeBLEPeripheralServer:[serverId integerValue]
                                             withcompletionHandler:^(BOOL success,
                                                                     NSDictionary * _Nullable resultDictionary,
                                                                     NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(onCharacteristicReadRequest){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
              onCharacteristicReadRequestCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(onCharacteristicWriteRequest){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
             onCharacteristicWriteRequestCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(offCharacteristicReadRequest){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
             offCharacteristicReadRequestCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(offCharacteristicWriteRequest){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
            offCharacteristicWriteRequestCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(onCharacteristicSubscribed){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
               onCharacteristicSubscribedCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(offCharacteristicSubscribed){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
              offCharacteristicSubscribedCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(onCharacteristicUnsubscribed){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
             onCharacteristicUnsubscribedCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}

PRIVATE_API(offCharacteristicUnsubscribed){
    kBeginCheck
    kEndCheck([NSString class], @"serverId", NO);
    NSString *serverId = event.args[@"serverId"];
    [[Weapps sharedApps].bluetoothManager webView:event.webView
            offCharacteristicUnsubscribedCallback:event.callbacak
                           withPeripheralServerId:[serverId integerValue]];
    return @"";
}
@end
