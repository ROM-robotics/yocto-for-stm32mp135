# Qt Creator Remote Debugging Without SDK

## မြန်မာဘာသာ အကျဉ်းချုပ်

Ubuntu 22.04 ပေါ်က Qt Creator မှာ app ရေးပြီး network ကနေ STM32MP135 ကို debug လုပ်ချင်ရင် **SDK မလိုပါဘူး**။ ဒါပေမယ့် **SDK ရှိရင် အလုပ်လုပ်ရ ပို့လွယ်ပါတယ်**။

## ရွေးချယ်စရာ ၂ မျိုး

### ရွေးချယ်စရာ ၁: SDK မရှိဘဲ (Manual Configuration)

**အားသာချက်**:
- SDK build မလုပ်ရ (အချိန်သက်သာ)
- Disk space သက်သာ

**အားနည်းချက်**:
- Qt Creator configuration ရှုပ်ထွေး
- Cross-compiler paths တွေ manual ထည့်ရ
- Qt libraries သွားရှာရခက်
- Sysroot configure လုပ်ရခက်

### ရွေးချယ်စရာ ၂: SDK ရှိတဲ့အခါ (Recommended)

**အားသာချက်**:
- Qt Creator ကို အလွယ်တကူ configure လုပ်လို့ရ
- Cross-compilation အလိုအလျောက် အလုပ်လုပ်
- Remote debugging လွယ်
- Production development အတွက် အကောင်းဆုံး

**အားနည်းချက်**:
- SDK build ကြာ (1 နာရီခန့်)
- Disk space 10GB လောက်ကျ

---

## Method 1: SDK မရှိဘဲ Qt Creator Setup (ခက်)

### Step 1: Yocto Build Environment Cross-Compiler ကိုသုံး

```bash
# Find Yocto cross-compiler
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Find compiler paths
which arm-ostl-linux-gnueabi-gcc
which arm-ostl-linux-gnueabi-g++
which arm-ostl-linux-gnueabi-gdb

# Example paths:
# ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gcc
```

### Step 2: Qt Creator Configuration (Manual)

#### 2.1 Configure Compilers

**Qt Creator** → **Tools** → **Options** → **Kits** → **Compilers**

**C Compiler**:
- Click **Add** → **GCC** → **C**
- **Name**: `Yocto ARM GCC (STM32MP135)`
- **Compiler path**: 
  ```
  ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gcc
  ```

**C++ Compiler**:
- Click **Add** → **GCC** → **C++**
- **Name**: `Yocto ARM G++ (STM32MP135)`
- **Compiler path**: 
  ```
  ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-g++
  ```

#### 2.2 Configure Debugger

**Tab: Debuggers**
- Click **Add**
- **Name**: `Yocto ARM GDB (STM32MP135)`
- **Path**: 
  ```
  ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gdb
  ```

#### 2.3 Configure Qt Version (ပြဿနာ!)

**Tab: Qt Versions**

⚠️ **ပြဿနာ**: SDK မရှိရင် qmake path ရှာရခက်!

**Workaround Option A: Use Yocto's qmake (if available)**
```bash
# Find qmake in Yocto build
find ~/openstlinux-build -name "qmake" -type f 2>/dev/null | grep native

# Example path:
# ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/bin/qmake
```

**Workaround Option B: Use host Qt6 for UI, manual cross-compile**
```bash
# Install Qt6 on Ubuntu host (for Qt Creator support only)
sudo apt-get install -y qt6-base-dev qt6-declarative-dev

# Use host qmake for Qt Creator configuration
which qmake
# /usr/bin/qmake

# BUT: Cross-compilation will need manual CMake toolchain file
```

**In Qt Creator**:
- **qmake location**: `/usr/bin/qmake` (host Qt6)
- **Version name**: `Qt 6 (Host) - for STM32MP135 development`

⚠️ **သတိပြုရန်**: ဒီ qmake က host အတွက်ပါ။ Target အတွက် cross-compile လုပ်တဲ့အခါ CMake toolchain file သုံးရပါမယ်။

#### 2.4 Configure Device

**Tab: Devices**
- Click **Add** → **Generic Linux Device**
- **Name**: `STM32MP135 Discovery`
- **Host name**: `192.168.7.1` (or your board IP)
- **Username**: `root`
- **Authentication**: Default (no password)
- Click **Test** to verify SSH connection

#### 2.5 Create Kit

**Tab: Kits**
- Click **Add**
- **Name**: `STM32MP135 (Without SDK)`
- **Device type**: `Generic Linux Device`
- **Device**: `STM32MP135 Discovery`
- **Sysroot**: 
  ```
  ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
  ```
- **Compiler C**: `Yocto ARM GCC (STM32MP135)`
- **Compiler C++**: `Yocto ARM G++ (STM32MP135)`
- **Debugger**: `Yocto ARM GDB (STM32MP135)`
- **Qt version**: `Qt 6 (Host)`
- **CMake Configuration**: Add manually (see below)

**CMake Configuration (Important!)**:

Add these variables in Kit's CMake configuration:

