# Image နဲ့ Debugging Tools

## မြန်မာဘာသာ အကျဉ်းချုပ်

**Q: st-image-qt6 မှာ gdbserver ပါလား?**

**A: မူလ image မှာ **မပါပါဘူး**။ ထည့်ပေးရပါမယ်။**

---

## Default Image မှာ ဘာတွေ ပါလဲ?

### st-image-qt6 Default Packages

```bash
# Check image manifest
grep -i gdb ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/st-image-qt6-*.manifest

# Result: Empty (gdbserver မပါ)
```

**Default st-image-qt6 မှာ ပါတာတွေ:**
- ✅ Qt6 libraries (qtbase, qtdeclarative, qtwayland, qtsvg)
- ✅ Weston compositor
- ✅ SSH server (dropbear)
- ✅ Package manager (opkg)
- ❌ **gdbserver** (မပါ!)
- ❌ **gdb** (မပါ!)
- ❌ **strace** (မပါ!)
- ❌ **tcf-agent** (မပါ!)

---

## Debugging Tools ထည့်နည်း

### Method 1: Yocto Recipe မှာ ထည့် (အကြံပြု)

**File**: `~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb`

```bash
# Edit recipe
cat >> ~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb << 'EOF'

# Development and Debugging Tools
IMAGE_INSTALL += " \
    gdbserver \
    gdb \
    strace \
    tcf-agent \
"
EOF
```

**Updated recipe:**
```bitbake
# ST Image Core + Qt6
SUMMARY = "OpenSTLinux core image with Qt6 support"
LICENSE = "MIT"

# Inherit from st-image-core
require recipes-st/images/st-image-core.bb

# Add essential Qt6 packages
IMAGE_INSTALL += " \
    qtbase \
    qtbase-plugins \
    qtbase-tools \
    qtdeclarative \
    qtwayland \
    qtsvg \
"

# Development and Debugging Tools
IMAGE_INSTALL += " \
    gdbserver \
    gdb \
    strace \
    tcf-agent \
"
```

**Rebuild image:**
```bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Rebuild image
bitbake st-image-qt6

# Flash to SD card
cd tmp-glibc/deploy/images/stm32mp13-disco/flashlayout_st-image-qt6/optee/
STM32_Programmer_CLI -c port=usb1 -w flashlayout_st-image-qt6-optee-stm32mp13-disco.tsv
```

### Method 2: Runtime Installation (တာတေမြောက်)

Image ကို ပြန် build မလုပ်ချင်ရင် target ပေါ်မှာ တိုက်ရိုက် install:

```bash
# On target (STM32MP135)
opkg update
opkg install gdbserver gdb strace

# Verify
gdbserver --version
gdb --version
```

**အားနည်းချက်:**
- Network လိုအပ် (target က internet ချိတ်ရမယ်)
- Reboot လုပ်ရင် ပျောက်နိုင် (တချို့ filesystem တွေမှာ)
- Image size ကို မထိန်းချုပ်နိုင်

---

## Debugging Tools ရဲ့ အသုံးပြုနည်း

### 1. gdbserver - Remote Debugging

**Target ပေါ်မှာ:**
```bash
# Start gdbserver
gdbserver :2345 /usr/bin/your_app

# Or with arguments
gdbserver :2345 /usr/bin/your_app --arg1 --arg2

# Listen on specific interface
gdbserver 192.168.7.1:2345 /usr/bin/your_app
```

**Host ပေါ်မှာ:**
```bash
# Activate SDK
source ~/setup_stm32mp135_sdk.sh

# Start GDB
cd ~/qt6_projects/hello_stm32/build
$GDB hello_stm32

# Connect to target
(gdb) target remote 192.168.7.1:2345
(gdb) break main
(gdb) continue
(gdb) next
(gdb) print variable_name
(gdb) backtrace
```

### 2. gdb - Full Debugger (on target)

Target ပေါ်မှာ တိုက်ရိုက် debug:

```bash
# On target
gdb /usr/bin/your_app

(gdb) run
(gdb) break main
(gdb) continue
(gdb) backtrace
(gdb) list
(gdb) print variable_name
```

