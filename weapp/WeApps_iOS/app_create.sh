
CMD_PlistBuddy="/usr/libexec/PlistBuddy"
CMD_Xcodebuild=$(which xcodebuild)
CMD_Security=$(which security)
CMD_Lipo=$(which lipo)
CMD_Codesign=$(which codesign)

## 日志格式化输出
function logit() {
    echo -e "\033[32m [APPCreateShell] \033[0m $@"
}

## 日志格式化输出
function errorExit(){

    echo -e "\033[31m【APPCreateShell】BUILD FAILED $@ \033[0m"
    exit 1
}

## 日志格式化输出
function warning(){
    echo -e "\033[33m【警告】$@ \033[0m"
}

##字符串版本号比较：大于等于
function versionCompareGE() { test "$(echo "$@" | tr " " "\n" | sort -rn | head -n 1)" == "$1"; }

## 解锁keychain
function unlockKeychain(){
    $CMD_Security unlock-keychain -p "$UNLOCK_KEYCHAIN_PWD" "$HOME/Library/Keychains/login.keychain" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    $CMD_Security unlock-keychain -p "$UNLOCK_KEYCHAIN_PWD" "$HOME/Library/Keychains/login.keychain-db" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    return 0
}

##  导入.p12文件到keychain
function loadCer(){
    
    local downloadCerPath="${PUBLIC_PATH}/cer.p12"
    
    # 下载证书到本地
    wget $P12_PATH -O $downloadCerPath

    ## 检查证书
    if [[ ! -f "$downloadCerPath" ]]; then
       errorExit "${downloadCerPath} 下载证书失败，请检查证书路径是否正确"
    fi
    
    $CMD_Security import "$downloadCerPath" -k "$HOME/Library/Keychains/login.keychain" -P "$P12_PWD" -T /usr/bin/codesign
    if [[ $? -ne 0 ]]; then
        errorExit "导入证书到keyChain失败，请检查证书密码是否正确"
    fi
    return 0
}

function downloadProvision(){
    
    local downloadPath="${PUBLIC_PATH}/weapps.mobileprovision"
    
    # 下载证书到本地
    wget $PROVISION_URL -O $downloadPath

    ## 检查证书
    if [[ ! -f "$downloadPath" ]]; then
       errorExit "${downloadPath} 下载provision失败，请检查证书路径是否正确"
    fi
    
    return 0
}

## 获取配置ID,主要是后续用了获取bundle id
function getConfigurationIds() {

    ##配置模式：Debug 或 Release
    local targetId=$2
    local pbxproj=$1/project.pbxproj
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
      local buildConfigurationListId=$($CMD_PlistBuddy -c "Print :objects:$targetId:buildConfigurationList" "$pbxproj")
      local buildConfigurationList=$($CMD_PlistBuddy -c "Print :objects:$buildConfigurationListId:buildConfigurations" "$pbxproj" | sed -e '/Array {/d' -e '/}/d' -e 's/^[ \t]*//')
      ##数组中存放的分别是release和debug对应的id
      local configurationTypeIds=$(echo $buildConfigurationList)
      echo $configurationTypeIds

}

function getConfigurationIdWithType(){

    local configrationType=$3
    local targetId=$2
    local pbxproj=$1/project.pbxproj
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi

    local configurationTypeIds=$(getConfigurationIds "$1" $targetId)
    for id in ${configurationTypeIds[@]}; do
    local name=$($CMD_PlistBuddy -c "Print :objects:$id:name" "$pbxproj")
    if [[ "$configrationType" == "$name" ]]; then
        echo $id
    fi
    done
}

function getInfoPlistFile()
{
    configurationId=$2
    local pbxproj=$1/project.pbxproj
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
   local  infoPlistFileName=$($CMD_PlistBuddy -c "Print :objects:$configurationId:buildSettings:INFOPLIST_FILE" "$pbxproj" )
   ## 替换$(SRCROOT)为.
   infoPlistFileName=${infoPlistFileName//\$(SRCROOT)/.}
      ### 完整路径
    infoPlistFilePath="$1/../$infoPlistFileName"
    echo $infoPlistFilePath
}

#设置Info.plist文件bundleIdentifier
function setBundleIdentifier () {
    local infoPlistFile=$1
    local bundleIdentifier=$2
    if [[ ! -f "$infoPlistFile" ]]; then
        exit 1
    fi
    if [[ $bundleIdentifier ]]; then
#    $CMD_PlistBuddy -c "Set :CFBundleIdentifier $bundleIdentifier" "$infoPlistFile"
    setKeyAndValueInPlist ":CFBundleIdentifier" "$bundleIdentifier" "string" $infoPlistFile
    fi
}

function setKeyAndValueInPlist()
{
    local key=$1
    local value=$2
    local valueType=$3
    local plist=$4
    
    echo $key
    echo $value

    local result=$($CMD_PlistBuddy -c "print ${key}" "${plist}")
    if [ -z "$result" ] ;then
        $CMD_PlistBuddy -c "Add ${key} $valueType $value" "$plist"
    else
        $CMD_PlistBuddy -c "Set ${key} $value" "$plist"
    fi
}

## 设置工程中Bundle Id
function setProjectBundleId()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local bundleId=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
#    $CMD_PlistBuddy -c "Set :objects:$configurationId:buildSettings:PRODUCT_BUNDLE_IDENTIFIER ${bundleId}" "$pbxproj"
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:PRODUCT_BUNDLE_IDENTIFIER" "$bundleId" "string" $pbxproj
}

## 获取bundle Id,分为Releae和Debug
function getProjectBundleId()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    local bundleId=$($CMD_PlistBuddy -c "Print :objects:$configurationId:buildSettings:PRODUCT_BUNDLE_IDENTIFIER" "$pbxproj" | sed -e '/Array {/d' -e '/}/d' -e 's/^[ \t]*//')
    echo $bundleId
}


function getProfileBundleId()
{
    local profile=$1
    local applicationIdentifier=$($CMD_PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< "$($CMD_Security cms -D -i "$profile" 2>/dev/null )")
    if [[ $? -ne 0 ]]; then
        exit 1;
    fi
    ##截取bundle id,这种截取方法，有一点不太好的就是：当applicationIdentifier的值包含：*时候，会截取失败,如：applicationIdentifier=6789.*
    local bundleId=${applicationIdentifier#*.}
    echo $bundleId
}

#设置工程文件中productName
function setProductName ()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local productName=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:PRODUCT_NAME" "$productName" "string" $pbxproj
}

#设置工程文件中可用架构
function setArchs ()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local archs=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:VALID_ARCHS" "$archs" "string" $pbxproj
}

## 设置工程中setCodeSignIdentifier
function setCodeSignIdentifier()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local codeSignIdentifier=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:CODE_SIGN_IDENTITY" "$codeSignIdentifier" "string" $pbxproj
}

