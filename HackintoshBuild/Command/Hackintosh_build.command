#!/bin/bash

start=$(date +%s)
url=$1
cd $url
dir=hackintosh_Plugins
if [ ! -e $dir ]; then
    mkdir -p $dir/Release
    mkdir -p $dir/Sources
fi
cd $dir/Sources

proxy=$3
if [ $proxy!='' ]; then
export http_proxy=$proxy
export https_proxy=$proxy
fi

path=$5
if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
echo "您尚未安装nasm,现在为您安装"
osascript <<EOF
do shell script "mkdir -p /usr/local/bin || exit 1; cp ${path%/*}/nasm /usr/local/bin/ || exit 1; cp ${path%/*}/ndisasm /usr/local/bin/ || exit 1" with prompt "安装nsam需要授权" with administrator privileges
EOF
fi

if [ "$(which mtoc.NEW)" == "" ] || [ "$(which mtoc)" == "" ]; then
echo "您尚未安装mtoc,现在为您安装"
osascript <<EOF
do shell script "mkdir -p /usr/local/bin || exit 1; cp ${path%/*}/mtoc /usr/local/bin/mtoc || exit 1; cp ${path%/*}/mtoc /usr/local/bin/mtoc.NEW || exit 1" with prompt "安装mtoc需要授权" with administrator privileges
EOF
fi

buildArray=(
'OpenCore,https://github.com/acidanthera/OpenCorePkg.git'
'n-d-k-OpenCore,https://github.com/n-d-k/OpenCorePkg.git'
'AppleSupportPkg,https://github.com/acidanthera/AppleSupportPkg.git'
'Lilu,https://github.com/acidanthera/Lilu.git'
'AirportBrcmFixup,https://github.com/acidanthera/AirportBrcmFixup.git'
'AppleALC,https://github.com/acidanthera/AppleALC.git'
'ATH9KFixup,https://github.com/chunnann/ATH9KFixup.git'
'BT4LEContinuityFixup,https://github.com/acidanthera/BT4LEContinuityFixup.git'
'CPUFriend,https://github.com/acidanthera/CPUFriend.git'
'HibernationFixup,https://github.com/acidanthera/HibernationFixup.git'
'NoTouchID,https://github.com/al3xtjames/NoTouchID.git'
'RTCMemoryFixup,https://github.com/acidanthera/RTCMemoryFixup.git'
'SystemProfilerMemoryFixup,https://github.com/Goldfish64/SystemProfilerMemoryFixup.git'
'VirtualSMC,https://github.com/acidanthera/VirtualSMC.git'
'acidanthera_WhateverGreen,https://github.com/acidanthera/WhateverGreen.git'
'bugprogrammer_WhateverGreen,https://github.com/bugprogrammer/WhateverGreen.git'
'IntelMausiEthernet,https://github.com/Mieze/IntelMausiEthernet.git'
'AtherosE2200Ethernet,https://github.com/Mieze/AtherosE2200Ethernet.git'
'RTL8111,https://github.com/Mieze/RTL8111_driver_for_OS_X.git'
'NVMeFix,https://github.com/acidanthera/NVMeFix.git'
'MacProMemoryNotificationDisabler,https://github.com/IOIIIO/MacProMemoryNotificationDisabler.git'
)

liluPlugins='AirportBrcmFixup AppleALC ATH9KFixup BT4LEContinuityFixup CPUFriend HibernationFixup NoTouchID RTCMemoryFixup SystemProfilerMemoryFixup VirtualSMC acidanthera_WhateverGreen bugprogrammer_WhateverGreen NVMeFix MacProMemoryNotificationDisabler'

bootLoader='OpenCore n-d-k-OpenCore AppleSupportPkg'

if [[ $4 == "" ]]; then
    logs=/dev/null
else
    if [ -e $4/buildlog ]; then
        rm -rf $4/buildlog
    fi
    mkdir $4/buildlog
fi

