
var id = 0;
const ComCallbackName = 'callbackName__';

// 回调
function callBack(err,res) {
    res = err == null || err == 'null' ? res : err;
    if (typeof res == 'object') {
        res = JSON.stringify(res);
    } 
    var p = document.getElementById('loginResult');
    p.innerText = res;
}

function imgCallback(err,res) {
    try {
        res = JSON.parse(res);
    } catch (error) {
        console.log(error);
    }
    var img = document.getElementById('img');
    if (res.base64 == undefined) {
        img.setAttribute('src',res);
    } else {
        img.setAttribute('src',res.base64);
    }
}

function imgVoidCallback(err,res) {
    res = JSON.parse(res);
    if (res == undefined) return;

    if (res != undefined) {
        if (res.tempFilePath) {
            var params = {
                callback: "imgCallback",
                data: {
                    src: res.tempFilePath
                }
            }
            callBack(err,res);
            window.__weappsNative.getBase64Image(JSON.stringify(params));
        } else {
            imgCallback(err,res.base64);
        }
    } else {
        callBack(err,res);
    }
}


function getCallbackName(callback) {
    let callbackName = ComCallbackName + (id++);
    window[callbackName] = function (err,args) {
        console.log(id, callbackName, args);
        callback(err,args);
//        delete window[callbackName];
    };
    return callbackName;
}

//打开新页面
function openWindow(url) 
{
    var params = {
        data: {
            url: url
        }
    }
    window.__weappsNative.navigateTo(JSON.stringify(params));
}

//微信登录测试
function login() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName
    }
    window.__weappsNative.weiXinLogin(JSON.stringify(params));
}


function shareWeb() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            platform: '2',
            url: 'www.tencent.com',
            title: '腾讯首页',
            description: '腾讯以技术丰富互联网用户的生活',
            base64: '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'
        }
    }
    window.__weappsNative.shareWebPage(JSON.stringify(params));
}

function shareImg() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            platform: '2',
            base64: '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'
        }
    }
    window.__weappsNative.shareImage(JSON.stringify(params));
}

function shareText() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            platform: '2',
            text: '腾讯首页',
        }
    }
    window.__weappsNative.shareText(JSON.stringify(params));
}


function getScreenWidth() {
    var params = {
    }
    callBack(null,window.__weappsNative.getScreenWidthSync(JSON.stringify(params)));
}

function getScreenHeight () {
    var params = {
    }
    callBack(null,window.__weappsNative.getScreenHeightSync(JSON.stringify(params)));
}


function createQrCode () {
    var codeInfo = document.getElementById('QrCode').value;
    var callbackName = getCallbackName(imgVoidCallback);
    var params = {
        callback: callbackName,
        data: {
            content: codeInfo,
            size: 200
        }
    }
    window.__weappsNative.createQrCode(JSON.stringify(params));
}

function scanCode () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback:"callBack",
    }
    window.__weappsNative.scanCode(JSON.stringify(params));
}

function openCamera () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            sourceType: ["camera"],
            count: 3
        }
    }
    window.__weappsNative.chooseImage(JSON.stringify(params));
}

function openAlbum () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            sourceType: ["album"],
            count: 3
        }
    }
    window.__weappsNative.chooseImage(JSON.stringify(params));
}

function chooseImage () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
//            sourceType: ["album","camera"],
            count: 3
        }
    }
    window.__weappsNative.chooseImage(JSON.stringify(params));
}

function chooseVideoFromAlbum () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            sourceType: ["album"],
            maxDuration: 10
        }
    }
    window.__weappsNative.chooseVideo(JSON.stringify(params));
}

function chooseVideoFromCamera () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            sourceType: ["camera"],
            maxDuration: 10,
            compressed: false
        }
    }
    window.__weappsNative.chooseVideo(JSON.stringify(params));
}

function chooseVideo () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            maxDuration: 10,
        }
    }
    window.__weappsNative.chooseVideo(JSON.stringify(params));
}

function chooseMedia () {
    var callbackName = getCallbackName(callBack);

    var params = {
        callback: callbackName,
        data: {
            maxDuration: 10,
            sourceType: ['album']
        }
    }
    window.__weappsNative.chooseMedia(JSON.stringify(params));
}

function getAppName () {
    var params = {
    }
    callBack(null,window.__weappsNative.getAppNameSync(JSON.stringify(params)));
}

function getAppVersionCode () {
    var params = {
    }
    callBack(null,window.__weappsNative.getAppVersionCodeSync(JSON.stringify(params)));
}

function getAppId () {
    var params = {
    }
    callBack(null,window.__weappsNative.getAppIdSync(JSON.stringify(params)));
}

function getAppLogo () {
    var params = {
    }
    imgCallback(null,window.__weappsNative.getAppLogoSync(JSON.stringify(params)));
}

function getSimOperatorName () {
    var params = {
    }
    callBack(null,window.__weappsNative.getSimOperatorNameSync(JSON.stringify(params)));
}