## 设置工程中PROVISIONING_PROFILE_SPECIFIER
function setProvisionProfileSpecifier()
{
    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local profileSpecifier=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:PROVISIONING_PROFILE_SPECIFIER" "$profileSpecifier" "string" $pbxproj
}

##设置签名方式（手动/自动
function setManulCodeSigning ()
{

    local configurationId=$2
    local pbxproj=$1/project.pbxproj
    local codeSignIdentifier=$3
    if [[ ! -f "$pbxproj" ]]; then
        exit 1
    fi
    setKeyAndValueInPlist ":objects:$configurationId:buildSettings:CODE_SIGN_STYLE" "$codeSignIdentifier" "string" $pbxproj

}

#设置bundle display name
function setBundleDisplayName () {
    local infoPlistFile=$1
    local bundleDisplayName=$2
    if [[ ! -f "$infoPlistFile" ]]; then
        logit "set setBundleDisplayName error"
        exit 1
    fi
    if [[ $bundleDisplayName ]]; then
        setKeyAndValueInPlist ":CFBundleDisplayName" "$bundleDisplayName" "string" "$infoPlistFile"
    fi
}

#设置bundle name
function setBundleName () {
    local infoPlistFile=$1
    local bundleDisplayName=$2
    if [[ ! -f "$infoPlistFile" ]]; then
        logit "set CFBundleName error"
        exit 1
    fi
    if [[ $bundleDisplayName ]]; then
        setKeyAndValueInPlist ":CFBundleName" "$bundleDisplayName" "string" "$infoPlistFile"
    fi
}

#设置Info.plist文件版本号
function setProjectVersion () {
    local infoPlistFile=$1
    local projectVersion=$2
    if [[ ! -f "$infoPlistFile" ]]; then
        exit 1
    fi
    if [[ $projectVersion ]]; then
        setKeyAndValueInPlist ":CFBundleShortVersionString" "$projectVersion" "string" $infoPlistFile
#        $CMD_PlistBuddy -c "Set :CFBundleShortVersionString $projectVersion" "$infoPlistFile"
    fi
}

#设置微信 BundleURLSchemes 里面的wechatId
function setWechatURLSchemesId () {
    local infoPlistFile=$1
    local wechatId=$2
    if [[ ! -f "$infoPlistFile" ]]; then
        logit "set CFBundleURLTypes error"
        exit 1
    fi
    if [[ $wechatId ]]; then
        setKeyAndValueInPlist ":CFBundleURLTypes:0:CFBundleURLSchemes:0" "$wechatId" "string" "$infoPlistFile"
    fi
}

##匹配授权文件
function matchMobileProvisionFile()
{

    ##分发渠道
    local channel=$1
    local appBundleId=$2
    local publicPath=$4
    ##授权文件下载地址
    local mobileProvisionPath=$3
 
    if [[ ! -f "$mobileProvisionPath" ]]; then
        errorExit "【error】下载mobileprovision文件失败!"
    fi
    ##遍历
    local provisionFile=''
    local maxExpireTimestmap=0

    local bundleIdFromProvisionFile=$(getProfileBundleId "$mobileProvisionPath")
    if [[ "$bundleIdFromProvisionFile" ]] && [[ "$appBundleId" != "$bundleIdFromProvisionFile" ]]; then
        errorExit "【error】mobileprovision中appId不匹配!"
    fi
    local profileType=$(getProfileType "$mobileProvisionPath")
    if [[ "$profileType" != "$channel" ]]; then
        errorExit "【error】mobileprovision中分发渠道不匹配!"
    fi
    echo $mobileProvisionPath
}

##获取授权文件类型
function getProfileType()
{
    local profile=$1
    local profileType=''
    if [[ ! -f "$profile" ]]; then
        exit 1
    fi
    ##判断是否存在key:ProvisionedDevices
    local haveKey=$($CMD_Security cms -D -i "$profile" 2>/dev/null | sed -e '/Array {/d' -e '/}/d' -e 's/^[ \t]*//' | grep ProvisionedDevices)
    if [[ "$haveKey" ]]; then
        local getTaskAllow=$($CMD_PlistBuddy -c 'Print :Entitlements:get-task-allow' /dev/stdin <<< $($CMD_Security cms -D -i "$profile" 2>/dev/null ) )
        if [[ $getTaskAllow == true ]]; then
            profileType='development'
        else
            profileType='ad-hoc'
        fi
    else

        local haveKeyProvisionsAllDevices=$($CMD_Security cms -D -i "$profile" 2>/dev/null | grep ProvisionsAllDevices)
        if [[ "$haveKeyProvisionsAllDevices" != '' ]]; then
            provisionsAllDevices=$($CMD_PlistBuddy -c 'Print :ProvisionsAllDevices' /dev/stdin <<< "$($CMD_Security cms -D -i "$profile" 2>/dev/null)" )
            if [[ $provisionsAllDevices == true ]]; then
                profileType='enterprise'
            else
                profileType='app-store'
            fi
        else
            profileType='app-store'
        fi
    fi
    echo $profileType
}

##检查podfile是否存在
function  checkPodfileExist() {

    local podfile=$(find "$PROJECT_PATH" -maxdepth 1  -type f -iname "Podfile")
    if [[ -f "$podfile" ]]; then
        logit "【cocoapods】pod install";
        pod install
    fi
}

##查找xcworkspace工程启动文件
function findXcworkspace() {

    local xcworkspace=$(find "$PROJECT_PATH" -maxdepth 1  -type d -iname "*.xcworkspace")
    if [[ -d "$xcworkspace" ]] || [[ -f "${xcworkspace}/contents.xcworkspacedata" ]]; then
        echo $xcworkspace
    fi
}

##查找xcodeproj工程启动文件
function findXcodeproj() {

    local xcodeprojPath=$(find "$PROJECT_PATH" -maxdepth 1  -type d -iname "*.xcodeproj")
    if [[ ! -d "$xcodeprojPath" ]] || [[ ! -f "${xcodeprojPath}/project.pbxproj" ]]; then
        exit 1
    fi
    echo  $xcodeprojPath
}

## 初始化build.xcconfig配置文件
function initBuildXcconfig() {
    local xcconfigFile=$Tmp_Build_Xcconfig_File
    if [[ -f "$xcconfigFile" ]]; then
        ## 清空
        > "$xcconfigFile"
    else
        ## 生成文件
        touch "$xcconfigFile"
    fi
    echo $xcconfigFile
}

## 获取xcpretty安装路径
function getXcprettyPath() {
    xcprettyPath=$(which xcpretty)
    echo $xcprettyPath
}