selectList=$2
selectedArray=(`echo $selectList | tr ',' ' '`)
for i in ${selectedArray[*]}; do
    if [[ $4 != "" ]]; then
        logs=$4/buildlog/${buildArray[$i]%,*}.log
    fi
    echo "正在编译"${buildArray[$i]%,*}
    if [ -e ../Release/${buildArray[$i]%,*} ]; then
        rm -rf ../Release/${buildArray[$i]%,*}
    fi
    mkdir -p ../Release/${buildArray[$i]%,*}/Release
    mkdir -p ../Release/${buildArray[$i]%,*}/Debug
    if [ -e ./${buildArray[$i]%,*} ]; then
        rm -rf ./${buildArray[$i]%,*}
    fi
    git clone -q ${buildArray[$i]##*,} ${buildArray[$i]%,*} -b master --depth=1
    pushd ${buildArray[$i]%,*}

    if [[ $bootLoader =~ ${buildArray[$i]%,*} ]]; then
        if [[ ${buildArray[$i]%,*} == "n-d-k-OpenCore" ]]; then
            cp -rf ${path%/*}/macbuild-ndk.tool ./ndk-macbuild.tool
            ./ndk-macbuild.tool >> $logs || exit 1
        elif [[ ${buildArray[$i]%,*} == "OpenCore" ]]; then
            cp -rf ${path%/*}/macbuild-oc.tool ./macbuild.tool
            ./macbuild.tool >> $logs || exit 1
        else
            cp -rf ${path%/*}/macbuild-asp.tool ./macbuild.tool
            ./macbuild.tool >> $logs || exit 1
        fi
        cp Binaries/RELEASE/*.zip ../../Release/${buildArray[$i]%,*}/Release >> $logs || exit 1

        cp Binaries/DEBUG/*.zip ../../Release/${buildArray[$i]%,*}/Debug >> $logs || exit 1

        echo ${buildArray[$i]%,*}"编译成功"
    else
        if [[ $liluPlugins =~ ${buildArray[$i]%,*} ]]; then
            if [ ! -e *.kext ]; then
                echo ${buildArray[$i]%,*}"源码包里没有Lilu，现在编译Lilu"
                if [ ! -e $url/$dir/Sources/Lilu/build/Debug/Lilu.kext ]; then
                    pushd $url/$dir/Sources
                    git clone -q https://github.com/acidanthera/Lilu.git -b master --depth=1 && cd Lilu
                    xcodebuild -configuration Debug >> $logs || exit 1
                    popd
                    cp -Rf $url/$dir/Sources/Lilu/build/Debug/Lilu.kext . >> $logs || exit 1
                else
                    cp -Rf $url/$dir/Sources/Lilu/build/Debug/Lilu.kext . >> $logs || exit 1
                fi
            fi
        fi
        xcodebuild -configuration Release >> $logs || exit 1
        xcodebuild -configuration Debug >> $logs || exit 1
        if [ -e build/Release/*.zip ]; then
            cp -Rf build/Release/*.zip ../../Release/${buildArray[$i]%,*}/Release >> $logs || exit 1
            cp -Rf build/Debug/*.zip ../../Release/${buildArray[$i]%,*}/Debug >> $logs || exit 1
            echo ${buildArray[$i]%,*}"编译成功"
        else
            cp -Rf build/Release/*.kext ../../Release/${buildArray[$i]%,*}/Release/${buildArray[$i]%,*}-Release.kext >> $logs || exit 1
            cp -Rf build/Debug/*.kext ../../Release/${buildArray[$i]%,*}/Debug/${buildArray[$i]%,*}-Debug.kext >> $logs || exit 1
            echo ${buildArray[$i]%,*}"编译成功"
        fi
    fi
    popd
done;

if [[ $4 != "" ]]; then
    open $4/buildlog/
fi
open $url/$dir/Release

end=$(date +%s)
take=$(( end - start ))
echo 编译结束程序执行了${take}秒.
