# Qt Creator Kit Setup for STM32MP135 Qt6 SDK

## Overview
Qt Creator မှာ Yocto SDK ကို kit အနေနဲ့ configure လုပ်ပြီး cross-compile နဲ့ remote debugging လုပ်နည်း။

---

## Prerequisites

### 1. SDK Installation
```bash
# SDK installer ကို run ပြီးသား
~/stm32mp1-sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

# SDK activate လုပ်ဖို့ script
source ~/setup_stm32mp135_sdk.sh
```

### 2. Qt Creator Installation
```bash
# Qt Creator install (Ubuntu 22.04)
sudo apt update
sudo apt install qtcreator

# သို့မဟုတ် Qt Online Installer မှ download
# https://www.qt.io/download-qt-installer
```

---

## Step 1: SDK Environment Information

SDK activate လုပ်ပြီး environment variables များကို စစ်ပါ:

```bash
source ~/setup_stm32mp135_sdk.sh

# Important paths
echo "SDK ROOT: $SDKTARGETSYSROOT"
echo "Cross Compiler: $CC"
echo "C++ Compiler: $CXX"
echo "CMake Toolchain: $OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake"
echo "Qt6 Config: $SDKTARGETSYSROOT/usr/lib/cmake/Qt6"
```

**Expected Output:**
```
SDK ROOT: /home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
Cross Compiler: arm-ostl-linux-gnueabi-gcc
C++ Compiler: arm-ostl-linux-gnueabi-g++
CMake Toolchain: /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/share/cmake/OEToolchainConfig.cmake
Qt6 Config: /home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi/usr/lib/cmake/Qt6
```

---

## Step 2: Open Qt Creator Kit Configuration

### Launch Qt Creator
```bash
qtcreator
```

### Navigate to Kit Settings
1. **Tools** → **Options** → **Kits**
2. ဘယ်ဘက် sidebar မှာ အောက်ပါ tabs များ ရှိပါမယ်:
   - Qt Versions
   - Compilers
   - Debuggers
   - CMake
   - Kits

---

## Step 3: Configure Qt Version

### 3.1 Add Qt6 from SDK

1. **Qt Versions** tab ကို သွားပါ
2. **Add...** ကို နှိပ်ပါ
3. Browse to qmake location:
   ```
   /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/qmake
   ```
4. Version name: `Qt 6.8.4 (STM32MP1 SDK)`
5. **Apply** နှိပ်ပါ

**Verification:**
- Qt Version ပေါ်လာရမယ် (⚠️ warning မရှိဘူး)
- Qt version: 6.8.4
- ABI: arm-linux-generic-elf-32bit

---

## Step 4: Configure Compilers

### 4.1 Add C Compiler

1. **Compilers** tab ကို သွားပါ
2. **Add** → **GCC** → **C**
3. Configuration:
   - **Name:** `GCC ARM STM32MP1 (C)`
   - **Compiler path:**
     ```
     /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gcc
     ```
   - **ABI:** arm-linux-generic-elf-32bit
4. **Apply**

### 4.2 Add C++ Compiler

1. **Add** → **GCC** → **C++**
2. Configuration:
   - **Name:** `GCC ARM STM32MP1 (C++)`
   - **Compiler path:**
     ```
     /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-g++
     ```
   - **ABI:** arm-linux-generic-elf-32bit
3. **Apply**

---

## Step 5: Configure Debugger

### 5.1 Add GDB for ARM

1. **Debuggers** tab ကို သွားပါ
2. **Add**
3. Configuration:
   - **Name:** `GDB ARM STM32MP1`
   - **Path:**
     ```
     /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gdb
     ```
   - **Type:** GDB
   - **ABI:** arm-linux-generic-elf-32bit
4. **Apply**

---

## Step 6: Configure CMake

### 6.1 Add CMake from SDK

1. **CMake** tab ကို သွားပါ
2. **Add**
3. Configuration:
   - **Name:** `CMake (STM32MP1 SDK)`
   - **Path:**
     ```
     /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/cmake
     ```
4. **Apply**

---

## Step 7: Create Kit

### 7.1 Add New Kit