**သုံးသင့်တဲ့ အချိန်:**
- Network မရှိရင်
- Quick debugging
- Core dump analysis

### 3. strace - System Call Tracer

Application က ဘာ system calls တွေ ခေါ်နေလဲ စစ်တာ:

```bash
# Trace all system calls
strace /usr/bin/your_app

# Save to file
strace -o trace.log /usr/bin/your_app

# Trace specific system calls only
strace -e open,read,write /usr/bin/your_app

# Attach to running process
strace -p <pid>

# Show timing information
strace -T /usr/bin/your_app
```

**အသုံးဝင်တဲ့ အခြေအနေများ:**
- File open/read/write ပြဿနာ
- Permission denied errors
- Missing library errors
- Performance analysis

### 4. tcf-agent - Target Communication Framework

Eclipse TCF agent for advanced debugging:

```bash
# Start tcf-agent on target
systemctl start tcf-agent

# Or manual start
tcf-agent -d -L- -l0

# Check status
systemctl status tcf-agent
```

**Features:**
- Remote file access
- Process control
- Memory inspection
- Advanced debugging with Eclipse CDT

---

## Image Size Comparison

### Without Debugging Tools

```bash
Size: ~512 MB
Boot time: 11s (without Weston)
Memory: 112 MB
```

### With Debugging Tools

```bash
Size: ~520 MB (+8MB)
Boot time: 11s (same)
Memory: 115 MB (+3MB)

Added packages:
- gdbserver: ~300 KB
- gdb: ~5 MB
- strace: ~500 KB
- tcf-agent: ~2 MB
```

**Trade-off:**
- ➕ Remote debugging capability
- ➕ System call tracing
- ➕ Full debugger on target
- ➖ Slightly larger image (+8MB)
- ➖ Minimal memory overhead (+3MB)

---

## Production vs Development Images

### Development Image (with debugging)

```bitbake
IMAGE_INSTALL += " \
    gdbserver \
    gdb \
    strace \
    tcf-agent \
    \
    # Additional dev tools \
    ldd \
    ltrace \
    valgrind \
    perf \
    sysstat \
"
```

**သုံးသင့်တာ:**
- Development phase
- Testing and debugging
- Performance profiling
- Issue investigation

### Production Image (minimal)

```bitbake
# Minimal debugging (only gdbserver for remote debug)
IMAGE_INSTALL += " \
    gdbserver \
"

# Or completely remove debugging tools
# (not recommended unless very constrained)
```

**သုံးသင့်တာ:**
- Final production deployment
- Size-constrained devices
- Security-sensitive applications

**အကြံပြု:**
- Development မှာ full debugging tools
- Production မှာ gdbserver ပဲ (remote debug အတွက်)

---

## Verification အဆင့်များ

### 1. Check Recipe

```bash
cat ~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb | grep -A10 "Debugging Tools"
```

### 2. Build Image

```bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
bitbake st-image-qt6
```

### 3. Check Manifest

```bash
grep -E "gdbserver|gdb |strace|tcf-agent" \
  ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/st-image-qt6-*.manifest
```

**Expected output:**
```
gdb cortexa7t2hf-neon-vfpv4 13.2
gdbserver cortexa7t2hf-neon-vfpv4 13.2
strace cortexa7t2hf-neon-vfpv4 6.5
tcf-agent cortexa7t2hf-neon-vfpv4 1.7.0
```

### 4. Flash and Test

```bash
# Flash image
STM32_Programmer_CLI -c port=usb1 -w flashlayout_st-image-qt6-optee-stm32mp13-disco.tsv

# Boot target and verify
ssh root@192.168.7.1

# On target
gdbserver --version
gdb --version
strace -V
```

---

## Remote Debugging Workflow

### Complete Example

**1. Target ပေါ်မှာ gdbserver start:**
```bash
ssh root@192.168.7.1
gdbserver :2345 /usr/bin/hello_stm32
```

**2. Host ပေါ်မှာ GDB connect:**
```bash
# Terminal on host
source ~/setup_stm32mp135_sdk.sh
cd ~/qt6_projects/hello_stm32/build

$GDB hello_stm32
(gdb) target remote 192.168.7.1:2345
(gdb) break main
(gdb) continue

# Debug as usual
(gdb) next
(gdb) step
(gdb) print my_variable
(gdb) backtrace
(gdb) info locals
(gdb) watch my_variable
```

