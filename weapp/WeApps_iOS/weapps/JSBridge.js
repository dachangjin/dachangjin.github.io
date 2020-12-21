
(function(){
    var AsyncApi = [
        "navigateTo",
                   
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
        "getBase64Image",
        "saveBase64Image",
        "getFileSize",
        "deleteFile",
        "createFile",
        "createFolder",
        "telCall",
        "smsTo",
        "emailTo",
        "setClipboardData",
        "addCalendarEvent",
        "saveImageToPhotosAlbum",
        "compressImage",
        "getSystemInfo",
        "chooseImage",
        "downloadFile",
        "uploadFile",
        "saveFile",
        "getFileInfo",
        "getSavedFileList",
        "removeSavedFile",
        "openDocument",
        "hideKeyboard",
        "getBatteryInfo",
        "onKeyboardHeightChange",
        "offKeyboardHeightChange",
        "pageScrollTo",
        "setScreenBrightness",
        "getScreenBrightness",
        "setKeepScreenOn",
        "faceVerify",
        "getSimInfo",
        "getClipboardData",
        "getNetworkType",
        "getSimOperatorName",
        "getSystemFreeSize",
        "getStorage",
        "getAppId",
        "getAppName",
        "getScreenWidth",
        "getScreenHeight",
        "previewImage",
        "saveVideoToPhotosAlbum",
        "hideToast",
        "showLoading",
        "hideLoading",
        "showActionSheet",
        "showModal",
        "vibrateLong",
        "vibrateShort",
        "chooseVideo",
        "chooseMedia",
        "compressVideo",
        "stopLocationUpdate",
        "startLocationUpdateBackground",
        "startLocationUpdate",
        "openLocation",
        "onLocationChange",
        "offLocationChange",
        "getLocation",
        "chooseLocation"



    ];
    var syncApi = [
        "getScreenHeightSync",
        "getScreenWidthSync",
        "getAppNameSync",
        "getAppIdSync",
        "getAppVersionCodeSync",
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
        "setStorageSync"
        
        
                    
        
    ];

    var log = function (params) {
        if (params == undefined) {
            params = {
                method: 'log',
                data: ''
            };
         } else {
             params = {
                 method: 'log',
                 data: params
             }
         }
        params = JSON.stringify(params);
        window.webkit.messageHandlers.jsBridge.postMessage(params);
    }
   
    console.log = log;
    console.error = log;
    console.warn = log;

    window.onerror = function (errorMsg, url, lineNumber) {  
        console.log('Error: ' + errorMsg + ' Script: ' + url + ' Line: ' + lineNumber);   
    }

    var syncCall = function (name, params) {
        if (params == undefined) {
           params = {
               method: name
           };
        } else if (typeof(params) == "string") {
            try {
                params = JSON.parse(params);
                params.method = name;
            } catch (error) {
                //可能param就是个字符串参数，为了适配安卓那边，有的只传了一个callback，此时params就是callback
                // console.log(error);
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

    var asyncCall = function (name, params) {
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

    var jsBridge = {};

    AsyncApi.forEach(element => {
        jsBridge[element] = function(params) {
            syncCall(element, params);
        }
    });

    syncApi.forEach(element => {
        jsBridge[element] = function(params) {
            return asyncCall(element, params);
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
