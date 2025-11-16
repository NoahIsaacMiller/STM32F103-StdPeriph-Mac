# 设置CMake最低版本要求（兼容3.10及以上版本，确保跨平台兼容性）
cmake_minimum_required(VERSION 3.10)

# 交叉编译关键配置：设置尝试编译的目标类型为静态库
# 避免在配置阶段因缺少目标平台库文件导致的链接错误
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# 引入ARM交叉编译工具链配置文件
# 该文件定义了交叉编译的基础规则（如目标系统、处理器架构等）
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/arm-none-eabi-toolchain.cmake)

# 显式指定交叉编译工具链（针对ARM Cortex-M3架构）
set(CMAKE_C_COMPILER       arm-none-eabi-gcc)    # C编译器
set(CMAKE_CXX_COMPILER     arm-none-eabi-g++)    # C++编译器
set(CMAKE_ASM_COMPILER     arm-none-eabi-gcc)    # 汇编编译器（用gcc驱动汇编）
set(CMAKE_OBJDUMP          arm-none-eabi-objdump) # 反汇编工具
set(CMAKE_OBJCOPY          arm-none-eabi-objcopy) # 目标文件转换工具（生成bin/hex）
set(CMAKE_SIZE             arm-none-eabi-size)    # 查看目标文件大小的工具

# 定义项目名称及支持的语言（C、C++、汇编）
# 同时支持C和C++，方便混合编程
project(STM32-F103-C8T6 C CXX ASM)

# --------------------------
# 核心配置：芯片与编译参数
# --------------------------
# MCU架构相关编译参数
# -mcpu=cortex-m3：指定目标处理器为Cortex-M3
# -mthumb：启用Thumb指令集（Cortex-M系列必须使用）
# -mfloat-abi=soft：使用软件浮点（STM32F103无硬件浮点单元）
set(MCU_FLAGS -mcpu=cortex-m3 -mthumb -mfloat-abi=soft)

# 指定链接器脚本（定义Flash和RAM的地址与大小分配）
# 该脚本需与STM32F103C8T6的硬件规格匹配（64KB Flash / 20KB RAM）
set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/ld/stm32_flash.ld")

# --------------------------
# 头文件与源文件路径配置
# --------------------------
# 包含头文件目录（让编译器能找到#include的文件）
include_directories(
  ${CMAKE_SOURCE_DIR}/inc/driver    # 外设库驱动头文件
  ${CMAKE_SOURCE_DIR}/inc/user      # 用户应用头文件
  ${CMAKE_SOURCE_DIR}/src/system    # 系统核心代码头文件（如启动文件相关）
)

# 系统核心源文件（启动文件、内核初始化等，必须包含）
set(SYSTEM_SRCS
  ${CMAKE_SOURCE_DIR}/src/system/startup_stm32f10x_md.s  # 启动汇编文件（中断向量表+初始化）
  ${CMAKE_SOURCE_DIR}/src/system/core_cm3.c              # Cortex-M3内核通用函数
  ${CMAKE_SOURCE_DIR}/src/system/system_stm32f10x.c      # STM32系统时钟配置
)

# 驱动层源文件（标准外设库实现，.c和.cpp文件均支持）
file(GLOB DRIVER_SRCS 
  ${CMAKE_SOURCE_DIR}/driver/*.c    # C语言驱动文件
  ${CMAKE_SOURCE_DIR}/driver/*.cpp  # C++语言驱动文件
)

# 用户应用源文件（业务逻辑代码，.c和.cpp文件均支持）
file(GLOB USER_SRCS 
  ${CMAKE_SOURCE_DIR}/src/user/*.c  # C语言应用文件
  ${CMAKE_SOURCE_DIR}/src/user/*.cpp# C++语言应用文件
)

# --------------------------
# 编译与链接配置
# --------------------------
# 创建可执行目标（最终生成的ELF文件）
add_executable(${PROJECT_NAME}
  ${SYSTEM_SRCS}   # 系统核心代码
  ${DRIVER_SRCS}   # 驱动层代码
  ${USER_SRCS}     # 用户应用代码
)

# 通用编译选项（C、C++、汇编共用）
target_compile_options(${PROJECT_NAME} PRIVATE
  ${MCU_FLAGS}               # 芯片架构参数
  -Wall -Wextra              # 开启常用警告（提高代码质量）
  -O2                        # 优化等级（平衡代码大小和执行效率）
  -ffunction-sections        # 将每个函数放在独立的代码段
  -fdata-sections            # 将每个数据放在独立的数据段
)

# C语言特定编译选项
# 对所有C源文件启用C99标准（支持较新的C语言特性）
set_property(SOURCE ${DRIVER_SRCS} ${USER_SRCS} ${SYSTEM_SRCS} 
  PROPERTY COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:C>:-std=c99>
)

# C++语言特定编译选项
set_property(SOURCE ${DRIVER_SRCS} ${USER_SRCS}
  PROPERTY COMPILE_OPTIONS 
  $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>    # 启用C++17标准
  $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions> # 禁用异常处理（嵌入式系统常用，减小体积）
  $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>       # 禁用运行时类型信息（减小体积，降低复杂度）
)

# 汇编文件编译选项
# 汇编文件需要预处理（支持#include和宏），因此添加-xassembler-with-cpp
set_source_files_properties(
  ${CMAKE_SOURCE_DIR}/src/system/startup_stm32f10x_md.s
  PROPERTIES
  COMPILE_OPTIONS "${MCU_FLAGS};-xassembler-with-cpp"
)

# 编译宏定义（传递给C/C++预处理器）
target_compile_definitions(${PROJECT_NAME} PRIVATE
  STM32F10X_MD         # 指定芯片类型为中等密度（STM32F103C8T6属于此类）
  USE_STDPERIPH_DRIVER # 启用标准外设库驱动（需配合库文件使用）
)

# 输出文件配置
set_target_properties(${PROJECT_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}  # 生成文件放在build目录
  SUFFIX ".elf"                                # 可执行文件后缀为.elf
)

# 链接选项（控制最终ELF文件的生成）
target_link_options(${PROJECT_NAME} PRIVATE
  ${MCU_FLAGS}                 # 芯片架构参数（链接时需与编译参数一致）
  -T${LINKER_SCRIPT}           # 指定链接器脚本（定义内存布局）
  -nostartfiles -nostdlib      # 不使用标准启动文件和库（嵌入式系统自定义）
  -Wl,--gc-sections            # 移除未使用的代码段和数据段（减小固件体积）
  -Wl,-Map=${PROJECT_NAME}.map # 生成映射文件（用于分析内存占用）
  -lc -lm -lstdc++             # 链接必要的库：C标准库、数学库、C++标准库
)

# 构建后处理：生成二进制固件并提示烧录命令
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
  # 从ELF文件生成二进制固件（.bin格式，可直接烧录到Flash）
  COMMAND ${CMAKE_OBJCOPY} -O binary "$<TARGET_FILE:${PROJECT_NAME}>" firmware.bin
  
  # 显示固件大小信息（代码段、数据段等占用情况，检查是否超过Flash/RAM容量）
  COMMAND ${CMAKE_SIZE} "$<TARGET_FILE:${PROJECT_NAME}>"
  
  # 打印烧录提示（方便开发者直接复制命令）
  COMMAND echo "========================================================="
  COMMAND echo "烧录命令: st-flash write firmware.bin 0x08000000"
  COMMAND echo "========================================================="
  
  COMMENT "生成固件完成（.elf 和 .bin 文件已生成）"
)