**3. Qt Creator Integration:**

See `03_how_to_develop_qt6_app.md` - Remote Debugging section

---

## Troubleshooting

### Issue 1: gdbserver not found after boot

**Cause**: Image built without gdbserver

**Solution**:
```bash
# Option 1: Rebuild image with debugging tools
# (see Method 1 above)

# Option 2: Install at runtime
ssh root@192.168.7.1
opkg update
opkg install gdbserver
```

### Issue 2: Connection refused (port 2345)

**Cause**: gdbserver not running or firewall

**Solution**:
```bash
# On target: Check if gdbserver is running
ps | grep gdbserver

# Start gdbserver
gdbserver :2345 /usr/bin/your_app

# Check network connectivity
ping 192.168.7.1  # from host
```

### Issue 3: GDB version mismatch

**Cause**: Host GDB != target gdbserver version

**Solution**:
```bash
# Use SDK's GDB (already matched)
source ~/setup_stm32mp135_sdk.sh
$GDB --version  # Should match target gdbserver

# Verify on target
ssh root@192.168.7.1 'gdbserver --version'
```

### Issue 4: Symbols not found

**Cause**: Binary was stripped or built without debug info

**Solution**:
```bash
# Build with debug symbols
cmake -DCMAKE_BUILD_TYPE=Debug ..
make

# Or use RelWithDebInfo
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
make

# Don't strip binary
# (remove $STRIP command if present)
```

---

## Best Practices

### 1. Development Workflow

```bash
# 1. Build with debugging tools
bitbake st-image-qt6

# 2. Flash to SD card
# (flashlayout includes all tools)

# 3. Develop with full debugging capability
# (gdbserver, strace always available)
```

### 2. Production Deployment

```bash
# Option A: Keep gdbserver only
IMAGE_INSTALL += "gdbserver"

# Option B: Create separate development image
# st-image-qt6-dev.bb (with tools)
# st-image-qt6-prod.bb (minimal)
```

### 3. Security Considerations

**Development image:**
- ✅ Full debugging tools
- ✅ gdb, gdbserver, strace
- ⚠️ Never deploy to production!

**Production image:**
- ⚠️ gdbserver only (if needed for field debugging)
- ✅ Or no debugging tools at all
- ✅ Strip all binaries
- ✅ Optimize for size and security

---

## Quick Reference

### Build Image with Debugging

```bash
# Add to recipe
echo 'IMAGE_INSTALL += "gdbserver gdb strace tcf-agent"' >> \
  ~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb

# Build
bitbake st-image-qt6

# Flash
STM32_Programmer_CLI -c port=usb1 -w flashlayout.tsv
```

### Remote Debug Session

```bash
# Target
gdbserver :2345 /usr/bin/app

# Host
source ~/setup_stm32mp135_sdk.sh
$GDB app
(gdb) target remote 192.168.7.1:2345
(gdb) continue
```

### System Call Tracing

```bash
# On target
strace -o /tmp/trace.log /usr/bin/app

# Analyze trace
cat /tmp/trace.log | grep -E "open|read|write"
```

---

## Summary (အတိုချုပ်)

| အချက် | အဖြေ |
|------|-----|
| **Default image မှာ gdbserver ပါလား?** | ❌ မပါပါဘူး |
| **ဘယ်လို ထည့်မလဲ?** | IMAGE_INSTALL += "gdbserver gdb strace" |
| **Image size တိုးမလား?** | ✅ +8MB only |
| **Remote debugging လုပ်လို့ရမလား?** | ✅ ရပါတယ် (gdbserver ထည့်ပြီးရင်) |
| **Production မှာ သုံးသင့်လား?** | ⚠️ gdbserver ပဲ ထားပါ (သို့) လုံးဝမထည့် |
| **အမြန် install လုပ်ချင်ရင်?** | opkg install gdbserver |

---

**Last Updated**: November 10, 2025  
**Image**: st-image-qt6  
**Tools**: gdbserver, gdb, strace, tcf-agent  
**Target**: STM32MP135F Discovery Kit
