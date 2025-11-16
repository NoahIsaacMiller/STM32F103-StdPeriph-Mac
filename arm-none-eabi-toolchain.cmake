# ==============================================================================
# 交叉编译工具链配置：针对 ARM Cortex-M 系列微控制器（如 STM32F103）
# 作用：告知 CMake 正在进行交叉编译，并指定目标平台的工具链和规则
# ==============================================================================

# --------------------------
# 目标系统基本信息配置
# --------------------------
# 设置目标系统名称为 Generic（通用）
# 原因：嵌入式裸机开发（无操作系统）没有特定的系统名称，用 Generic 表示
set(CMAKE_SYSTEM_NAME Generic)

# 设置目标系统版本（仅为满足 CMake 语法要求，裸机开发中无实际意义）
set(CMAKE_SYSTEM_VERSION 1)

# 指定目标处理器架构为 ARM
# 对应 STM32F103 使用的 Cortex-M3 内核（属于 ARM 架构）
set(CMAKE_SYSTEM_PROCESSOR arm)


# --------------------------
# 交叉编译工具链路径配置
# --------------------------
# 定义交叉编译器前缀（所有工具的统一前缀）
# arm-none-eabi- 是针对 ARM 裸机开发的标准工具链前缀（无 OS 支持）
set(TOOLCHAIN_PREFIX arm-none-eabi)

# 配置具体工具的路径
# 假设工具链的 bin 目录已添加到系统 PATH，因此直接使用工具名（无需绝对路径）
# 若未添加 PATH，需指定完整路径（如 /opt/arm-none-eabi/bin/${TOOLCHAIN_PREFIX}-gcc）

# C 编译器：使用 ARM 交叉编译工具链中的 gcc
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}-gcc)

# C++ 编译器：使用 ARM 交叉编译工具链中的 g++
# 若项目需要支持 C++，需确保此配置生效（配合主 CMakeLists.txt 中的 CXX 支持）
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++)

# 汇编器：使用 gcc 作为汇编器前端（支持预处理指令，如 #include、#define）
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}-gcc)

# 目标文件转换工具：用于将 ELF 格式转换为可烧录的 bin/hex 格式
set(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}-objcopy)

# 固件大小分析工具：用于查看 ELF 文件各段（代码/数据）的占用情况
set(CMAKE_SIZE ${TOOLCHAIN_PREFIX}-size)


# --------------------------
# 工具链资源查找路径配置
# --------------------------
# 工具链根目录（工具链自带的库文件、头文件所在路径）
# 需根据实际安装位置修改（常见路径：/opt/arm-none-eabi、~/esp/tools/arm-none-eabi 等）
set(TOOLCHAIN_DIR /opt/arm-none-eabi)

# 设置 CMake 查找资源的根路径（优先在此目录下搜索库、头文件等）
# 确保使用工具链自带的嵌入式库，而非主机系统的库（避免兼容性问题）
set(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_DIR})


# --------------------------
# 查找规则配置（核心！避免链接主机系统资源）
# --------------------------
# 程序查找规则：NEVER（不在目标系统路径中查找程序）
# 说明：编译器、objcopy 等工具是运行在主机（如 x86 电脑）上的，无需在目标路径查找
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# 库文件查找规则：ONLY（只在目标工具链路径中查找）
# 说明：必须使用针对 ARM 架构的库（如 libc.a），不能用主机系统的 x86 库
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

# 头文件查找规则：ONLY（只在目标工具链路径中查找）
# 说明：使用工具链自带的嵌入式头文件（如 stdint.h），确保与目标架构匹配
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 包查找规则：ONLY（只在目标工具链路径中查找 CMake 包）
# 说明：确保引入的第三方库是针对 ARM 架构编译的
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)