## 获取workspace的项目路径列表
function getAllXcprojPathFromWorkspace() {
    local xcworkspace=$1;
    local xcworkspacedataFile="$xcworkspace/contents.xcworkspacedata";
    if [[ ! -f "$xcworkspacedataFile" ]]; then
        echo "xcworkspace 文件不存在";
        exit 1;
    fi
    local list=($(grep "location =" "$xcworkspacedataFile" | cut -d "\"" -f2 | cut -d ":" -f2))
    ## 补充完整路径
    local completePathList=()
    for xcproj in ${list[*]}; do
        local path="${xcworkspace}/../${xcproj}"
        ## 数组追加元素括号里面第一个参数不能用双引号，否则会多出一个空格
        completePathList=(${completePathList[*]} "$path")

    done
    echo "${completePathList[*]}"
}

## 获取xcproj的所有target
## 比分数组元素本身带有空格，所以采用字符串用“;”作为分隔符，而不是用数组。
function getAllTargetsInfoFromXcprojList() {
    ## 转换成数组
    local xcprojList=$1

    ## 因在mac 系统下 在for循环中无法使用map ，所以使用数组来代替，元素格式为 targetId:targetName:xcprojPath
    local wrapXcprojListStr='' ##
    ## 获取每个子工程的target
    for (( i = 0; i < ${#xcprojList[*]}; i++ )); do
        local xcprojPath=${xcprojList[i]};
        local pbxprojPath="${xcprojPath}/project.pbxproj"
        if [[ -f "$pbxprojPath" ]]; then
            # echo "$pbxprojPath"
            local rootObject=$($CMD_PlistBuddy -c "Print :rootObject" "$pbxprojPath")
            local targetIdList=$($CMD_PlistBuddy -c "Print :objects:${rootObject}:targets" "$pbxprojPath" | sed -e '/Array {/d' -e '/}/d' -e 's/^[ \t]*//')
            #括号用于初始化数组,例如arr=(1,2,3),括号用于初始化数组,例如arr=(1,2,3)
            local targetIds=($(echo $targetIdList));
            for targetId in ${targetIds[*]}; do
                local targetName=$($CMD_PlistBuddy -c "Print :objects:$targetId:name" "$pbxprojPath")
                local info="${targetId}:${targetName}:${xcprojPath}"
                if [[ "$wrapXcprojListStr" == '' ]]; then
                    wrapXcprojListStr="$info";
                else
                    wrapXcprojListStr="${wrapXcprojListStr};${info}";

                fi
            done
        fi
    done
    echo "$wrapXcprojListStr"

}

function getTargetInfoValue(){

    local targetInfo="$1"
    local key="$2"
    if [[ "$targetInfo" == "" ]] || [[ "$key" == "" ]]; then
        errorExit "【error】getTargetInfoValue 参数不能为空"
    fi

    ## 更换数组分隔符
    OLD_IFS="$IFS"
    IFS=":"
    local arr=($targetInfo)
    IFS="$OLD_IFS"
    if [[ ${#arr[@]} -lt 3 ]]; then
        errorExit "【error】getTargetInfoValue 函数出错"
    fi
    local value=''
    if [[ "$key"  == "id" ]]; then
        value=${arr[0]}
    elif [[ "$key" == "name" ]]; then
        value=${arr[1]}
    elif [[ "$key" == "xcproj" ]]; then
        value=${arr[2]}
    fi
    echo "$value"
}

### 开始构建归档，因为该函数里面逻辑较多，所以在里面添加了日志打印
function archiveBuild()
{
    local targetName=$1
    local xcconfigFile=$2
    local xcworkspacePath=$(findXcworkspace)
    local xcprojectpath=$(findXcodeproj)
    ## 暂时使用全局变量---
    archivePath="${Package_Dir}"/$targetName.xcarchive
    
    logit "【开始构建】开始构建app"
    ####################进行归档########################
    local cmd="$CMD_Xcodebuild archive"
    if [[ "$xcworkspacePath" ]]; then
 
        echo '开始xcworkspacePath'
        cmd="$cmd"" -workspace \"$xcworkspacePath\""
            
    elif [[ "$xcprojectpath" ]]; then
        echo '开始xcprojectpath'
        cmd="$cmd"" -project \"$xcprojectpath\""
    fi
    
    cmd="$cmd"" -scheme $targetName -archivePath \"$archivePath\" -configuration $CONFIGRATION_TYPE -xcconfig $xcconfigFile clean build"


    local xcpretty=$(getXcprettyPath)
    if [[ $VERBOSE ==  false ]] && [[ "$xcpretty" ]]; then
        ## 格式化日志输出
        cmd="$cmd"" | xcpretty "
    fi

    # 执行构建，set -o pipefail 为了获取到管道前一个命令xcodebuild的执行结果，否则$?一直都会是0
    eval "set -o pipefail && $cmd "
    if [[ $? -ne 0 ]]; then
        echo '归档失败'
        errorExit "【error 归档失败，请检查编译日志(编译错误、签名错误等)。"
    fi


     echo "$archivePath"
}

##获取Xcode 版本
function getXcodeVersion() {
    local xcodeVersion=`$CMD_Xcodebuild -version | head -1 | cut -d " " -f 2`
    echo $xcodeVersion
}


## 获取授权文件TeamID
function getProvisionfileTeamID()
{
    local provisionFile=$1
    if [[ ! -f "$provisionFile" ]]; then
        exit 1
    fi
    provisonfileTeamID=$($CMD_PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' /dev/stdin <<< $($CMD_Security cms -D -i "$provisionFile" 2>/dev/null))
    echo $provisonfileTeamID
}

## 获取授权文件名称
function getProvisionfileName()
{
    local provisionFile=$1
    if [[ ! -f "$provisionFile" ]]; then
        exit 1
    fi
    provisonfileName=$($CMD_PlistBuddy -c 'Print :Name' /dev/stdin <<< $($CMD_Security cms -D -i "$provisionFile" 2>/dev/null))
    echo $provisonfileName
}



function generateOptionsPlist(){
    local provisionFile=$1
    if [[ ! -f "$provisionFile" ]]; then
        exit 1
    fi

    local provisionFileTeamID=$(getProvisionfileTeamID "$provisionFile")
    local provisionFileType=$(getProfileType "$provisionFile")
    local provisionFileName=$(getProvisionfileName "$provisionFile")
    local provisionFileBundleID=$(getProfileBundleId "$provisionFile")
    local compileBitcode='<false/>'
    if [[ "$ENABLE_BITCODE" == 'YES' ]]; then
        compileBitcode='<true/>'
    fi


    local plistfileContent="
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
    <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n
    <plist version=\"1.0\">\n
    <dict>\n
    <key>teamID</key>\n
    <string>$provisionFileTeamID</string>\n
    <key>method</key>\n
    <string>$provisionFileType</string>\n
    <key>stripSwiftSymbols</key>\n
    <true/>\n
    <key>provisioningProfiles</key>\n
    <dict>\n
        <key>$provisionFileBundleID</key>\n
        <string>$provisionFileName</string>\n
    </dict>\n
    <key>compileBitcode</key>\n
    $compileBitcode\n
    </dict>\n
    </plist>\n
    "
    ## 重定向
    echo "$plistfileContent" > "$Tmp_Options_Plist_File"
    echo "$Tmp_Options_Plist_File"
}


function exportIPA() {

    local archivePath=$1
    local provisionFile=$2
    local targetName=${archivePath%.*}
    targetName=${targetName##*/}
    local xcodeVersion=$(getXcodeVersion)
    exportPath="${Package_Dir}"/${targetName}.ipa

    if [[ ! -f "$provisionFile" ]]; then
        exit 1
    fi

    ####################进行导出IPA########################
    local cmd="$CMD_Xcodebuild -exportArchive"
    ## >= 8.3
    if versionCompareGE "$xcodeVersion" "8.3"; then
        local optionsPlistFile=$(generateOptionsPlist "$provisionFile")
         cmd="$cmd"" -archivePath \"$archivePath\" -exportPath \"$Package_Dir\" -exportOptionsPlist \"$optionsPlistFile\""
    else
        cmd="$cmd"" -exportFormat IPA -archivePath \"$archivePath\" -exportPath \"$exportPath\""
    fi
    ##判断是否安装xcpretty
    xcpretty=$(getXcprettyPath)
    if [[ "$xcpretty" ]]; then
        ## 格式化日志输出
        cmd="$cmd | xcpretty -c"
    fi
    # 这里需要添加>/dev/null 2>&1; ，否则echo exportPath 作为函数返回参数，会带有其他信息
    eval "set -o pipefail && $cmd" ;
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
}

## 发现在 xcode >= 8.3.3 以上都不存在 ,在xcode8.2.1 存在
function repairXcentFile()
{

    local exportPath=$1
    local archivePath=$2
    local xcodeVersion=$(getXcodeVersion)

    ## 小于8.3(不包含8.3)
    if ! versionCompareGE "$xcodeVersion" "8.3"; then
        local appName=`basename "$exportPath" .ipa`
        local xcentFile="${archivePath}"/Products/Applications/"${appName}".app/archived-expanded-entitlements.xcent
        if [[ -f "$xcentFile" ]]; then
            # baxcent文件从archive中拷贝到IPA中
            unzip -o "$exportPath" -d /"$Package_Dir" >/dev/null 2>&1
            local app="${Package_Dir}"/Payload/"${appName}".app
            cp -af "$xcentFile" "$app" >/dev/null 2>&1
            ##压缩,并覆盖原有的ipa
            cd "${Package_Dir}"  ##必须cd到此目录 ，否则zip会包含绝对路径
            zip -qry  "$exportPath" Payload >/dev/null 2>&1 && rm -rf Payload
            cd - >/dev/null 2>&1
            ## 因为重新加压，文件名和路径都没有变化
            local ipa=$exportPath
            echo  "$ipa"
        fi
    fi
}


#构建完成，检查App
function checkIPA()
{
    local exportPath=$1
    if [[ ! -f "$exportPath" ]]; then
        exit 1
    fi
    local ipaName=$BUNDLE_DISPLAY_NAME
    ##解压强制覆盖，并不输出日志
    if [[ -d "${Package_Dir}/Payload" ]]; then
        rm -rf "${Package_Dir}/Payload"
    fi
    unzip -o "$exportPath" -d ${Package_Dir} >/dev/null 2>&1
    
    local app=${Package_Dir}/Payload/"${ipaName}".app
    codesign --no-strict -v "$app"
    if [[ $? -ne 0 ]]; then
        errorExit "【error】 签名检查：签名校验不通过！"
    fi
    logit "【签名校验】签名校验通过"
    if [[ ! -d "$app" ]]; then
        errorExit "【error】 解压失败！无法找到$app"
    fi

    local ipaInfoPlistFile=${app}/Info.plist
    local mobileProvisionFile=${app}/embedded.mobileprovision
    local appShowingName=`$CMD_PlistBuddy -c "Print :CFBundleName" $ipaInfoPlistFile`
    local appBundleId=`$CMD_PlistBuddy -c "print :CFBundleIdentifier" "$ipaInfoPlistFile"`
    local appVersion=`$CMD_PlistBuddy -c "Print :CFBundleShortVersionString" $ipaInfoPlistFile`
    local appBuildVersion=`$CMD_PlistBuddy -c "Print :CFBundleVersion" $ipaInfoPlistFile`

    


    local appCodeSignIdenfifier=$($CMD_Codesign -dvvv "$app" 2>/tmp/log.txt &&  grep Authority /tmp/log.txt | head -n 1 | cut -d "=" -f2)
    #支持最小的iOS版本
    local supportMinimumOSVersion=$($CMD_PlistBuddy -c "print :MinimumOSVersion" "$ipaInfoPlistFile")
    #支持的arch
    local supportArchitectures=$($CMD_Lipo -info "$app"/"$ipaName" | cut -d ":" -f 3)

    logit "【IPA 信息】名字:$appShowingName"
    # getEnvirionment
    # logit "配置环境kBMIsTestEnvironment:$currentEnvironmentValue"
    logit "【IPA 信息】bundleID:$appBundleId"
    logit "【IPA 信息】版本:$appVersion"
    logit "【IPA 信息】build:$appBuildVersion"
    logit "【IPA 信息】支持最低iOS版本:$supportMinimumOSVersion"
    logit "【IPA 信息】支持的archs:$supportArchitectures"
    logit "【IPA 信息】签名:$appCodeSignIdenfifier"
    ## 清除解压出来的Playload
    rm -rf ${Package_Dir}/Payload
}

## 获取授权文件UUID
function getProvisionfileUUID()
{
    local provisionFile=$1
    if [[ ! -f "$provisionFile" ]]; then
        exit 1
    fi
    provisonfileUUID=$($CMD_PlistBuddy -c 'Print :UUID' /dev/stdin <<< $($CMD_Security cms -D -i "$provisionFile" 2>/dev/null))
    echo $provisonfileUUID
}

## 获取profile type的中文名字
function getProfileTypeCNName()
{
    local profileType=$1
    local profileTypeName
    if [[ "$profileType" == 'app-store' ]]; then
        profileTypeName='商店分发'
    elif [[ "$profileType" == 'enterprise' ]]; then
        profileTypeName='企业分发'
    elif [[ "$profileType" == 'ad-hoc' ]]; then
        profileTypeName='内部测试(ad-hoc)'
    else
        profileTypeName='内部测试'
    fi
    echo $profileTypeName

}

## 添加一项配置
function setXCconfigWithKeyValue() {

    local key=$1
    local value=$2

    local xcconfigFile=$Tmp_Build_Xcconfig_File
    if [[ ! -f "$xcconfigFile" ]]; then
        exit 1
    fi

    if grep -q "[ ]*$key[ ]*=.*" "$xcconfigFile";then
        ## 进行替换
        sed -i "_bak" "s/[ ]*$key[ ]*=.*/$key = $value/g" "$xcconfigFile"
    else
        ## 进行追加(重定位)
        echo "$key = $value" >>"$xcconfigFile"
    fi
}


function finalIPAName ()
{

    local targetName=$1
    local apiEnvFile=$2
    local apiEnvVarName=$3
    local infoPlistFile=$4
    local channelName=$5

    if [[ ! -f "$infoPlistFile" ]]; then
        return;
    fi
        ## IPA和日志重命名
    local curDatte=`date +"%Y%m%d_%H%M%S"`
    local ipaName=${targetName}_${curDatte}
    local apiEnvValue=$(getIPAEnvValue "$apiEnvFile" "$apiEnvVarName")
    local projectVersion=$(getProjectVersion "$infoPlistFile")
    local buildVersion=$(getBuildVersion "$infoPlistFile")



    if [[ "$apiEnvValue" ]]; then
        local apiEnvName=''
        if [[ "$apiEnvValue" == 'YES' ]]; then
            apiEnvName='生产环境'
        elif [[ "$apiEnvValue" == 'NO' ]]; then
            apiEnvName='开发环境'
        else
            apiEnvName='未知环境'
        fi
        ipaName="$ipaName""_${apiEnvName}"
    fi
    ipaName="${ipaName}""_${channelName}""_${projectVersion}""(${buildVersion})"
    echo "$ipaName"
}

## 将appIcon下载并且裁剪至不同分辨率，前提是AppIcon.appiconset文件加载json文件已对应好各个图片名称
function clipsIcon() {
    local iconPath=$1
    local projectPath=$2
    local publicPath=$3
    
#    if [[ ! -f "$iconPath" ]]; then
#        errorExit "${iconPath} icon不存在，请检查路径是否正确"
#    fi
    
    if [[ ! -d "$projectPath" ]]; then
        errorExit "${projectPath} 项目路径错误，请检查项目路径是否正确"
    fi
    
    
    local downloadIconPath="${publicPath}/appIcon.png"

    ## 下载appIcon到本地
    wget $iconPath -O $downloadIconPath
    
    ## 检查下载结果
    if [[ ! -f "$downloadIconPath" ]]; then
        errorExit "${iconPath} 下载AppIcon失败，请检查AppIcon路径是否正确"
    fi
    
    local AppIconPath="${projectPath}/weapps/Assets.xcassets/AppIcon.appiconset"

    ##若默认路径错误，在项目路径中查找AppIcon.appiconset文件夹
    if [[ ! -d "$AppIconPath" ]]; then
        AppIconPath=`find "$projectPath" -maxdepth 5 -path "./.Trash" -prune -o -type d -name AppIcon.appiconset -print| head -n 1`
    fi
    
    if [[ ! -d "$AppIconPath" ]]; then
        errorExit "${AppIconPath} AppIcon目录错误，请检查AppIcon目录错误是否正确"
    fi
    
    local sizes="40 60 58 87 80 120 120 180 20 40 29 58 40 80 76 152 167 1024"

    for size in $sizes
    do
    ##剪裁AppIcon到AppIcon.appiconset路径
    sips -Z ${size} ${downloadIconPath} -o "${AppIconPath}/${size}x${size}.png"
    done
    
    ##生成57x57和512x512图片供OTA使用
    sizes="57 512"
    
    for size in $sizes
    do
    sips -Z ${size} ${downloadIconPath} -o "${size}x${size}.png"
    done
    
     ##删除appIcon
    rm -f "$downloadIconPath"
}

function copyImageToAssert()
{
    local imagePath=$1
    local projectPath=$2
    local publicPath=$3
#    if [[ ! -f "$imagePath" ]]; then
#    errorExit "${projectPath} launchImage不存在，请检查路径是否正确"
#    fi
    if [[ ! -d "$projectPath" ]]; then
    errorExit "${projectPath} 项目路径错误，请检查项目路径是否正确"
    fi
    
    local downloadPath="${publicPath}/launchImage.png"

    ## 下载appIcon到本地
    wget $imagePath -O $downloadPath
    
    ## 检查下载结果
    if [[ ! -f "$downloadPath" ]]; then
        errorExit "${imagePath} 下载launchImage失败，请检查launchImage路径是否正确"
    fi
    
    local appImagePath="${projectPath}/weapps/Assets.xcassets/launchImage.imageset/launchImage.png"
    if [[ ! -f "$appImagePath" ]]; then
        appImagePath=`find "$projectPath" -maxdepth 5 -path "./.Trash" -prune -o -type f -name launchImage.png -print| head -n 1`
    fi
    cp $downloadPath $appImagePath
    if [[ $? -ne 0 ]]; then
    errorExit "拷贝launchImage失败，请检查launchImage路径是否正确";
    fi
}

## 下载广告资源到指定位置
function downloadAndCopySplashSource () {
    local splashSourceUrl=$1
    local projectPath=$2

    if [[ ! -d "$projectPath" ]]; then
        errorExit "${projectPath} 项目路径错误，请检查项目路径是否正确"
    fi
    if [[ "$splashSourceUrl" =~ .mp4 ]];then
    wget $splashSourceUrl -O ${projectPath}/weapps/Resource/H5.bundle/bg_splash_video.mp4
    elif [[ "$splashSourceUrl" =~ .gif ]];then
    wget $splashSourceUrl -O ${projectPath}/weapps/Resource/H5.bundle/bg_splash_image.gif
    elif [[ "$splashSourceUrl" =~ .png ]];then
    wget $splashSourceUrl -O ${projectPath}/weapps/Resource/H5.bundle/bg_splash_image.png
    elif [[ "$splashSourceUrl" =~ .jpg ]];then
    wget $splashSourceUrl -O ${projectPath}/weapps/Resource/H5.bundle/bg_splash_image.jpg
    fi
}

## 将h5文件拷贝到H5.bundle里面
function copyH5File() {
    local H5FilePath=$1
    local projectPath=$2
    if [[ ! -d "$projectPath" ]]; then
        errorExit "${projectPath} 项目路径错误，请检查项目路径是否正确"
    fi
    if [[ ! -d "$H5FilePath" ]]; then
        errorExit "${H5FilePath} h5文件路径错误，请检查路径是否正确"
    fi
    
    cp -r $H5FilePath ${projectPath}/weapps/Resource/H5.bundle/
}


##拷贝第三方库到项目中
function copyVendorToProject() {
    local vendorPath=$1
    local projectPath=$2
    if [[ ! -d "$projectPath" ]]; then
        errorExit "${projectPath} 项目路径错误，请检查项目路径是否正确"
    fi
    if [[ ! -f "$vendorPath" ]]; then
        errorExit "${vendorPath} 三方库文件路径错误，请检查路径是否正确"
    fi
    unzip -o $vendorPath -d ${projectPath}/weapps/
    
    if [[ ! -d "${projectPath}/weapps/Vendor" ]]; then
        errorExit "${projectPath}/weapps/Vendor 解压三方库到项目中出错，请检查路径是否正确"
    fi
#    cp -r $vendorPath ${projectPath}/weapps/
}

##  导入.p12文件到keychain
function loadP12ToKeychain(){
    
#    local publicPath=$1
#    local downloadCerPath="${publicPath}/cer.p12"

    ## 下载证书到本地
#    wget $P12_PATH -O $downloadCerPath

    ## 检查证书
    if [[ ! -f "$P12_PATH" ]]; then
       errorExit "${P12_PATH} 下载证书失败，请检查证书路径是否正确"
    fi
    
    $CMD_Security import "$P12_PATH" -k "$HOME/Library/Keychains/login.keychain" -P "$P12_PWD" -T /usr/bin/codesign
    if [[ $? -ne 0 ]]; then
        errorExit "导入证书到keyChain失败，请检查证书密码是否正确"
    fi
    return 0
}

#######################################################

## 构建开始时间
startTimeSeconds=`date +%s`
##打包根目录
PUBLIC_PATH="$WORKSPACE"
##工程目录
PROJECT_PATH="${PUBLIC_PATH}/WeApps_iOS"
##开机密码
UNLOCK_KEYCHAIN_PWD='ww19901226'
##
BUILD_TARGET=''

##输出ipa文件名
IPA_FILE_NAME='Weapps'
##appid
BUNDLE_ID='com.tencent.weapps1'
##appName
BUNDLE_DISPLAY_NAME="Weapps"
##icon路径
LOGO_PATH=''
##启动图路径
LAUNCH_IMAGE_PATH=''
##版本号
PROJECT_VERSION='1.0'
##广告资源
SPLASH_RESOURCE=''
##启动广告url
SPLASH_URL=''
##启动广告倒计时
SPLASH_TIME=5
##点击广告页跳转的网页url
SPLASH_JUMP_URL=''
##H5代码压缩包路径
WEB_CODE_PATH="${PUBLIC_PATH}/preview"
##第三方库路径
VENDOR_PATH=""
##分发渠道
CHANNEL='app-store'

##微信AppId
WECHAT_APP_ID=''
##微信AppSecret
WECHAT_APP_SECRET=''
##bugly注册的AppID
BUGLY_ID=''
##bugly注册的key
BUGLY_KEY=''
##腾讯慧眼人脸认证ID
CLOUD_FACE_VERIFY_ID=''
##腾讯慧眼人脸认证key
CLOUD_FACE_VERIFY_KEY=''
##腾讯慧眼人脸认证license
CLOUD_FACE_VERIFY_LICENSE=''
##证书路径
P12_PATH=''
##证书密码
P12_PWD='123456'
##开机密码
UNLOCK_KEYCHAIN_PWD='ww19901226'
##mobileprovision文件所在文件夹
PROVISION_URL=''

CONFIGRATION_TYPE='Release'
ARCHS='armv7 arm64'
ENABLE_BITCODE='NO'
DEBUG_INFORMATION_FORMAT='dwarf'
AUTO_BUILD_VERSION='NO'
CODE_SIGN_STYLE='Manual'

Package_Dir="$PUBLIC_PATH"
## 脚本临时生成最终用于构建的配置
Tmp_Build_Xcconfig_File="$Package_Dir/build.xcconfig"
#Tmp_Log_File="$Package_Dir/`date +"%Y%m%d%H%M%S"`.log"
##临时文件目录
Tmp_Options_Plist_File="$Package_Dir/optionsplist.plist"


while [ "$1" != "" ]; do
    st=$1
    key=${st%%=*}
    value=${st#*=}
    
    case $key in
        public_path )
            PUBLIC_PATH="$value"
            PROJECT_PATH="${value}/WeApps_iOS"
            WEB_CODE_PATH="${value}/preview"
            OUT_PUT_PATH="$value"
           ;;
       output_path )
            OUT_PUT_PATH="$value"
           ;;
        file_name )
            IPA_FILE_NAME="$value"
            ;;
        appid )
            BUNDLE_ID="$value"
            ;;
        name )
            BUNDLE_DISPLAY_NAME="$value"
            ;;
        vendor_path )
            VENDOR_PATH="$value"
            ;;
        logo )
            LOGO_PATH="$value"
            ;;
        launch_image )
            LAUNCH_IMAGE_PATH="$value"
            ;;
        version )
            PROJECT_VERSION="$value"
            ;;
        cer_path )
            P12_PATH="$value"
            ;;
        cer_pwd )
            P12_PWD="$value"
            ;;
        mobileprovision )
            PROVISION_URL="$value"
            ;;
        channel )
            CHANNEL="$value"
            ;;
        splash_resource )
            SPLASH_RESOURCE="$value"
            ;;
        splash_url )
            SPLASH_URL="$value"
            ;;
        splash_time )
            SPLASH_TIME="$value"
            ;;
        splash_jump_url )
            SPLASH_JUMP_URL="$value"
            ;;
        web_code )
            WEB_CODE_PATH="$value"
            ;;
        weixin_appid )
            WECHAT_APP_ID="$value"
            ;;
        weixin_appsecret )
            WECHAT_APP_SECRET="$value"
            ;;
        bugly_id )
            BUGLY_ID="$value"
            ;;
        bugly_key )
            BUGLY_KEY="$value"
            ;;
        cloud_faceverify_id )
            CLOUD_FACE_VERIFY_ID="$value"
            ;;
        cloud_faceverify_key )
            CLOUD_FACE_VERIFY_KEY="$value"
            ;;
        cloud_faceverify_license )
            CLOUD_FACE_VERIFY_LICENSE="$value"
            ;;
        target)
            BUILD_TARGET="$value"
            ;;
        archs )
            ARCHS="$value"
            ;;
        debug )
            if [ $value=="true" ] ; then
                CONFIGRATION_TYPE='Debug'
            else
                CONFIGRATION_TYPE='Release'
            fi
            ;;
        keychain_pwd )
            UNLOCK_KEYCHAIN_PWD="$value"
            ;;
        -v | --verbose )
            VERBOSE=true
            ;;
        -V | --version )
            generalAPPCreateShellVersion
            ;;
         -x )
            set -x;;
        --show-profile-detail )
            getProfileInfo "$value"
            exit;
            ;;
          --enable-bitcode )
            ENABLE_BITCODE='YES'
            ;;
          --auto-buildversion )
            AUTO_BUILD_VERSION='YES'
            ;;
          --env-filename )
            API_ENV_FILE_NAME="$value"
            ;;
        --env-varname)
            API_ENV_VARNAME="$value"
            ;;
        --env-production)
            API_ENV_PRODUCTION="$value"
            ;;
        -h | --help )
            usage
            ;;
        * )
            usage
            ;;
    esac

    shift