function getNetworkType () {
    var params = {
    }
    callBack(null,window.__weappsNative.getNetworkTypeSync(JSON.stringify(params)));
}
function isMobileConnected () {
    var params = {
    }
    callBack(null,window.__weappsNative.isMobileConnectedSync(JSON.stringify(params)));
}
function isWifiConnected () {
    var params = {
    }
    callBack(null,window.__weappsNative.isWifiConnectedSync(JSON.stringify(params)));
}
function isNetworkConnected () {
    var params = {
    }
    callBack(null,window.__weappsNative.isNetworkConnectedSync(JSON.stringify(params)));
}

function telCall () {
    var params = {
        data:{
            phoneNumber: '123456'
        }
    }
    window.__weappsNative.telCall(JSON.stringify(params))
}

function smsTo () {
    var params = {
        data:{
            phoneNumber: '123456'
        }
    }
    window.__weappsNative.smsTo(JSON.stringify(params))
}

function emailTo () {
    var params = {
        data:{
            email: '123456@qq.com'
        }
    }
    window.__weappsNative.emailTo(JSON.stringify(params))
}

function hasSimCard () {
    var params = {
    }
    callBack(null,window.__weappsNative.hasSimCardSync(JSON.stringify(params)));
}

function getClipboardData () {
    var params = {

    }
    callBack(null,window.__weappsNative.getClipboardDataSync(JSON.stringify(params)));
}

function setClipboardData () {
    var callbackName = getCallbackName(callBack)
    var params = {
        callback: callbackName,
        data: {
            data: 'clipboard content'
        }
    }
    window.__weappsNative.setClipboardData(JSON.stringify(params));
}

function getBatteryLevel () {
    var params = {
    }
    callBack(null,window.__weappsNative.getBatteryInfoSync(JSON.stringify(params)));
}

function addCalendarEvent () {
    var callbackName = getCallbackName(callBack)
    var params = {
        callback: callbackName,
        data: {
            title: '开会',
            description : '部门会议',
            reminderTime : 1592222708000
        }
    }
    window.__weappsNative.addCalendarEvent(JSON.stringify(params));
}

function getDeviceId () {
    var params = {
    }
    callBack(null,window.__weappsNative.getDeviceIdSync(JSON.stringify(params)));
}

function getOSVersionCode () {
    var params = {
    }
    callBack(null,window.__weappsNative.getOSVersionCodeSync(JSON.stringify(params)));
}

function getDeviceType () {
    var params = {
    }
    callBack(null,window.__weappsNative.getDeviceTypeSync(JSON.stringify(params)));
}

function getSystemFreeSize () {
    var params = {
    }
    callBack(null,window.__weappsNative.getSystemFreeSizeSync(JSON.stringify(params)));
}

function getSystemInfo () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName
    }
    window.__weappsNative.getSystemInfo(JSON.stringify(params));
}

function setStorage()
{
    var key = document.getElementById('storage_key').value;
    var value = document.getElementById('storage_value').value;
    var callbackName = getCallbackName(callBack)   
    var params = {
        callback: callbackName,
        data: {
            key: key,
            data: value
        }
    }
    window.__weappsNative.setStorage(JSON.stringify(params));
}

function getStorageCallback(err,res) {
    res = JSON.parse(res);
    document.getElementById('get_storage_value').innerText = res.data
}

function getStorage()
{
    var key = document.getElementById('get_storage_key').value;
    var params = {
        callback: 'getStorageCallback',
        data: {
            key: key,
        }
    }
    window.__weappsNative.getStorage(JSON.stringify(params));
}


function downloadFile() {
    var callbackName = getCallbackName(imgVoidCallback);

    var params = {
        callback: callbackName,
        data: {
            url: 'https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1592410449964&di=1a5b0467cf859766a9b50cd9522a1456&imgtype=0&src=http%3A%2F%2Fa0.att.hudong.com%2F56%2F12%2F01300000164151121576126282411.jpg'
        }
    }
    window.__weappsNative.downloadFile(JSON.stringify(params));
}

function faceVerify() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
        }
    }
    window.__weappsNative.faceVerify(JSON.stringify(params));

}

function previewImages() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            urls: [
                'https://www.tencent.com/data/index/index_detail_1.jpg',
                'https://www.tencent.com/data/index/index_detail_2.jpg',   
                'https://www.tencent.com/data/index/index_detail_3.jpg',
                'https://www.tencent.com/data/index/index_develop_bg1.jpg',
                'https://www.tencent.com/data/index/index_develop_bg2.jpg',
                'https://www.tencent.com/data/index/index_develop_bg3.jpg'
            ],
            current: 'https://www.tencent.com/data/index/index_develop_bg1.jpg'
          }
    }
    window.__weappsNative.previewImage(JSON.stringify(params));
}

