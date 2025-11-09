# How to Develop Qt6 Applications for STM32MP135

Complete guide for cross-compiling Qt6 applications on Ubuntu 22.04 host for STM32MP135F Discovery Kit target.

---

## မြန်မာဘာသာ အကျဉ်းချုပ်

### SDK လိုအပ်ချက်

**Q: Ubuntu 22.04 ပေါ်က Qt Creator မှာ app ရေးပြီး network ကနေ STM32MP135 ကို debug လုပ်ချင်ရင် SDK လိုလား?**

**A: SDK မဖြစ်မနေ မလိုပါဘူး။ ဒါပေမယ့် SDK ရှိရင် အများကြီးပို့လွယ်ပါတယ်။**

### SDK မရှိဘဲ Development (၃ မျိုး)

| နည်းလမ်း | အားသာချက် | အားနည်းချက် |
|---------|-----------|-------------|
| **1. Command-line + Yocto** | Setup လွယ်, အမြန်ဆုံး | Qt Creator integration မရှိ |
| **2. Qt Creator Manual** | IDE support ပြည့်စုံ | Configuration ရှုပ်ထွေး |
| **3. VS Code + CMake** | အလယ်အလတ် | Qt Creator ထက် feature နည်း |

### SDK ရှိတဲ့အခါ

✅ Qt Creator configuration **10 မိနစ်** ပြီး  
✅ Cross-compilation အလိုအလျောက် အလုပ်လုပ်  
✅ Remote debugging လွယ်  
✅ Team နဲ့ share လုပ်လို့ရ  
✅ Production development အတွက် အကောင်းဆုံး  

### SDK Build Failed ဖြစ်ရင်?

```bash
# Option 1: ARM toolchain ကို skip လုပ် (Qt6 Linux အတွက် မလို)
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf
bitbake st-image-qt6 -c populate_sdk

# Option 2: SDK မပါဘဲ Yocto environment သုံး
source ~/setup_qt6_dev.sh
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
make -j$(nproc)
```

### အကြံပြုချက်

- 🎯 **အမြန် စတင်ချင်ရင်**: Yocto environment သုံး (SDK မလို)
- 🎯 **Production အတွက်**: SDK build လုပ်ပြီး Qt Creator သုံး
- 🎯 **SDK build fail ဖြစ်နေရင်**: ARM toolchain skip လုပ်ပြီး retry

**အသေးစိတ် guide**: `06_qt_creator_without_sdk.md` ကြည့်ပါ

---