done



# 下载并剪裁appIcon到项目中
clipsIcon "$LOGO_PATH" "$PROJECT_PATH" "$PUBLIC_PATH"

# 下载并复制image到项目中
copyImageToAssert "$LAUNCH_IMAGE_PATH" "$PROJECT_PATH" "$PUBLIC_PATH"

#下载广告资源到指定位置
downloadAndCopySplashSource "$SPLASH_RESOURCE" "$PROJECT_PATH"

copyH5File "$WEB_CODE_PATH" "$PROJECT_PATH"

## 解锁钥匙串
unlockKeychain
if [[ $? -eq 0 ]]; then
    logit "【钥匙串 】unlock-keychain";
else
    errorExit "【error】unlock-keychain 失败, 请使用-p 参数或者在user.xcconfig配置文件中指定密码";
fi

##证书导入到钥匙串
loadCer
if [[ $? -eq 0 ]]; then
    logit "【钥匙串 】导入p12证书到钥匙串中";
else
    errorExit "【error】导入p12证书 失败 ";
fi

## 获取xcproj 工程列表
xcworkspace=$(findXcworkspace)


xcprojPathList=()
if [[ "$xcworkspace" ]]; then
    
    logit "【构建信息】项目结构：多工程协同(workplace)"
    ##  外括号作用是转变为数组
    xcprojPathList=($(getAllXcprojPathFromWorkspace "$xcworkspace"))
    num=${#xcprojPathList[@]} ##数组长度
    if [[ $num -gt 1 ]]; then
        i=0
        for xcproj in ${xcprojPathList[*]}; do
            i=$(expr $i + 1)
            logit "【构建信息】工程${i}：${xcproj##*/}"
        done
    fi

else
    ## 查找xcodeproj 文件
    logit "【构建信息】项目结构：单工程"
    xcodeprojPath=$(findXcodeproj)
    if [[ "$xcodeprojPath" ]]; then
        logit "【构建信息】工程路径:$xcodeprojPath"
    else
        errorExit "【error】当前目录不存在.xcworkspace或.xcodeproj工程文件，请在项目工程目录下执行脚本$(basename $0)"
    fi
    xcprojPathList=("$xcodeprojPath")
fi


## 构建的xcprojPath列表,即除去Pods.xcodeproj之外的
buildXcprojPathList=()

for (( i = 0; i < ${#xcprojPathList[*]}; i++ )); do
    path=${xcprojPathList[i]};
    if [[ "${path##*/}" == "Pods.xcodeproj" ]]; then
        continue;
    fi
    ## 数组追加元素括号里面第一个参数不能用双引号，否则会多出一个空格
    buildXcprojPathList=(${buildXcprojPathList[*]} "$path")
done
logit "【构建信息】可构建的工程数量（不含Pods）:${#buildXcprojPathList[*]}"


## 获取可构建的工程列表的所有target
targetsInfoListStr=$(getAllTargetsInfoFromXcprojList "${buildXcprojPathList[*]}")


## 设置数组分隔符号为分号
OLD_IFS="$IFS" ##记录当前分隔符号
IFS=";"
targetsInfoList=($targetsInfoListStr)

logit "【构建信息】可构建的Target数量（不含Pods）:${#targetsInfoList[*]}"


i=1
for targetInfo in ${targetsInfoList[*]}; do
    tId=$(getTargetInfoValue "$targetInfo" "id")
    tName=$(getTargetInfoValue "$targetInfo" "name")
    logit "【构建信息】可构建Target${i}：${tName}"
    i=$(expr $i + 1 )
done

IFS="$OLD_IFS" ##还原



##获取构建的targetName和targetId 和构建的xcodeprojPath
targetName=''
targetId=''
xcodeprojPath=''
if [[ "$BUILD_TARGET" ]]; then
    for targetInfo in ${targetsInfoList[*]}; do
        tId=$(getTargetInfoValue "$targetInfo" "id")
        tName=$(getTargetInfoValue "$targetInfo" "name")
        path=$(getTargetInfoValue "$targetInfo" "xcproj")
        if [[ "$tName" == "$BUILD_TARGET" ]]; then
            targetName="$tName"
            targetId="$tId"
            xcodeprojPath="$path"
            break;
        fi

    done
else
        ## 默认选择第一个target
    targetInfo=${targetsInfoList[0]}
    targetId=$(getTargetInfoValue "$targetInfo" "id")
    targetName=$(getTargetInfoValue "$targetInfo" "name")
    xcodeprojPath=$(getTargetInfoValue "$targetInfo" "xcproj")
fi



logit "【构建信息】构建Target：${targetName}（${targetId}）"

if [[ ! "targetName" ]] || [[ ! "targetId" ]] || [[ ! "xcodeprojPath" ]]; then
    errorExit "【error】获取构建信息失败!"
fi


##获取构配置类型的ID （Release和Debug分别对应不同的ID）
configurationTypeIds=$(getConfigurationIds "$xcodeprojPath" "$targetId")
if [[ ! "$configurationTypeIds" ]]; then
    errorExit "【error】获取配置模式(Release和Debug)Id列表失败"
fi

## 获取当前构建的配置模式ID
configurationId=$(getConfigurationIdWithType "$xcodeprojPath" "$targetId" "$CONFIGRATION_TYPE")
if [[ ! "$configurationId" ]]; then
    errorExit "【error】获取${CONFIGRATION_TYPE}配置模式Id失败"
fi
logit "【构建信息】配置模式：$CONFIGRATION_TYPE"



infoPlistFile=$(getInfoPlistFile "$xcodeprojPath" "$configurationId")
if [[ ! -f "$infoPlistFile" ]]; then
    echo "$xcodeprojPath"
    errorExit "【error】获取info.Plist文件失败"
fi
logit "【构建信息】InfoPlist 文件：$infoPlistFile"


## 设置info.plist文件bundleId
setBundleIdentifier "$infoPlistFile" "$BUNDLE_ID"

## 获取debug 和 release 对应的 ConfigurationId
debugConfigurationId=$(getConfigurationIdWithType "$xcodeprojPath" "$targetId" "Debug")
releaseConfigurationId=$(getConfigurationIdWithType "$xcodeprojPath" "$targetId" "Release")

# 设置项目文件里面debug和release下bundleId

#setProjectBundleId "$xcodeprojPath" "$debugConfigurationId" "$BUNDLE_ID"
#setProjectBundleId "$xcodeprojPath" "$releaseConfigurationId" "$BUNDLE_ID"

# 设置项目文件里面debug和release下productName
setProductName "$xcodeprojPath" "$debugConfigurationId" "$BUNDLE_DISPLAY_NAME"
setProductName "$xcodeprojPath" "$releaseConfigurationId" "$BUNDLE_DISPLAY_NAME"

# 设置项目文件里面debug和release下archs
#setArchs "$xcodeprojPath" "$debugConfigurationId" "$ARCHS"
#setArchs "$xcodeprojPath" "$releaseConfigurationId" "$ARCHS"


## 设置手动签名
#setManulCodeSigning "$xcodeprojPath" "$debugConfigurationId" "$CODE_SIGN_STYLE"
#setManulCodeSigning "$xcodeprojPath" "$releaseConfigurationId" "$CODE_SIGN_STYLE"

## 设置签名方式
setCodeSignIdentifier "$xcodeprojPath" "$debugConfigurationId" "iPhone Developer"
setCodeSignIdentifier "$xcodeprojPath" "$releaseConfigurationId" "iPhone Distribution"

#设置包显示名
setBundleDisplayName "$infoPlistFile" "$BUNDLE_DISPLAY_NAME"

setBundleName "$infoPlistFile" "$BUNDLE_DISPLAY_NAME"

#设置版本号
setProjectVersion "$infoPlistFile" "$PROJECT_VERSION"

#设置微信Id
setWechatURLSchemesId "$infoPlistFile" "$WECHAT_APP_ID"

## 获取Bundle Id
if [[ $BUNDLE_ID ]]; then
    ## 重新指定Bundle Id
    projectBundleId=$BUNDLE_ID
else
    ## 获取工程中的Bundle Id
    projectBundleId=$(getProjectBundleId "$xcodeprojPath" "$configurationId")
    if [[ ! "$projectBundleId" ]] ; then
        errorExit "获取项目的Bundle Id失败"
    fi
fi
logit "【构建信息】Bundle Id：$projectBundleId"

logit "【构建信息】下载并进行授权文件匹配..."
## 匹配授权文件
downloadProvision

PROVISION_URL="${PUBLIC_PATH}/weapps.mobileprovision"
provisionFile=$(matchMobileProvisionFile "$CHANNEL" "$projectBundleId" "$PROVISION_URL" "${PUBLIC_PATH}")
if [[ ! "$provisionFile" ]]; then
    errorExit "【error】不存在Bundle Id 为 ${projectBundleId} 且分发渠道为${CHANNEL}的授权文件，请检查${PROVISION_URL}目录是否存在对应授权文件"
fi
##导入授权文件
open "$provisionFile"

logit "【构建信息】匹配授权文件：$provisionFile"

### 进行构建配置信息覆盖，关闭BitCode、签名手动、配置签名等
xcconfigFile=$(initBuildXcconfig)
if [[ "$xcconfigFile" ]]; then
    logit "【签名设置】初始化XCconfig配置文件：$xcconfigFile"
fi
setXCconfigWithKeyValue "ENABLE_BITCODE" "$ENABLE_BITCODE"
setXCconfigWithKeyValue "DEBUG_INFORMATION_FORMAT" "$DEBUG_INFORMATION_FORMAT"
setXCconfigWithKeyValue "CODE_SIGN_STYLE" "$CODE_SIGN_STYLE"
setXCconfigWithKeyValue "PROVISIONING_PROFILE_SPECIFIER" "$(getProvisionfileName "$provisionFile")"
setXCconfigWithKeyValue "PROVISIONING_PROFILE" "$(getProvisionfileUUID "$provisionFile")"
setXCconfigWithKeyValue "DEVELOPMENT_TEAM" "$(getProvisionfileTeamID "$provisionFile")"
#setXCconfigWithKeyValue "CODE_SIGN_IDENTITY" "$codeSignIdentity"
setXCconfigWithKeyValue "PRODUCT_BUNDLE_IDENTIFIER" "$projectBundleId"
setXCconfigWithKeyValue "ARCHS" "$ARCHS"


## podfile 检查
checkPodfileExist

## 开始归档。
## 这里使用a=$(...)这种形式会导致xocdebuild日志只能在函数archiveBuild执行完毕的时候输出；
## archivePath 在函数archiveBuild 是全局变量
archivePath=''
archiveBuild "$targetName" "$Tmp_Build_Xcconfig_File"
logit "【归档信息】项目构建成功，文件路径：$archivePath"

# 开始导出IPAexportIPA
exportPath=''
exportIPA  "$archivePath" "$provisionFile"
if [[ ! "$exportPath" ]]; then
    errorExit "【error】IPA导出失败，请检查日志。"
fi
logit "【IPA 导出】IPA导出成功，文件路径：$exportPath"
if [[ ! "$ipaName" ]]; then
    ipaName=$targetName
fi


## 修复8.3 以下版本的xcent文件
xcentFile=$(repairXcentFile "$exportPath" "$archivePath")
if [[ "$xcentFile" ]]; then
    logit "【xcent 文件修复】拷贝archived-expanded-entitlements.xcent 到${xcentFile}"
fi


##备份dsym文件

dsym=$(find "${archivePath}/dSYMs" -name "*.dSYM" | head -1)
if [[ -d "$dsym" ]]; then
    cd "${archivePath}/dSYMs"
    tar -czvf  "$Package_Dir/dsym.tar.gz"  "${dsym##*/}"  2>/dev/null
fi


## 检查IPA
checkIPA "$exportPath"

##清理临时文件
rm -rf "$Tmp_Options_Plist_File"
rm -rf "$Tmp_Build_Xcconfig_File"
rm -rf "$archivePath"
rm -rf "$Package_Dir/Packaging.log"
rm -rf "$Package_Dir/ExportOptions.plist"
rm -rf "$Package_Dir/DistributionSummary.plist"


## IPA和日志重命名
logit "【IPA 信息】IPA和日志重命名"
exportDir=${exportPath%/*}


if [ -z $IPA_FILE_NAME ]; then
    IPA_FILE_NAME=$(finalIPAName "$targetName" "$apiEnvFile" "$API_ENV_VARNAME" "$infoPlistFile" "$(getProfileTypeCNName $CHANNEL)")
fi
logit "【IPA 信息】IPA路径:${exportDir}/${IPA_FILE_NAME}.ipa"
logit "【IPA 信息】日志路径:${exportDir}/${IPA_FILE_NAME}.log"



##结束时间
endTimeSeconds=`date +%s`
logit "【构建成功】BUILD SUCCESSFUL"
logit "【构建时长】构建时长：$((${endTimeSeconds}-${startTimeSeconds})) 秒"

mv "$exportPath"     "${exportDir}/${IPA_FILE_NAME}.ipa"