function showToast () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            title: '测试Toast测试Toast测试Toast测试Toast测试Toast',
            icon :'success',
            duration: 3000,
            mask: true
          }
    }
    window.__weappsNative.showToast(JSON.stringify(params));
}

function showModal () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            title: '提示',
            content :'这是一个模态弹窗,这是一个模态弹窗,这是一个模态弹窗这是一个模态弹窗,这是一个模态弹窗,这是这是一个模态弹窗,这是一个模态弹窗,这是',
          }
    }
    window.__weappsNative.showModal(JSON.stringify(params));
}

function showLoading () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            title: '测试Toast',
            mask: false
          }
    }
    window.__weappsNative.showLoading(JSON.stringify(params));
}

function hideToast () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
    }
    window.__weappsNative.hideToast(JSON.stringify(params));
}

function hideLoading () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,

    }
    window.__weappsNative.hideLoading(JSON.stringify(params));
}

function showActionSheet () {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            itemList: ['A', 'B', 'C', 'D', 'E', 'F'],
          }
    }
    window.__weappsNative.showActionSheet(JSON.stringify(params));
}


function openLocation(err,res) {
    var res = JSON.parse(res);
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
            latitude: res.latitude,
            longitude: res.longitude,
            scale: 5
          }
    }
    window.__weappsNative.openLocation(JSON.stringify(params));
}


function getLocation () {
    var callbackName = 'openLocation';
    var params = {
        callback: callbackName,
        data: {
            type: 'gcj02',
            isHighAccuracy: true,
            highAccuracyExpireTime: 4000
          }
    }
    window.__weappsNative.getLocation(JSON.stringify(params));
}

function startLocationUpdate() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
          }
    }
    window.__weappsNative.startLocationUpdate(JSON.stringify(params));
}

function stopLocationUpdate() {
    var callbackName = getCallbackName(callBack);
    var params = {
        callback: callbackName,
        data: {
          }
    }
    window.__weappsNative.stopLocationUpdate(JSON.stringify(params));
}


function onLocationChange() {
    var params = {
        callback: 'callBack',
        data: {
          }
    }
    window.__weappsNative.onLocationChange(JSON.stringify(params));
}

function offLocationChange() {
    var params = {
        callback: 'callBack',
        data: {
          }
    }
    window.__weappsNative.offLocationChange(JSON.stringify(params));
}


function CameraContext(cameraId) {
    this.identifier = cameraId //相机id，由createCameraContext创建返回
    //type为setZoom | startRecord | stopRecord | takePhoto | startListening | stopListening
    this.operateCameraContext = function(type, callback, params) {
        params.operationType = type;
        params.identifier = this.identifier;
        params = {
            callback: callback,
            data: params
        }
        window.__weappsNative.operateCameraContext(JSON.stringify(params));
    }

    this.onCameraFrame = (callback, startCallback, stopCallback)=> {
        // var callback = ''  //callbackName
        // var startCallback = '' //startCallbackName
        // var stopCallback = '' //stopCallbackName
        var params = {
            identifier: this.identifier
        }
        var onCameraFrameParams = {
            callback: callback,
            data: params
        }
        window.__weappsNative.onCameraFrame(JSON.stringify(params));
        return {
            //开始监听 对应CameraFrameListener.start
            start: ()=> {
                this.operateCameraContext(startListening, startCallback, params)
            },
            //停止监听 CameraFrameListener.stop
            stop: ()=> {
                this.operateCameraContext(stopListening, stopCallback, params)
            }
        };
    }
}

//camera标签需设置css属性overflow: scroll; -webkit-overflow-scrolling: touch; 
//并且camera标签内部需要一个高度或者宽度大于camera标签的子标签。使camera标签能产生滚动效果
//建议设置camera子标签高度或者宽度足够大，避免后期改变camera标签大小时，子标签高度宽度不足导致camera滑动效果失效，进而导致同层渲染失效
function createCameraContext() {
    var params = {
        mode:'normal',  //应用模式，只在初始化时有效，不能动态变更
        resolution:'medium',  //分辨率，不支持动态修改
        devicePosition: 'back', //摄像头朝向
        flash: 'auto',      //闪光灯
        frameSize: 'medium',       //指定期望的相机帧数据尺寸
        bindstop: '',      //回调，摄像头在非正常终止时触发，如退出后台等情况
        binderror: '',     //回调，用户不允许使用摄像头时触发
        bindinitdone: '',  //回调，相机初始化完成时触发，e.detail = {maxZoom}
        bindscancode: '',  //回到，在扫码识别成功时触发，仅在 mode="scanCode" 时生效
        posistion: {
            top: 30,  //camera标签距离Window顶部距离
            left: 30,  //camera标签距离Window左边距离
            height: 300, //camera标签高度
            width: 300,  //camera标签宽度
            scrollHeight: 400 //camera标签可滚动高度，一般有子标签高度决定，非必传
        }
    }
    var cameraId = window.__weappsNative.createCameraContext(JSON.stringify(params));
}