```
CMAKE_TOOLCHAIN_FILE:FILEPATH=%{Env:OECORE_NATIVE_SYSROOT}/usr/share/cmake/OEToolchainConfig.cmake
CMAKE_PREFIX_PATH:PATH=%{Env:OECORE_TARGET_SYSROOT}/usr/lib/cmake
CMAKE_FIND_ROOT_PATH:PATH=%{Env:OECORE_TARGET_SYSROOT}
```

⚠️ **ပြဿနာ**: Environment variables (`$OECORE_NATIVE_SYSROOT`) တွေက Yocto environment source လုပ်ထားမှ available ဖြစ်ပါတယ်။

### Step 3: Project Configuration

**CMakeLists.txt** မှာ manual toolchain file path ထည့်:

```cmake
cmake_minimum_required(VERSION 3.16)
project(hello_stm32 VERSION 1.0 LANGUAGES CXX)

# Manual sysroot for non-SDK builds
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE 
        "$ENV{HOME}/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/sysroots/x86_64-linux/usr/share/cmake/OEToolchainConfig.cmake"
        CACHE FILEPATH "Toolchain file")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

add_executable(hello_stm32 main.cpp qml.qrc)
target_link_libraries(hello_stm32 Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
```

### Step 4: Build from Qt Creator

1. Open Project in Qt Creator
2. Select Kit: `STM32MP135 (Without SDK)`
3. **Build** → **Build Project**

⚠️ **ပြဿနာတက်နိုင်တာ**: 
- Environment variables မရှိရင် build fail ဖြစ်နိုင်
- Qt6 libraries ရှာမတွေ့နိုင်

**Workaround**: Terminal ကနေ manual build:

```bash
# Source Yocto environment first
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Then build
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
cmake --build build -j$(nproc)
```

### Step 5: Deploy and Debug

**In Qt Creator**:
1. **Projects** → **Run Settings** (for STM32MP135 kit)
2. **Deployment**:
   - Method: Upload to device via SCP
   - Local file: `build/hello_stm32`
   - Remote directory: `/tmp`
3. **Run Configuration**:
   - Executable: `/tmp/hello_stm32`
   - Working directory: `/tmp`

**Debug**:
- Click **Debug** button (F5)
- Qt Creator will:
  1. Deploy app to target via SCP
  2. Start gdbserver on target
  3. Connect GDB from host
  4. Stop at breakpoints

---

## Method 2: SDK ရှိတဲ့အခါ (အကောင်းဆုံး)

### SDK ကို ဘာလို့ သုံးသင့်လဲ?

1. **Qt Creator Configuration လွယ်**: Compiler/Qt paths တွေ အလိုအလျောက် configure ဖြစ်
2. **Standalone Development**: Yocto build environment source မလုပ်ဘဲလည်း cross-compile လုပ်လို့ရ
3. **Team Development**: SDK ကို team members တွေနဲ့ share လုပ်လို့ရ
4. **Relocatable**: SDK folder ကို ဘယ်နေရာမဆို ရွှေ့လို့ရ

### SDK Build လုပ်နည်း

```bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Build SDK
bitbake st-image-qt6 -c populate_sdk

# Install SDK
cd tmp-glibc/deploy/sdk/
./openstlinux-weston-glibc-x86_64-st-image-qt6-*.sh -d ~/stm32mp1-sdk

# Source SDK
source ~/stm32mp1-sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi
```

### SDK ရှိရင် Qt Creator Setup (လွယ်)

**Detailed documentation**: See `03_how_to_develop_qt6_app.md` Section "Qt Creator Setup"

**Quick steps**:

1. **Compilers**: Add from `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/`
2. **Debugger**: Add GDB from same location
3. **Qt Version**: Add qmake from `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/qmake`
4. **Device**: Configure STM32MP135 with IP address
5. **Kit**: Create kit with all above components + sysroot

✅ **အားသာချက်**: Qt6 libraries အားလုံး sysroot ထဲမှာ ပါပြီးသား!

---

## Comparison: SDK vs No SDK

| Feature | With SDK | Without SDK |
|---------|----------|-------------|
| Qt Creator Configuration | ✅ Easy (10 minutes) | ⚠️ Complex (30+ minutes) |
| Build Reliability | ✅ Stable | ⚠️ Error-prone |
| Environment Setup | ✅ One script: `source ~/stm32mp1-sdk/environment-*` | ⚠️ Must source Yocto environment |
| Qt Libraries | ✅ All in sysroot | ⚠️ Must find in Yocto build |
| Standalone Development | ✅ Yes | ❌ No (needs Yocto workspace) |
| Disk Space | ⚠️ ~10GB | ✅ 0GB (uses existing Yocto) |
| Build Time | ⚠️ 1 hour SDK build | ✅ 0 (already have Yocto) |
| Team Sharing | ✅ Share SDK tarball | ❌ Must rebuild Yocto |
| Remote Debugging | ✅ Works perfectly | ⚠️ Works but harder to setup |

---

## SDK Build Failed ဖြစ်တယ်ဆိုရင်?

ဒီအတိုင်း SDK မပါဘဲ development လုပ်လို့ရပါတယ်:

