
(function(){
    const AsyncApi = [
                    "navigateTo",
                    "getCurrentPageQuery",
                    
                    "weiXinLogin",
                    "shareWebPage",
                    "shareImage",
                    "shareText",
                    "showToast",
                    "createQrCode",
                    "scanCode",
                    "openCamera",
                    "openAlbum",
                    "setStorage",
                    "removeStorage",
                    "clearStorage",
                    "getStorage",
                    "getStorageInfo",
                    "getBase64Image",
                    "saveBase64Image",
                    "getFileSize",
                    "deleteFile",
                    "createFile",
                    "createFolder",
                    "makePhoneCall",
                    "smsTo",
                    "emailTo",
                    "setClipboardData",
                    "getClipboardData",
                    "addCalendarEvent",
                    "saveImageToPhotosAlbum",
                    "compressImage",
                    "getSystemInfo",
                    "chooseImage",
                    
                    "saveFile",
                    "getFileInfo",
                    "getSavedFileList",
                    "removeSavedFile",
                    "openDocument",
                    "getBatteryInfo",
                      
                    "onKeyboardHeightChange",
                    "offKeyboardHeightChange",
                    "hideKeyboard",
                      
                    "pageScrollTo",
                    "setScreenBrightness",
                    "getScreenBrightness",
                    "onUserCaptureScreen",
                    "offUserCaptureScreen",
                    "setKeepScreenOn",
                    "faceVerify",
                    "getSimInfo",
                    
                    "getNetworkType",
                    "onNetworkStatusChange",
                    "offNetworkStatusChange",
                    "getSimOperatorName",
                    "getSystemFreeSize",
                    "getAppId",
                    "getAppName",
                    "getScreenWidth",
                    "getScreenHeight",
                    "previewImage",
                    
                    "hideToast",
                    "showLoading",
                    "hideLoading",
                    "showActionSheet",
                    "showModal",
                    "vibrateLong",
                    "vibrateShort",
                        
                    "saveVideoToPhotosAlbum",
                    "chooseVideo",
                    "chooseMedia",
                    "compressVideo",
                    "getVideoInfo",
                    "createVideoContext",
                    "operateVideoContext",
                    "setVideoContextState",
                      
                    "stopLocationUpdate",
                    "startLocationUpdateBackground",
                    "startLocationUpdate",
                    "openLocation",
                    "onLocationChange",
                    "offLocationChange",
                    "getLocation",
                    "chooseLocation",
                    "onAppShow",
                    "offAppShow",
                    "onAppHide",
                    "offAppHide",
                    "onPullDownRefresh",
                    "offPullDownRefresh",
                    "startPullDownRefresh",
                    "stopPullDownRefresh",
                    
                    "onHeadersReceived",
                    "offHeadersReceived",
                    "offProgressUpdate",
                    "onProgressUpdate",
                    "abort",

                    "operateRecorder",
                    // "onFrameRecorded",
                    // "onInterruptionBegin",
                    // "onInterruptionEnd",
                    // "onPause",
                    // "onResume",
                    // "onStart",
                    // "onStop",
                    // "onError",
                    "getAvailableAudioSources",

                    
                    // "onCanplay",
                    // "onEnded",
                    // "onError",
                    // "onPause",
                    // "onPlay",
                    // "onSeeked",
                    // "onSeeking",
                    // "onStop",
                    // "onTimeUpdate",
                    // "onWaiting",
                    // "offCanplay",
                    // "offEnded",
                    // "offError",
                    // "offPause",
                    // "offPlay",
                    // "offSeeked",
                    // "offSeeking",
                    // "offStop",
                    // "offTimeUpdate",
                    // "offWaiting",
//                    "setInnerAudioSrcSync",
//                    "setInnerAudioStartTimeSync",
//                    "setInnerAudioAutoplaySync",
//                    "setInnerAudioLoopSync",
//                    "setInnerAudioObeyMuteSwitchSync",
//                    "setInnerAudioVolumeSync",
//                    "setInnerAudioPlaybackRateSync",
         
                    
                    "operateBackgroundAudio",
                    "setBackgroundAudioState",
                    "operateInnerAudio",
                    "setInnerAudioState",

                    "setConfig",
                    "showNavigationBarLoading",
                    "hideNavigationBarLoading",
                    "setNavigationBarTitle",
                    "setNavigationBarColor",
                    "hideHomeButton",

                    "setBackgroundTextStyle",
                    "setBackgroundColor",

                    "showTabBarRedDot",
                    "hideTabBarRedDot",
                    "showTabBar",
                    "hideTabBar",
                    "setTabBarStyle",
                    "setTabBarItem",
                    "setTabBarBadge",
                    "removeTabBarBadge",

                    "operateCameraContext",
                    "onCameraFrame",

                    "operateVideoDecoder",
                                
                    "startAccelerometer",
                    "stopAccelerometer",
                    "onAccelerometerChange",
                    "offAccelerometerChange",
                    
                    "startCompass",
                    "stopCompass",
                    "onCompassChange",
                    "offCompassChange",
                    
                    "startDeviceMotionListening",
                    "stopDeviceMotionListening",
                    "onDeviceMotionChange",
                    "offDeviceMotionChange",
                    
                    "startGyroscope",
                    "stopGyroscope",
                    "onGyroscopeChange",
                    "offGyroscopeChange",
                    
                    "onMemoryWarning",
                    "offMemoryWarning",

                    "reverseWebView",
                    
                    "checkIsOpenAccessibility",

                    "openBluetoothAdapter",
                    "closeBluetoothAdapter",
                    "startBluetoothDevicesDiscovery",
                    "stopBluetoothDevicesDiscovery",
                    "getBluetoothAdapterState",
                    "getBluetoothDevices",
                    "getConnectedBluetoothDevices",
                    "onBluetoothDeviceFound",
                    "offBluetoothDeviceFound",
                    "onBluetoothAdapterStateChange",
                    "offBluetoothAdapterStateChange",
                    
                    "getBLEDeviceServices",
                    "getBLEDeviceRSSI",
                    "getBLEDeviceCharacteristics",
                    "createBLEConnection",
                    "closeBLEConnection",
                    "setBLEMTU",
                    "writeBLECharacteristicValue",
                    "readBLECharacteristicValue",
                    "notifyBLECharacteristicValueChange",
                    "onBLEConnectionStateChange",
                    "offBLEConnectionStateChange",
                    "onBLECharacteristicValueChange",
                    "offBLECharacteristicValueChange",
                    
                    "onBLEPeripheralConnectionStateChanged",
                    "offBLEPeripheralConnectionStateChanged",
                    "createBLEPeripheralServer",
                    "operateBLEPeripheralServer",
                    
                    "createVoIPRoom",
                    "updateVoIPChatMuteConfig",
                    "subscribeVoIPVideoMembers",
                    "setEnable1v1Chat",
                    "onVoIPVideoMembersChanged",
                    "onVoIPChatSpeakersChanged",
                    "onVoIPChatMembersChanged",
                    "onVoIPChatInterrupted",
                    "offVoIPVideoMembersChanged",
                    "offVoIPChatSpeakersChanged",
                    "offVoIPChatMembersChanged",
                    "offVoIPChatInterrupted",
                    "joinVoIPChat",
                    "join1v1Chat",
                    "exitVoIPChat",
                    
                    "createLivePusherContext",
                    "operateLivePusherContext",
                    "setLivePusherContextState",
                    
                    "createLivePlayerContext",
                    "operateLivePlayerContext",
                    "setLivePlayerContextState",
                    
                    "startBeaconDiscovery",
                    "stopBeaconDiscovery",
                    "onBeaconUpdate",
                    "onBeaconServiceChange",
                    "offBeaconUpdate",
                    "offBeaconServiceChange",
                    "getBeacons",

                    "startWifi",
                    "stopWifi",
                    "setWifiList",
                    "onWifiConnected",
                    "offWifiConnected",
                    "onGetWifiList",
                    "offGetWifiList",
                    "getWifiList",
                    "getConnectedWifi",
                    "connectWifi",
                    
                    "createMapContext",
                    "operateMapContext",
                    "setMapContextState"
    ];
    const syncApi = [
                    "getScreenHeightSync",
                    "getScreenWidthSync",
                    "getAppNameSync",
                    "getAppIdSync",
                    "getAppVersionCodeSync",
                    "getLaunchOptionsSync",
                    "getStorageSync",

                    "getSystemFreeSizeSync",
                    "getSimOperatorNameSync",
                    "getNetworkTypeSync",
                    "isMobileConnectedSync",

                    "isWifiConnectedSync",
                    "isNetworkConnectedSync",
                    "hasSimCardSync",
                    "getClipboardDataSync",
                    "getBatteryInfoSync",
                    "getOSVersionCodeSync",
                    "getDeviceTypeSync",
                    "getAppLogoSync",
                    "getDeviceIdSync",
                    "getSystemInfoSync",
                    "setStorageSync",
                               
                    "request",
//                    "operateRequestTask",
                    "uploadFile",
//                    "operateUploadTask",
                    "downloadFile",
//                    "operateDownloadTask",
                    

                    "createInnerAudioContext",
//                    "getInnerAudioDurationSync",
//                    "getInnerAudioCurrentTimeSync",
//                    "getInnerAudioPausedSync",
//                    "getInnerAudioBufferedSync",
                    "getBackgroundAudioState",
                    "getInnerAudioState",
                               
                    "createCameraContext",
                               
                    "createVideoDecoder",
                    "getFrameData",
        
    ];

    const log = function (params) {
        if (params == undefined) {
            params = {
                method: 'log',
                data: ''
            };
         } else {
             const args = []
             for (let index = 0; index < arguments.length; index++) {
                 const element = arguments[index];
                 args.push(element)
             }
             params = {
                 method: 'log',
                 data: args
             }
         }
        try {
            params = JSON.stringify(params);
        } catch (error) {
            params = {info: 'params fail to stringify'};  
        }
        window.webkit.messageHandlers.jsBridge.postMessage(params);
    }
   
    console.log = log;
    console.error = log;
    console.warn = log;

    window.onerror = function (errorMsg, url, lineNumber) {  
        console.log(`Error: ${errorMsg} Script: ${url} Line: ${lineNumber}`)
    }

    const asyncCall = function (name, params) {
        if (params == undefined) {
           params = {
               method: name
           };
        } else if (typeof(params) == "string") {
            try {
                params = JSON.parse(params);
                params.method = name;
            } catch (error) {
                params = {
                    method: name,
                    callback: params
                }
            }
        } else if (typeof(params) == "object") {
            params.method = name;
        }
        if (typeof(params) != "string") {
            params = JSON.stringify(params);
        }
        window.webkit.messageHandlers.jsBridge.postMessage(params);
    };

    const syncCall = function (name, params) {
        if (params == undefined) {
            params = {
                method: name
            };
         } else if (typeof(params) == "string") {
            try {
                params = JSON.parse(params);
                params.method = name;
            } catch (error) {
                console.log(error);
            }
         } else if (typeof(params) == "object") {
             params.method = name;
         }
        if (typeof(params) != "string") {
            params = JSON.stringify(params);
        }
        return window.prompt(name,params);
    }

    const jsBridge = {};

    AsyncApi.forEach(element => {
        jsBridge[element] = function(params) {
            asyncCall(element, params);
        }
    });

    syncApi.forEach(element => {
        jsBridge[element] = function(params) {
            return syncCall(element, params);
        }
    });
    
    jsBridge.log = function(params) {
        if (typeof(params) != "string") {
            params = JSON.stringify(params);
        }
        syncCall("log",params);
    }
    window.device = "IOS";
    window.__weappsNative = jsBridge;
})();