## Table of Contents
1. [Development Environment Setup](#development-environment-setup)
2. [SDK Installation and Configuration](#sdk-installation-and-configuration)
3. [Qt Creator Setup](#qt-creator-setup)
4. [Creating Your First Qt6 Application](#creating-your-first-qt6-application)
5. [Cross-Compilation Workflow](#cross-compilation-workflow)
6. [Deployment Methods](#deployment-methods)
7. [Remote Debugging](#remote-debugging)
8. [Example Applications](#example-applications)
9. [Troubleshooting](#troubleshooting)

---

## Development Environment Setup

### Prerequisites

#### Host System Requirements
- **OS**: Ubuntu 22.04 LTS (or similar Debian-based distribution)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 50GB free space
- **CPU**: Multi-core processor (4+ cores recommended)

#### Install Required Host Packages

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install development tools
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    gdb-multiarch \
    chrpath \
    diffstat \
    gawk \
    libncurses5-dev \
    texinfo \
    wget \
    python3-pip \
    ssh \
    rsync

# Install Qt Creator and development tools
sudo apt-get install -y \
    qtcreator \
    qt6-base-dev \
    qt6-declarative-dev \
    qml6-module-qtquick \
    libqt6core6 \
    libqt6gui6 \
    libqt6widgets6

# Install network tools for deployment
sudo apt-get install -y \
    nfs-kernel-server \
    nfs-common
```

---

## SDK Installation and Configuration

### SDK လိုအပ်ချက် (မြန်မာဘာသာ)

**SDK က ဘာလဲ?**
- Cross-compilation tools တွေ (arm-ostl-linux-gnueabi-gcc, g++, gdb)
- Qt6 libraries အားလုံး (target အတွက်)
- Sysroot (target filesystem အတုအယောင်)
- Standalone development environment

**SDK မရှိရင် ဘာဖြစ်မလဲ?**
- ✅ Yocto build environment ကနေ တိုက်ရိုက် cross-compile လုပ်လို့ရ
- ⚠️ Qt Creator configuration ခက်
- ⚠️ Environment source လုပ်ဖို့ လိုအပ်
- ⚠️ Team နဲ့ share လုပ်ရခက်

**SDK ရှိရင် အားသာချက်?**
- ✅ Qt Creator မှာ အလွယ်တကူ configure လုပ်လို့ရ
- ✅ Standalone (Yocto workspace မလို)
- ✅ အလုပ် stable
- ✅ SDK tarball ကို team တွေနဲ့ share လို့ရ

### Generate Cross-Compilation SDK

The Yocto build system can generate an SDK with all necessary cross-compilation tools and libraries.

#### Step 1: Build the SDK

```bash
# Navigate to build directory
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Build SDK for st-image-qt6
bitbake st-image-qt6 -c populate_sdk

# SDK will be generated at:
# tmp-glibc/deploy/sdk/openstlinux-weston-glibc-x86_64-st-image-qt6-cortexa7t2hf-neon-vfpv4-stm32mp13-disco-toolchain-*.sh
```

**Note**: SDK generation takes 30-60 minutes depending on your system.

**SDK Build Failed ဖြစ်ရင်? (မြန်မာဘာသာ)**

```bash
# အကြောင်းအရာ: nativesdk-gcc-arm-none-eabi network timeout
# ဒါက ARM Cortex-M bare-metal toolchain ဖြစ်ပြီး Qt6 Linux development အတွက် မလိုပါဘူး

# ဖြေရှင်းနည်း 1: ARM bare-metal toolchain ကို skip လုပ်
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf

# SDK ကို ပြန် build
bitbake st-image-qt6 -c populate_sdk

# ဖြေရှင်းနည်း 2: SDK မပါဘဲ development လုပ်
# အသေးစိတ်: 06_qt_creator_without_sdk.md ကြည့်ပါ
```

**SDK Installation ပြဿနာ: LD_LIBRARY_PATH Error**

```bash
# ပြဿနာ: "Your environment is misconfigured, you probably need to 'unset LD_LIBRARY_PATH'"
# အကြောင်းရင်း: ROS သို့မဟုတ် အခြား software က LD_LIBRARY_PATH set လုပ်ထားလို့

# Check LD_LIBRARY_PATH
printenv | grep LD_LIBRARY_PATH

# ဖြေရှင်းနည်း: Unset ပြီး install လုပ်
cd ~/backup/sdk-installers
unset LD_LIBRARY_PATH
./st-image-qt6-openstlinux-weston-*.sh -d ~/stm32mp1-sdk

# SDK activation script မှာ automatic handle လုပ်ထား
# (activation script က LD_LIBRARY_PATH ကို temporary unset လုပ်မယ်)
```

#### Step 2: Install the SDK

**SDK Location များ (မြန်မာဘာသာ):**

SDK ကို ဘယ်မှာ သိမ်းရမလဲ? ရွေးချယ်မှု ၃ မျိုး:

| Location | အကောင်းဆုံး အတွက် | Pros | Cons |
|----------|-------------------|------|------|
| `~/stm32mp1-sdk` | Individual developer | User space, လွယ် | User တစ်ယောက်ပဲ သုံးလို့ရ |
| `/opt/st/stm32mp1` | Team shared | System-wide, team share | Root permission လို |
| Custom path | Project-specific | Flexible | Path သတိရရခက် |

```bash
# Navigate to SDK location
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/sdk/

# Find the SDK installer
ls -lh openstlinux-weston-glibc-x86_64-st-image-qt6-*.sh

# Option 1: Install to home directory (အကြံပြု)
./openstlinux-weston-glibc-x86_64-st-image-qt6-cortexa7t2hf-neon-vfpv4-stm32mp13-disco-toolchain-*.sh -d ~/stm32mp1-sdk

# Option 2: Install to /opt (team sharing အတွက်)
sudo ./openstlinux-weston-glibc-x86_64-st-image-qt6-cortexa7t2hf-neon-vfpv4-stm32mp13-disco-toolchain-*.sh -d /opt/st/stm32mp1

# Option 3: Install to project directory
./openstlinux-weston-glibc-x86_64-st-image-qt6-cortexa7t2hf-neon-vfpv4-stm32mp13-disco-toolchain-*.sh -d ~/projects/stm32mp135/sdk

# Option 4: Install to external drive (backup အတွက်)
./openstlinux-weston-glibc-x86_64-st-image-qt6-cortexa7t2hf-neon-vfpv4-stm32mp13-disco-toolchain-*.sh -d /mnt/external/stm32mp1-sdk

# Follow prompts:
# - Accept license agreement
# - Confirm installation path
```

**SDK Backup လုပ်နည်း (အရေးကြီး!):**

```bash
# SDK installer (.sh file) ကို သိမ်းထား (590MB)
# ဒါဆို နောက်ပိုင်း ပြန် install လုပ်လို့ရ
cp ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/sdk/openstlinux-weston-glibc-x86_64-st-image-qt6-*.sh \
   ~/backup/sdk-installer/

# Or upload to Google Drive / Dropbox
# Or save to external USB drive
cp openstlinux-weston-glibc-x86_64-st-image-qt6-*.sh /mnt/usb/stm32mp135-sdk-backup/
```

#### Step 3: Setup SDK Environment

```bash
# Source the SDK environment
source ~/stm32mp1-sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

# Verify cross-compiler
$CC --version
# Should show: arm-ostl-linux-gnueabi-gcc (GCC) 13.3.0

# Check Qt6 libraries
ls $OECORE_TARGET_SYSROOT/usr/lib/libQt6*.so.6 | head -5
# Should show: libQt6Core.so.6, libQt6Gui.so.6, etc.

# Check Qt6 CMake modules (Qt6 uses CMake, not qmake)
ls $OECORE_TARGET_SYSROOT/usr/lib/cmake/Qt6*/
# Should show: Qt6Core, Qt6Gui, Qt6Qml, Qt6Quick, etc.

# Verify SDK size
du -sh ~/stm32mp1-sdk
# Expected: ~6-7GB
```

**Create SDK activation script** for convenience:

```bash
cat > ~/setup_stm32mp135_sdk.sh << 'EOF'
#!/bin/bash
# STM32MP135 Qt6 SDK Environment Setup

# SDK path ကို သင့် installation location နဲ့ ပြောင်းပါ
SDK_PATH=~/stm32mp1-sdk
# အကယ်၍ /opt မှာ install လုပ်ထားရင်: SDK_PATH=/opt/st/stm32mp1
# အကယ်၍ custom path: SDK_PATH=/mnt/external/stm32mp1-sdk

ENV_SETUP=$SDK_PATH/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

if [ -f "$ENV_SETUP" ]; then
    # Handle LD_LIBRARY_PATH conflict (ROS, etc.)
    # SDK က သူ့ကိုယ်ပိုင် library paths တွေ set လုပ်မှာမို့
    if [ -n "$LD_LIBRARY_PATH" ]; then
        echo "⚠ Temporarily unsetting LD_LIBRARY_PATH for SDK"
        OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
        unset LD_LIBRARY_PATH
    fi
    
    source "$ENV_SETUP"
    
    echo "✓ STM32MP135 SDK environment loaded"
    echo "  SDK location: $SDK_PATH"
    echo "  Cross-compiler: $CC"
    echo "  Target sysroot: $OECORE_TARGET_SYSROOT"
    echo "  Native sysroot: $OECORE_NATIVE_SYSROOT"
    
    # Verify Qt6 libraries
    if [ -d "$OECORE_TARGET_SYSROOT/usr/lib/cmake/Qt6" ]; then
        echo "  Qt6 CMake: Available"
    fi
else
    echo "✗ SDK not found at $SDK_PATH"
    echo "  Please check SDK installation path"
    echo "  Current search path: $SDK_PATH"
    exit 1
fi
EOF

chmod +x ~/setup_stm32mp135_sdk.sh
```

**SDK Location နဲ့ အညီ Script ပြင်နည်း:**

```bash
# အကယ်၍ SDK ကို /opt မှာ install လုပ်ထားရင်
sed -i 's|SDK_PATH=~/stm32mp1-sdk|SDK_PATH=/opt/st/stm32mp1|' ~/setup_stm32mp135_sdk.sh

# အကယ်၍ custom path သုံးထားရင်
sed -i 's|SDK_PATH=~/stm32mp1-sdk|SDK_PATH=/your/custom/path|' ~/setup_stm32mp135_sdk.sh
```

**Usage**:
```bash
# Load SDK environment (do this in every new terminal for cross-compilation)
source ~/setup_stm32mp135_sdk.sh
```

**SDK သိမ်းဆည်းမှု အကြံပြုချက်များ:**

```bash
# 1. SDK installer ကို အရေးကြီးတဲ့ နေရာတွေမှာ သိမ်းထားပါ
mkdir -p ~/backup/sdk-installers
cp ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/sdk/*.sh \
   ~/backup/sdk-installers/

# 2. SDK installation info ကို documentation
cat > ~/stm32mp1-sdk/SDK_INFO.txt << EOF
SDK Installation Information
============================
Installation Date: $(date)
SDK Version: Qt 6.8.4
OpenSTLinux: v6.1.0
Target: STM32MP135F Discovery Kit
Installation Path: $(pwd)
Installer Source: ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/sdk/
EOF

# 3. Verify SDK size
du -sh ~/stm32mp1-sdk
# Expected: ~10GB
```

---

## Qt Creator Setup

### Install Qt Creator

```bash
# If not already installed
sudo apt-get install -y qtcreator

# Launch Qt Creator
qtcreator &
```

### Configure Qt Creator for Cross-Compilation

#### 1. Add Qt6 Cross-Compilation Kit

**Go to**: `Tools` → `Options` → `Kits`

##### 1.1 Configure Compiler

**Tab**: `Compilers`
- Click `Add` → `GCC` → `C`
- **Name**: `ARM GCC (STM32MP135)`
- **Compiler path**: `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gcc`

- Click `Add` → `GCC` → `C++`
- **Name**: `ARM G++ (STM32MP135)`
- **Compiler path**: `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-g++`

##### 1.2 Configure Debugger

**Tab**: `Debuggers`
- Click `Add`
- **Name**: `ARM GDB (STM32MP135)`
- **Path**: `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/arm-ostl-linux-gnueabi/arm-ostl-linux-gnueabi-gdb`

##### 1.3 Configure Qt Version

**Tab**: `Qt Versions`
- Click `Add`
- **qmake location**: `~/stm32mp1-sdk/sysroots/x86_64-ostlsdk-linux/usr/bin/qmake`
- **Version name**: `Qt 6.8.4 (STM32MP135)`

##### 1.4 Configure Device

**Tab**: `Devices`
- Click `Add` → `Generic Linux Device`
- **Name**: `STM32MP135 Discovery`
- **Host name**: `192.168.7.1` (USB network) or your board's IP
- **Username**: `root`
- **Authentication type**: `Default` (no password)
- Click `Test` to verify connection

##### 1.5 Create Kit

**Tab**: `Kits`
- Click `Add`
- **Name**: `STM32MP135 Qt6`
- **Device type**: `Generic Linux Device`
- **Device**: `STM32MP135 Discovery`
- **Sysroot**: `~/stm32mp1-sdk/sysroots/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi`
- **Compiler C**: `ARM GCC (STM32MP135)`
- **Compiler C++**: `ARM G++ (STM32MP135)`
- **Debugger**: `ARM GDB (STM32MP135)`
- **Qt version**: `Qt 6.8.4 (STM32MP135)`
- **CMake Tool**: Auto-detected
- **Qt mkspec**: Leave empty (auto-detected)

Click `Apply` and `OK`.

---

## Creating Your First Qt6 Application

### Example 1: Simple QML Application

#### Create Project Structure

```bash
# Create project directory
mkdir -p ~/qt6_projects/hello_stm32
cd ~/qt6_projects/hello_stm32

# Create main.cpp
cat > main.cpp << 'EOF'
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

int main(int argc, char *argv[])
{
    qDebug() << "Starting STM32MP135 Qt6 Application...";
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    return app.exec();
}
EOF

# Create main.qml
cat > main.qml << 'EOF'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 480
    height: 272
    title: qsTr("STM32MP135 Qt6 Demo")
    
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2c3e50" }
            GradientStop { position: 1.0; color: "#34495e" }
        }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "Hello STM32MP135!"
                font.pixelSize: 32
                font.bold: true
                color: "white"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "Qt6 + QML Application"
                font.pixelSize: 20
                color: "#ecf0f1"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Button {
                text: "Click Me!"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 150
                Layout.preferredHeight: 50
                
                onClicked: {
                    infoText.text = "Button clicked at " + new Date().toLocaleTimeString()
                }
            }
            
            Text {
                id: infoText
                text: "Waiting for interaction..."
                font.pixelSize: 16
                color: "#95a5a6"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
EOF

# Create qml.qrc (Qt Resource file)
cat > qml.qrc << 'EOF'
<RCC>
    <qresource prefix="/">
        <file>main.qml</file>
    </qresource>
</RCC>
EOF

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(hello_stm32 VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

# Enable automatic handling of Qt-specific features
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Add executable
add_executable(hello_stm32
    main.cpp
    qml.qrc
)

# Link Qt6 libraries
target_link_libraries(hello_stm32
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

# Install target
install(TARGETS hello_stm32
    RUNTIME DESTINATION bin
)
EOF

echo "✓ Project created at ~/qt6_projects/hello_stm32"
```

#### Build with Command Line (Cross-Compilation)

```bash
# Source SDK environment
source ~/setup_stm32mp135_sdk.sh

# Navigate to project
cd ~/qt6_projects/hello_stm32

# Create build directory
mkdir -p build && cd build

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake

# Build
make -j$(nproc)

# Result: hello_stm32 executable
ls -lh hello_stm32
```

---

### Example 2: Qt Widgets Application

```bash
mkdir -p ~/qt6_projects/widget_demo
cd ~/qt6_projects/widget_demo

# Create main.cpp
cat > main.cpp << 'EOF'
#include <QApplication>
#include <QWidget>
#include <QPushButton>
#include <QLabel>
#include <QVBoxLayout>
#include <QDateTime>

class MainWindow : public QWidget {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QWidget(parent) {
        setWindowTitle("STM32MP135 Widgets Demo");
        resize(480, 272);
        
        auto *layout = new QVBoxLayout(this);
        
        auto *label = new QLabel("Qt6 Widgets on STM32MP135", this);
        label->setAlignment(Qt::AlignCenter);
        label->setStyleSheet("font-size: 24px; font-weight: bold;");
        
        timeLabel = new QLabel("", this);
        timeLabel->setAlignment(Qt::AlignCenter);
        timeLabel->setStyleSheet("font-size: 16px; color: #555;");
        
        auto *button = new QPushButton("Update Time", this);
        button->setMinimumHeight(50);
        
        layout->addStretch();
        layout->addWidget(label);
        layout->addWidget(timeLabel);
        layout->addWidget(button);
        layout->addStretch();
        
        connect(button, &QPushButton::clicked, this, &MainWindow::updateTime);
        
        updateTime();
    }

private slots:
    void updateTime() {
        QString currentTime = QDateTime::currentDateTime().toString("hh:mm:ss");
        timeLabel->setText("Current time: " + currentTime);
    }

private:
    QLabel *timeLabel;
};

#include "main.moc"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    MainWindow window;
    window.show();
    
    return app.exec();
}
EOF

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(widget_demo VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)

set(CMAKE_AUTOMOC ON)

add_executable(widget_demo main.cpp)

target_link_libraries(widget_demo
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
)

install(TARGETS widget_demo RUNTIME DESTINATION bin)
EOF
```

---

## Cross-Compilation Workflow

### Method 1: CMake Cross-Compilation

```bash
# 1. Source SDK environment
source ~/setup_stm32mp135_sdk.sh

# 2. Navigate to project
cd ~/qt6_projects/hello_stm32

# 3. Clean previous build (if any)
rm -rf build

# 4. Create build directory
mkdir build && cd build

# 5. Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake

# 6. Build
make -j$(nproc)

# 7. Verify executable is ARM binary
file hello_stm32
# Output should show: ELF 32-bit LSB executable, ARM, EABI5...

# 8. Check dependencies
$READELF -d hello_stm32 | grep NEEDED
```

### Method 2: qmake Cross-Compilation

For projects using qmake instead of CMake:

```bash
# Create .pro file
cat > hello_stm32.pro << 'EOF'
QT += core gui qml quick
CONFIG += c++17

TARGET = hello_stm32
TEMPLATE = app

SOURCES += main.cpp
RESOURCES += qml.qrc

target.path = /usr/bin
INSTALLS += target
EOF

# Build with qmake
source ~/setup_stm32mp135_sdk.sh
cd ~/qt6_projects/hello_stm32

qmake
make -j$(nproc)
```

---

## Deployment Methods

### Method 1: SCP (Secure Copy)

```bash
# Deploy to target board
scp hello_stm32 root@192.168.7.1:/usr/bin/

# Or deploy to temporary location
scp hello_stm32 root@192.168.7.1:/tmp/
```

### Method 2: NFS (Network File System)

#### Setup NFS Server on Host

```bash
# Install NFS server
sudo apt-get install -y nfs-kernel-server

# Create shared directory
mkdir -p ~/nfs_share
chmod 777 ~/nfs_share

# Configure NFS export
sudo bash -c 'echo "/home/mr_robot/nfs_share *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports'

# Restart NFS server
sudo systemctl restart nfs-kernel-server
sudo exportfs -av
```

#### Mount NFS on Target

```bash
# On STM32MP135 (via serial or SSH)
mkdir -p /mnt/nfs
mount -t nfs 192.168.7.2:/home/mr_robot/nfs_share /mnt/nfs

# Make persistent (optional)
echo "192.168.7.2:/home/mr_robot/nfs_share /mnt/nfs nfs defaults 0 0" >> /etc/fstab
```

#### Deploy via NFS

```bash
# On host: Copy executable to NFS share
cp ~/qt6_projects/hello_stm32/build/hello_stm32 ~/nfs_share/

# On target: Run from NFS
/mnt/nfs/hello_stm32
```

### Method 3: Include in Root Filesystem

Add your application to the Yocto build:

```bash
# Create recipe for your application
mkdir -p ~/openstlinux-build/layers/meta-rom-custom/recipes-apps/hello-stm32

cat > ~/openstlinux-build/layers/meta-rom-custom/recipes-apps/hello-stm32/hello-stm32_1.0.bb << 'EOF'
SUMMARY = "Hello STM32 Qt6 Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative"

SRC_URI = "file://main.cpp \
           file://main.qml \
           file://qml.qrc \
           file://CMakeLists.txt"

S = "${WORKDIR}"

inherit cmake_qt6

do_install() {
    install -d ${D}${bindir}
    install -m 0755 hello_stm32 ${D}${bindir}/
}

FILES:${PN} = "${bindir}/hello_stm32"
EOF

# Copy source files to recipe
mkdir -p ~/openstlinux-build/layers/meta-rom-custom/recipes-apps/hello-stm32/hello-stm32
cp ~/qt6_projects/hello_stm32/* ~/openstlinux-build/layers/meta-rom-custom/recipes-apps/hello-stm32/hello-stm32/

# Add to image
echo 'IMAGE_INSTALL += "hello-stm32"' >> ~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb

# Rebuild image
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
bitbake st-image-qt6
```

---

## Remote Debugging

### Remote Debugging အကြောင်း (မြန်မာဘာသာ)

**Remote Debugging ဆိုတာ ဘာလဲ?**
- Host (Ubuntu 22.04) ပေါ်က GDB ကနေ
- Network ကတစ်ဆင့်
- Target (STM32MP135) ပေါ်က application ကို debug လုပ်တာ

**လိုအပ်တာတွေ:**
1. ✅ Target မှာ gdbserver install လုပ်ထား
2. ✅ Network connection (SSH ချိတ်လို့ရရမယ်)
3. ✅ ARM cross-compiler's GDB (host ပေါ်မှာ)
4. ✅ Cross-compiled binary (ARM format)

**SDK လိုအပ်ချက်:**
- ❌ Remote debugging အတွက် SDK မဖြစ်မနေ မလိုပါဘူး
- ✅ ဒါပေမယ့် SDK ရှိရင် Qt Creator integration လွယ်
- ⚠️ SDK မရှိရင် command-line GDB သုံးရ

### Setup GDB Server on Target

The st-image-qt6 includes gdbserver by default. If not:

```bash
# On target
opkg update
opkg install gdb gdbserver
```

### Remote Debug from Host

```bash
# 1. On target: Start gdbserver
gdbserver :2345 /usr/bin/hello_stm32

# 2. On host: Connect with GDB
source ~/setup_stm32mp135_sdk.sh
cd ~/qt6_projects/hello_stm32/build

$GDB hello_stm32
(gdb) target remote 192.168.7.1:2345
(gdb) continue
```

### Qt Creator Remote Debugging

**Prerequisites (မြန်မာဘာသာ):**
- ✅ SDK install လုပ်ပြီးသား (သို့) Yocto environment configure ပြီး
- ✅ Qt Creator မှာ STM32MP135 Kit setup ပြီး
- ✅ Target board နဲ့ network ချိတ်ထား (SSH test လုပ်ပြီး)
- ✅ Target မှာ gdbserver ရှိပြီးသား

**Qt Creator Setup:**

1. Go to `Projects` → `Run` (for STM32MP135 Kit)
2. **Run configuration**: Select your application
3. **Deployment**: Enable automatic deployment via SCP
4. **Debugger Settings**:
   - **Debug server port**: 2345
   - **Debug server key**: (leave empty)
5. Click **Debug** button (F5)

Qt Creator will:
- Deploy application to target
- Start gdbserver on target
- Connect GDB from host
- Show source-level debugging

**SDK မရှိဘဲ Debug လုပ်နည်း (Manual):**

```bash
# Terminal 1 - Target မှာ gdbserver start
ssh root@192.168.7.1
gdbserver :2345 /tmp/hello_stm32

# Terminal 2 - Host မှာ GDB connect
source ~/openstlinux-build/layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
cd ~/qt6_projects/hello_stm32/build
$GDB hello_stm32
(gdb) target remote 192.168.7.1:2345
(gdb) break main
(gdb) continue
(gdb) next
(gdb) print variable_name
(gdb) backtrace
```

**အသေးစိတ်**: `06_qt_creator_without_sdk.md` ကြည့်ပါ

---

## Example Applications

### Example 3: Sensor Data Display (QML + C++)

```bash
mkdir -p ~/qt6_projects/sensor_app
cd ~/qt6_projects/sensor_app

# C++ backend
cat > sensorbackend.h << 'EOF'
#ifndef SENSORBACKEND_H
#define SENSORBACKEND_H

#include <QObject>
#include <QTimer>

class SensorBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(float temperature READ temperature NOTIFY temperatureChanged)
    Q_PROPERTY(float humidity READ humidity NOTIFY humidityChanged)

public:
    explicit SensorBackend(QObject *parent = nullptr);
    
    float temperature() const { return m_temperature; }
    float humidity() const { return m_humidity; }

signals:
    void temperatureChanged();
    void humidityChanged();

private slots:
    void updateSensorData();

private:
    float m_temperature;
    float m_humidity;
    QTimer *m_timer;
};

#endif
EOF

cat > sensorbackend.cpp << 'EOF'
#include "sensorbackend.h"
#include <QRandomGenerator>

SensorBackend::SensorBackend(QObject *parent)
    : QObject(parent), m_temperature(25.0f), m_humidity(50.0f)
{
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &SensorBackend::updateSensorData);
    m_timer->start(1000); // Update every second
}

void SensorBackend::updateSensorData() {
    // Simulate sensor readings
    m_temperature = 20.0f + QRandomGenerator::global()->bounded(10.0);
    m_humidity = 40.0f + QRandomGenerator::global()->bounded(20.0);
    
    emit temperatureChanged();
    emit humidityChanged();
}
EOF

cat > main.cpp << 'EOF'
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "sensorbackend.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    
    SensorBackend backend;
    
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("sensorBackend", &backend);
    
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    engine.load(url);
    
    return app.exec();
}
EOF

cat > main.qml << 'EOF'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 480
    height: 272
    title: "STM32MP135 Sensor Monitor"
    
    Rectangle {
        anchors.fill: parent
        color: "#ecf0f1"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            Text {
                text: "Sensor Data Monitor"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#e74c3c"
                radius: 10
                
                ColumnLayout {
                    anchors.centerIn: parent
                    
                    Text {
                        text: "Temperature"
                        font.pixelSize: 16
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: sensorBackend.temperature.toFixed(1) + " °C"
                        font.pixelSize: 28
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#3498db"
                radius: 10
                
                ColumnLayout {
                    anchors.centerIn: parent
                    
                    Text {
                        text: "Humidity"
                        font.pixelSize: 16
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: sensorBackend.humidity.toFixed(1) + " %"
                        font.pixelSize: 28
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
EOF

cat > qml.qrc << 'EOF'
<RCC>
    <qresource prefix="/">
        <file>main.qml</file>
    </qresource>
</RCC>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(sensor_app VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

add_executable(sensor_app
    main.cpp
    sensorbackend.cpp
    sensorbackend.h
    qml.qrc
)

target_link_libraries(sensor_app
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

install(TARGETS sensor_app RUNTIME DESTINATION bin)
EOF
```

---

## Running Qt6 Applications on Target

### Method 1: Run in Weston/Wayland

```bash
# On STM32MP135 target
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland

# Run application
/usr/bin/hello_stm32
```

### Method 2: Run in Framebuffer Mode

```bash
# If Weston is not running
export QT_QPA_PLATFORM=linuxfb
export QT_QPA_FB_DRM=1

/usr/bin/hello_stm32
```

### Method 3: Auto-start on Boot

Create systemd service:

```bash
# On target
cat > /etc/systemd/system/qt6-app.service << 'EOF'
[Unit]
Description=Qt6 Application Auto-start
After=weston.service
Requires=weston.service

[Service]
Type=simple
User=root
Environment="XDG_RUNTIME_DIR=/run/user/0"
Environment="QT_QPA_PLATFORM=wayland"
Environment="WAYLAND_DISPLAY=wayland-0"
ExecStart=/usr/bin/hello_stm32
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable qt6-app.service
systemctl start qt6-app.service
```

---

## Troubleshooting

### SDK နဲ့ ပတ်သက်တဲ့ ပြဿနာများ (မြန်မာဘာသာ)

#### ပြဿနာ: SDK Build Failed - nativesdk-gcc-arm-none-eabi

**လက្ခဏာ:**
```
ERROR: nativesdk-gcc-arm-none-eabi-14.2-r0 do_fetch: Failed to fetch URL
```

**အကြောင်းရင်း:**
- Network timeout ဖြစ်နေ
- ARM bare-metal toolchain download fail
- ဒါက Qt6 Linux development အတွက် **မလိုပါဘူး**

**ဖြေရှင်းနည်း:**
```bash
# Option 1: Skip ARM toolchain
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf
bitbake st-image-qt6 -c populate_sdk

# Option 2: SDK မပါဘဲ development
# See: 06_qt_creator_without_sdk.md
```

#### ပြဿနာ: SDK မရှိဘူး ဒါပေမယ့် development လုပ်ချင်တယ်

**ဖြေရှင်းနည်း:**
```bash
# Create activation script
cat > ~/setup_qt6_dev.sh << 'EOF'
#!/bin/bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo "✓ Qt6 development environment ready"
EOF
chmod +x ~/setup_qt6_dev.sh

# အသုံးပြုနည်း
source ~/setup_qt6_dev.sh
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
make -j$(nproc)
```

---

### Issue 1: "cannot find -lQt6Core"

**Cause**: SDK sysroot not properly configured

**Solution**:
```bash
# Verify SDK environment
source ~/setup_stm32mp135_sdk.sh
echo $OECORE_TARGET_SYSROOT
ls $OECORE_TARGET_SYSROOT/usr/lib/libQt6*.so*

# Re-install SDK if libraries are missing
```

### Issue 2: "error while loading shared libraries: libQt6Core.so.6"

**Cause**: Qt6 libraries not on target or LD_LIBRARY_PATH not set

**Solution**:
```bash
# On target: Verify Qt6 libraries
ls /usr/lib/libQt6*.so*

# If missing, ensure st-image-qt6 is flashed correctly
# Or manually install Qt6 packages:
opkg update
opkg install qtbase qtdeclarative
```

### Issue 3: QML Application Shows Black Screen

**Cause**: Wayland compositor issues or QML modules not found

**Solution**:
```bash
# Check Weston status
systemctl status weston

# Restart Weston
systemctl restart weston

# Verify QML modules
ls /usr/lib/qt6/qml/QtQuick/

# Run with debug output
QT_DEBUG_PLUGINS=1 /usr/bin/hello_stm32
```

### Issue 4: Cross-Compilation Fails with CMake Errors

**Cause**: Incorrect toolchain file or SDK not sourced

**Solution**:
```bash
# Ensure SDK is sourced
source ~/setup_stm32mp135_sdk.sh

# Use correct toolchain file
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake

# Or use qmake instead
qmake
make
```

### Issue 5: Application Crashes on Target

**Cause**: Missing dependencies or incompatible libraries

**Solution**:
```bash
# Check dependencies
ldd /usr/bin/hello_stm32

# Install missing libraries
opkg update
opkg install <missing-package>

# Run with GDB to get backtrace
gdb /usr/bin/hello_stm32
(gdb) run
(gdb) backtrace
```

### Issue 6: Touch Input Not Working

**Cause**: Input device not configured

**Solution**:
```bash
# Check input devices
ls /dev/input/

# Set environment variable
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0

# Or configure in Qt app
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
```

---

## Performance Optimization Tips

### 1. Enable QML Compiler

```bash
# In CMakeLists.txt
find_package(Qt6 COMPONENTS QmlCompiler)
qt6_add_qml_module(your_app ...)
```

### 2. Use Hardware Acceleration

```bash
# Enable OpenGL ES acceleration
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
export QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6/eglfs_kms.json
```

### 3. Optimize QML Loading

```qml
// Use Loader for lazy loading
Loader {
    id: heavyComponent
    source: "HeavyComponent.qml"
    asynchronous: true
}
```

### 4. Reduce Memory Usage

```bash
# Strip debug symbols
$STRIP hello_stm32

# Use release build
cmake .. -DCMAKE_BUILD_TYPE=Release
```

---

## Additional Resources

### Official Documentation
- [Qt6 Documentation](https://doc.qt.io/qt-6/)
- [Qt for Embedded Linux](https://doc.qt.io/qt-6/embedded-linux.html)
- [STM32MP13 Qt6 Integration](https://wiki.st.com/stm32mpu/wiki/Qt)

### Example Projects
- [Qt6 QML Examples](https://doc.qt.io/qt-6/qtquick-examples.html)
- [Qt6 Widgets Examples](https://doc.qt.io/qt-6/qtwidgets-examples.html)

### Useful Commands

```bash
# Check Qt6 version on target
qmake --version

# List installed Qt6 packages
opkg list | grep qt6

# Monitor application performance
top -b -n 1 | grep hello_stm32

# Check GPU usage (if available)
cat /sys/class/graphics/fb0/modes

# View Wayland compositor info
weston-info

# Test QML scene performance
QSG_RENDER_TIMING=1 /usr/bin/hello_stm32
```

---

## Quick Reference

### မြန်မာဘာသာ အတိုချုပ်

#### SDK ရှိတဲ့အခါ Workflow

```bash
# 1. SDK environment activate
source ~/stm32mp1-sdk/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi

# 2. Build project
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
cmake --build build -j$(nproc)

# 3. Deploy to target
scp build/hello_stm32 root@192.168.7.1:/tmp/

# 4. Run on target
ssh root@192.168.7.1 '/tmp/hello_stm32'

# 5. Debug (optional)
# Terminal 1: ssh root@192.168.7.1 'gdbserver :2345 /tmp/hello_stm32'
# Terminal 2: $GDB build/hello_stm32
#            (gdb) target remote 192.168.7.1:2345
```

#### SDK မရှိဘဲ Workflow

```bash
# 1. Yocto environment activate
source ~/setup_qt6_dev.sh

# 2. Build project
cd ~/qt6_projects/hello_stm32
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake
cmake --build build -j$(nproc)

# 3-5. Same as above (Deploy, Run, Debug)
```

#### Qt Creator Debug Workflow (SDK ရှိရမယ်)

```
1. Projects → Select "STM32MP135 Qt6" Kit
2. Set breakpoints in code
3. Click Debug button (F5)
4. Qt Creator automatically:
   - Deploys app via SCP
   - Starts gdbserver on target
   - Connects GDB from host
   - Stops at breakpoints
```

#### အမြန်ညွှန်းတမ်း

| လုပ်ငန်း | SDK ရှိရင် | SDK မရှိရင် |
|--------|----------|------------|
| Environment | `source ~/stm32mp1-sdk/environment-*` | `source ~/setup_qt6_dev.sh` |
| Qt Creator | ✅ လွယ် | ⚠️ Manual config |
| Build | ✅ stable | ✅ stable |
| Deploy | SCP/NFS/Yocto | Same |
| Debug (CLI) | ✅ လွယ် | ✅ လွယ် |
| Debug (Qt Creator) | ✅ အလုပ်လုပ် | ⚠️ ခက် |

### Cross-Compile Workflow
```bash
# 1. Source SDK
source ~/setup_stm32mp135_sdk.sh

# 2. Configure
cmake -B build -DCMAKE_TOOLCHAIN_FILE=$OECORE_NATIVE_SYSROOT/usr/share/cmake/OEToolchainConfig.cmake

# 3. Build
cmake --build build -j$(nproc)

# 4. Deploy
scp build/your_app root@192.168.7.1:/usr/bin/

# 5. Run on target
ssh root@192.168.7.1 '/usr/bin/your_app'
```

### Network Setup for Development

**USB Ethernet (g_ether)**:
- Host: 192.168.7.2
- Target: 192.168.7.1

**Ethernet**:
- Configure via DHCP or static IP in `/etc/network/interfaces`

---

## နောက်ထပ် အကူအညီများ (Additional Resources)

### အခြား Documentation များ

- **06_qt_creator_without_sdk.md** - SDK မပါဘဲ Qt Creator setup လုပ်နည်း
- **04_how_to_disable_weston_and_start_qt_app.md** - Kiosk mode configuration
- **05_if_i_remove_weston.md** - Performance analysis (Boot time, Memory)

### အမြန် ဆုံးဖြတ်ချက် လမ်းညွှန်

**သင် SDK build လုပ်ချင်သလား?**

👉 **YES** - SDK သုံးသင့်သူများ:
- Production development အတွက်
- Team နဲ့ share လုပ်ချင်ရင်
- Qt Creator IDE experience လိုချင်ရင်
- Standalone environment လိုချင်ရင်

**Build command:**
```bash
echo 'TOOLCHAIN_HOST_TASK:remove = "nativesdk-gcc-arm-none-eabi"' >> conf/local.conf
bitbake st-image-qt6 -c populate_sdk
```

👉 **NO** - SDK မသုံးသင့်သူများ:
- အမြန် စတင်ချင်ရင်
- Disk space သက်သာချင်ရင်
- Command-line workflow နဲ့ အဆင်ပြေရင်
- Yocto environment နဲ့ ရင်းနှီးပြီးသားဆိုရင်

**Setup command:**
```bash
cat > ~/setup_qt6_dev.sh << 'EOF'
#!/bin/bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
echo "✓ Ready for cross-compilation"
EOF
chmod +x ~/setup_qt6_dev.sh
```

### သိထားသင့်တာများ

1. **SDK မရှိရင် remote debugging လုပ်လို့ရသေးလား?**
   - ✅ **ရပါတယ်** - Command-line GDB သုံးပြီး debug လုပ်လို့ရ
   - ⚠️ Qt Creator IDE debugging က ပိုလွယ်

2. **SDK ဘယ်လောက် ကြာမလဲ?**
   - Build: 30-60 minutes (network speed ပေါ် မူတည်)
   - Install: 2-3 minutes
   - Size: ~10GB disk space

3. **SDK build fail ဖြစ်ပြီး ပြန်မလုပ်ချင်ဘူးဆိုရင်?**
   - ✅ Yocto environment သုံးပြီး development ဆက်လုပ်လို့ရ
   - ✅ အားလုံး အလုပ်လုပ်မယ် (cross-compile, deploy, debug)
   - ⚠️ Qt Creator configuration ပဲ ရှုပ်မယ်

4. **Team members တွေကို ဘယ်လို ပေးမလဲ?**
   - **SDK ရှိရင်**: SDK installer (.sh file) share လုပ်
   - **SDK မရှိရင်**: Yocto workspace တစ်ခုလုံး clone လုပ်ရမယ်

5. **SDK ကို ဘယ်မှာ သိမ်းသင့်လဲ?**
   - **Home directory** (`~/stm32mp1-sdk`): Individual developer, အကြံပြု
   - **/opt/st/stm32mp1**: Team shared, system-wide access
   - **Project directory**: Project-specific SDK
   - **External drive**: Backup, portable development
   - **Important**: SDK installer (.sh file) ကို backup သိမ်းထားပါ!

6. **SDK ကို အခြား computer မှာ သုံးလို့ရလား?**
   - ✅ **ရပါတယ်** - SDK installer (.sh file) ကို copy လုပ်ပြီး install လုပ်လို့ရ
   - ✅ နောက် computer မှာ ထပ် build စရာမလို
   - ⚠️ Same architecture (x86_64 Linux) လိုအပ်

7. **SDK multiple versions သိမ်းလို့ရလား?**
   - ✅ **ရပါတယ်** - Different directories မှာ install လုပ်
   - Example: `~/stm32mp1-sdk-v6.1`, `~/stm32mp1-sdk-v6.2`
   - Activation script မှာ SDK_PATH ပြောင်းပြီး သုံး

---

**Last Updated**: November 10, 2025  
**Qt Version**: 6.8.4  
**OpenSTLinux**: v6.1.0 (openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11)  
**Target**: STM32MP135F Discovery Kit

**Myanmar Language Support**: ဖြည့်စွက်ထားပါပြီ ✅