### Option 1: Command Line Development (အလွယ်ဆုံး)

```bash
# Create activation script
cat > ~/setup_qt6_dev.sh << 'EOF'
#!/bin/bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo "✓ Qt6 cross-compilation environment ready"
echo "  Compiler: $CC"
echo "  Sysroot: $OECORE_TARGET_SYSROOT"
EOF

chmod +x ~/setup_qt6_dev.sh
```

**Development workflow**:

```bash
# 1. Setup environment
source ~/setup_qt6_dev.sh

# 2. Build project
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
cmake --build build -j$(nproc)

# 3. Deploy to target
scp build/hello_stm32 root@192.168.7.1:/tmp/

# 4. Debug on target
ssh root@192.168.7.1 'gdbserver :2345 /tmp/hello_stm32'

# 5. In another terminal: Connect GDB
source ~/setup_qt6_dev.sh
cd ~/qt6_projects/hello_stm32/build
$GDB hello_stm32
(gdb) target remote 192.168.7.1:2345
(gdb) continue
```

### Option 2: VS Code Remote Development

```bash
# Install VS Code extensions
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cmake-tools

# Configure VS Code with CMake + cross-compiler
# Easier than Qt Creator for SDK-less development
```

### Option 3: Fix SDK Build and Retry

```bash
# If SDK build failed on network issue:
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Clean failed package
bitbake nativesdk-gcc-arm-none-eabi -c cleanall

# Or skip ARM bare-metal toolchain (not needed for Qt6 Linux)
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf

# Retry SDK build
bitbake st-image-qt6 -c populate_sdk
```

---

## Remote Debugging Setup (SDK ရှိ/မရှိ တူတူလိုတာ)

### Target Board Setup

```bash
# On STM32MP135 target
opkg update
opkg install gdbserver

# Test gdbserver
gdbserver --version
```

### Network Setup

```bash
# On host: Test connection
ping 192.168.7.1
ssh root@192.168.7.1

# On target: Check network
ifconfig
# Should see usb0 or eth0 with IP 192.168.7.1
```

### Debug Session

**Manual debugging** (works with or without SDK):

```bash
# Terminal 1 - On target: Start gdbserver
ssh root@192.168.7.1
gdbserver :2345 /tmp/hello_stm32

# Terminal 2 - On host: Connect GDB
source ~/setup_qt6_dev.sh  # Or source SDK environment
cd ~/qt6_projects/hello_stm32/build

$GDB hello_stm32
(gdb) target remote 192.168.7.1:2345
(gdb) break main
(gdb) continue
(gdb) next
(gdb) print variable_name
```

**Qt Creator debugging** (needs proper Kit configuration):

1. Open project in Qt Creator
2. Select STM32MP135 Kit
3. Set breakpoints in code
4. Click **Debug** (F5)
5. Qt Creator handles gdbserver automatically

---

## Recommendation (အကြံပြုချက်)

### သင့်အခြေအနေအရ:

**If SDK build failed ဖြစ်နေတယ်ဆိုရင်**:
1. ✅ **Short term**: Use command-line development (Method 1 above)
2. ✅ **Long term**: Fix SDK build and retry

**If you want Qt Creator IDE experience**:
1. ✅ Fix SDK build issue (network problem or skip ARM toolchain)
2. ✅ Install SDK
3. ✅ Configure Qt Creator properly with SDK

**If you prefer simple workflow**:
1. ✅ Use VS Code + CMake + Yocto environment
2. ✅ Build from terminal
3. ✅ Deploy via SCP
4. ✅ Debug with command-line GDB

---

## Quick Answer (အတိုချုပ်)

**Question**: Ubuntu 22 ပေါ်က Qt Creator မှာ app ရေးပြီး network ကနေ MP135 ကို debug လုပ်ချင်တယ်။ SDK လိုလား?

**Answer**: 
- ❌ **SDK မဖြစ်မနေ မလိုပါဘူး** - Yocto environment သုံးပြီး development လုပ်လို့ရ
- ✅ **SDK ရှိရင် အများကြီး ပို့လွယ်** - Qt Creator configuration လွယ်, debugging stable
- ⚠️ **SDK မရှိရင်**: Manual configuration များ၊ command-line workflow သုံးရ
- 💡 **အကြံပြု**: SDK build ကို fix လုပ်ပြီး retry လုပ်ပါ (1 နာရီလောက်ပဲ ကြာ)

---

## Next Steps

### အခု ရွေးပါ:

**Path A: SDK မပါဘဲ ဆက်လုပ်မယ်**
```bash
# Use this workflow
source ~/setup_qt6_dev.sh
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
make -j$(nproc)
scp build/hello_stm32 root@192.168.7.1:/tmp/
```

**Path B: SDK ကို ပြန် build ကြည့်မယ်**
```bash
# Fix and retry
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf
bitbake st-image-qt6 -c populate_sdk
```

**ဘယ် path ကို ရွေးချင်လဲ သိအောင် ပြောပြပါ။ ဆက်ကူညီပေးပါမယ်။**