1. **Kits** tab ကို သွားပါ
2. **Add** button ကို နှိပ်ပါ
3. Configuration:

   **Name:**
   ```
   STM32MP135 Qt6 (Yocto SDK)
   ```

   **Device type:**
   - Generic Linux Device

   **Sysroot:**
   ```
   /home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   ```

   **Compiler:**
   - **C:** GCC ARM STM32MP1 (C)
   - **C++:** GCC ARM STM32MP1 (C++)

   **Debugger:**
   - GDB ARM STM32MP1

   **Qt version:**
   - Qt 6.8.4 (STM32MP1 SDK)

   **CMake Tool:**
   - CMake (STM32MP1 SDK)

   **CMake Configuration:**
   Click "Change..." button and add:
   ```
   CMAKE_TOOLCHAIN_FILE:FILEPATH=/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/share/cmake/OEToolchainConfig.cmake
   CMAKE_SYSROOT:PATH=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   OE_QMAKE_PATH_EXTERNAL_HOST_BINS:PATH=/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin
   ```

   **Environment:**
   Click "Change..." and add (SDK environment setup script မှ):
   ```
   PATH=/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin:/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/sbin:${PATH}
   PKG_CONFIG_PATH=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi/usr/lib/pkgconfig:/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi/usr/share/pkgconfig
   PKG_CONFIG_SYSROOT_DIR=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   CONFIG_SITE=/home/mr_robot/stm32mp1-sdk/site-config-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   OECORE_NATIVE_SYSROOT=/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux
   OECORE_TARGET_SYSROOT=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   OECORE_ACLOCAL_OPTS=-I /home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/share/aclocal
   OECORE_BASELIB=lib
   OECORE_TARGET_ARCH=arm
   OECORE_TARGET_OS=linux-gnueabi
   CC=arm-ostl-linux-gnueabi-gcc -mthumb -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7 -fstack-protector-strong -O2 -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   CXX=arm-ostl-linux-gnueabi-g++ -mthumb -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7 -fstack-protector-strong -O2 -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   CPP=arm-ostl-linux-gnueabi-gcc -E -mthumb -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7 -fstack-protector-strong -O2 -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   AS=arm-ostl-linux-gnueabi-as
   LD=arm-ostl-linux-gnueabi-ld --sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   GDB=arm-ostl-linux-gnueabi-gdb
   STRIP=arm-ostl-linux-gnueabi-strip
   RANLIB=arm-ostl-linux-gnueabi-ranlib
   OBJCOPY=arm-ostl-linux-gnueabi-objcopy
   OBJDUMP=arm-ostl-linux-gnueabi-objdump
   READELF=arm-ostl-linux-gnueabi-readelf
   AR=arm-ostl-linux-gnueabi-ar
   NM=arm-ostl-linux-gnueabi-nm
   M4=m4
   TARGET_PREFIX=arm-ostl-linux-gnueabi-
   CONFIGURE_FLAGS=--target=arm-ostl-linux-gnueabi --host=arm-ostl-linux-gnueabi --build=x86_64-linux --with-libtool-sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   CFLAGS= -O2 -pipe -g -feliminate-unused-debug-types
   CXXFLAGS= -O2 -pipe -g -feliminate-unused-debug-types
   LDFLAGS=-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -Wl,-z,relro,-z,now
   CPPFLAGS=
   KCFLAGS=--sysroot=/home/mr_robot/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
   OECORE_DISTRO_VERSION=5.0.8-snapshot-20251110
   OECORE_SDK_VERSION=5.0.8-snapshot-20251110
   ARCH=arm
   CROSS_COMPILE=arm-ostl-linux-gnueabi-
   ```

4. **Apply** → **OK**

---

## Step 8: Configure Remote Device

### 8.1 Add STM32MP135 Device

1. **Tools** → **Options** → **Devices**
2. **Add** → **Generic Linux Device** → **Start Wizard**
3. Configuration:
   - **Name:** `STM32MP135F-DK`
   - **Host name:** `192.168.7.1`
   - **SSH port:** `22`
   - **Username:** `root`
   - **Authentication:** Password
   - **Password:** (leave empty for no password)
4. **Next** → Test connection
5. **Finish**

### 8.2 Verify Device Connection
- Device status: "Device test finished successfully"
- Free ports: should show available ports

---

## Step 9: Test with Sample Project

### 9.1 Create Qt6 Widgets Application

```bash
mkdir -p ~/qt6_projects/hello_stm32
cd ~/qt6_projects/hello_stm32
```

**CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.16)
project(hello_stm32 VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

add_executable(hello_stm32
    main.cpp
)

target_link_libraries(hello_stm32 PRIVATE
    Qt6::Core
    Qt6::Widgets
)

install(TARGETS hello_stm32
    RUNTIME DESTINATION /home/root
)
```

**main.cpp:**
```cpp
#include <QApplication>
#include <QLabel>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    QWidget window;
    window.setWindowTitle("Hello STM32MP135");
    
    QVBoxLayout *layout = new QVBoxLayout(&window);
    
    QLabel *label = new QLabel("Hello from STM32MP135F-DK!\nQt 6.8.4 on Yocto Linux");
    label->setStyleSheet("QLabel { font-size: 24px; color: blue; }");
    label->setAlignment(Qt::AlignCenter);
    
    layout->addWidget(label);
    window.setLayout(layout);
    window.resize(400, 200);
    window.show();
    
    return app.exec();
}
```

### 9.2 Open in Qt Creator

1. **File** → **Open File or Project**
2. Select `CMakeLists.txt`
3. **Configure Project** dialog ပေါ်လာမယ်
4. Check only: **STM32MP135 Qt6 (Yocto SDK)**
5. Uncheck other kits
6. **Configure Project**

### 9.3 Build Settings

1. Left panel → **Projects** → **Build**
2. Build directory: `~/qt6_projects/hello_stm32/build-stm32mp135`
3. CMake configuration should show toolchain file automatically

### 9.4 Run Settings

1. **Projects** → **Run**
2. **Run configuration:** hello_stm32
3. **Deployment:**
   - Method: Upload files via SFTP
   - Remote executable: `/home/root/hello_stm32`
4. **Run Environment:**
   Add these variables:
   ```
   DISPLAY=:0
   QT_QPA_PLATFORM=wayland
   WAYLAND_DISPLAY=wayland-0
   XDG_RUNTIME_DIR=/run/user/0
   ```

### 9.5 Build and Deploy

1. **Build** → **Build Project "hello_stm32"**
2. Build output တွင် cross-compile ဖြစ်နေတာ တွေ့ရမယ်:
   ```
   arm-ostl-linux-gnueabi-g++ ... -o hello_stm32
   ```
3. **Build** → **Deploy Project "hello_stm32"**
4. File upload to board via SFTP

### 9.6 Run on Target

1. **Build** → **Run**
2. Application က board ရဲ့ display မှာ ပေါ်လာမယ်
3. Output window မှာ stdout/stderr ပြမယ်

---

## Step 10: Remote Debugging Setup

### 10.1 Debug Configuration

1. **Projects** → **Run** → Switch to **Debug**
2. **Debugger Settings:**
   - Use gdbserver on device
   - Port: 2345 (auto-select)
3. **Environment:**
   Same as Run configuration

### 10.2 Start Debugging

1. Set breakpoint in `main.cpp`
2. **Debug** → **Start Debugging** (F5)
3. Qt Creator will:
   - Deploy application
   - Start gdbserver on board
   - Connect with arm-ostl-linux-gnueabi-gdb
   - Stop at breakpoint

### 10.3 Debugging Features

- **Step Over (F10)**, **Step Into (F11)**, **Continue (F5)**
- **Locals and Expressions** window မှာ variables များ ကြည့်ရန်
- **Call Stack** window
- **Breakpoints** window
- **Application Output** window

---

## Troubleshooting

### Issue 1: Kit has no compiler
**Solution:** Compiler paths များ မှန်ကန်စွာ ထည့်ထားပါ။ SDK environment script က PATH မှာ ရှိတဲ့ compiler locations ကို စစ်ပါ။

### Issue 2: Qt version not detected
**Solution:** qmake path မှန်ရမယ်:
```bash
/home/mr_robot/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/qmake
```

### Issue 3: CMake cannot find Qt6
**Solution:** CMAKE_TOOLCHAIN_FILE နဲ့ CMAKE_SYSROOT မှန်ကန်စွာ set လုပ်ထားပါ။

### Issue 4: Application won't run on board
**Solution:** 
- Run environment variables (QT_QPA_PLATFORM, WAYLAND_DISPLAY) စစ်ပါ
- Board မှာ Weston running ရှိမရှိ စစ်ပါ: `systemctl status weston@root`
- Executable permissions: `chmod +x /home/root/hello_stm32`

### Issue 5: gdbserver connection timeout
**Solution:**
- Board network connectivity စစ်ပါ: `ping 192.168.7.1`
- gdbserver က board မှာ installed ရှိမရှိ စစ်ပါ
- Firewall rules စစ်ပါ

---

## Advanced: Qt Creator Automation Script

SDK activate နဲ့ Qt Creator launch ကို auto လုပ်ဖို့:

**~/launch_qtcreator_stm32.sh:**
```bash
#!/bin/bash

# Activate SDK environment
source ~/setup_stm32mp135_sdk.sh

# Launch Qt Creator with SDK environment
qtcreator &

echo "Qt Creator launched with STM32MP135 SDK environment"
```

**Make executable and use:**
```bash
chmod +x ~/launch_qtcreator_stm32.sh
~/launch_qtcreator_stm32.sh
```

---

## Summary

✅ **Configured Components:**
- Qt 6.8.4 from Yocto SDK
- ARM GCC cross-compilers (C/C++)
- ARM GDB debugger
- CMake with OE toolchain
- STM32MP135F-DK device (SSH/SFTP)

✅ **Workflow:**
1. Open project in Qt Creator
2. Select STM32MP135 Qt6 kit
3. Build (cross-compile)
4. Deploy via SFTP
5. Run/Debug on target board

✅ **Features Working:**
- Cross-compilation
- Remote deployment
- Remote debugging with breakpoints
- Qt6 Wayland applications on Weston
- SFTP file transfer

**Documentation Date:** November 10, 2025  
**SDK Version:** OpenSTLinux 5.0.8-snapshot  
**Qt Version:** 6.8.4  
**Target:** STM32MP135F-DK (Cortex-A7, 480x272 display)
