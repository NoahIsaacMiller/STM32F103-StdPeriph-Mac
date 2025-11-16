# STM32F103C8T6 标准外设库项目模板

基于STM32F103C8T6微控制器的嵌入式开发模板，集成STM32标准外设库（V3.6.0）与CMake构建系统，适配macOS Apple Silicon及Linux环境，提供完整的编译、烧录与调试流程。


## 项目特点

- **开箱即用**：预置标准外设库核心驱动与初始化代码，无需手动移植
- **跨平台兼容**：通过CMake实现一键配置，完美支持macOS（包括Apple Silicon）与Linux系统
- **自动化工作流**：集成`f1flow`脚本，支持多命令组合（如`./f1flow clear build flash`），简化开发流程
- **规范结构**：严格分离驱动层与用户层代码，便于团队协作与项目扩展
- **可视化反馈**：脚本执行过程中通过 emoji 与色彩标识状态，操作结果直观清晰


## 硬件规格

| 参数                | 详情                          |
|---------------------|-------------------------------|
| 微控制器            | STM32F103C8T6（Cortex-M3内核） |
| 主频                | 最高72MHz                     |
| 存储                | 64KB Flash / 20KB SRAM        |
| 外设支持            | GPIO、USART、SPI、I2C、定时器等 |
| 封装形式            | LQFP48                        |


## 软件环境

### 依赖工具

- **交叉编译器**：`arm-none-eabi-gcc`（版本10及以上）
- **构建工具**：`cmake`（3.10+）、`make`
- **烧录工具**：`st-link`（含`st-flash`命令）
- **推荐IDE**：VS Code（搭配C/C++、CMake Tools插件）


## 项目结构

```
.
├── arm-none-eabi-toolchain.cmake  # ARM交叉编译工具链配置
├── CMakeLists.txt                # 主构建脚本（核心配置）
├── f1flow                         # 自动化工作流脚本（支持多命令）
├── driver/                       # 标准外设库驱动实现（.c）
├── inc/                          # 头文件总目录
│   ├── driver/                   # 驱动头文件（与driver/对应）
│   └── user/                     # 用户应用头文件（自定义声明）
├── ld/                           # 链接器脚本
│   └── stm32_flash.ld            # 内存布局定义（Flash/RAM分配）
├── src/                          # 源代码目录
│   ├── system/                   # 系统核心代码
│   │   ├── startup_stm32f10x_md.s # 启动汇编（中断向量表）
│   │   ├── system_stm32f10x.c    # 系统时钟初始化
│   │   └── core_cm3.c            # Cortex-M3内核函数
│   └── user/                     # 用户应用代码
│       ├── main.c                # 程序入口
│       └── stm32f10x_it.c        # 中断服务函数
└── .vscode/                      # VS Code调试配置（可选）
    ├── launch.json               # 调试器配置
    └── settings.json             # 项目特定设置
```


## 快速开始

### 1. 环境搭建

```bash
# 安装依赖（macOS示例，使用Homebrew）
brew install arm-none-eabi-gcc stlink cmake

# 克隆项目
git clone https://github.com/NoahIsaacMiller/STM32F103-StdPeriph-Mac.git
cd STM32F103-StdPeriph-Mac

# 赋予脚本执行权限
chmod +x f1flow
```


### 2. 核心操作指南

使用`f1flow`脚本管理全流程，支持单命令与多命令组合：

```bash
# 检查开发环境是否就绪（工具+项目结构）
./f1flow check

# 清空屏幕后编译项目
./f1flow clear build

# 清理构建产物→重新编译→烧录固件
./f1flow clean build flash

# 执行完整流程（检查→清理→编译→烧录）
./f1flow full

# 重置开发板
./f1flow reset

# 查看所有可用命令
./f1flow help
```


## 开发指南

### 新增功能模块

1. 在`src/user/`目录下创建功能源文件（如`led.c`、`uart.c`）
2. 在`inc/user/`目录下创建对应头文件（如`led.h`、`uart.h`）
3. 在`CMakeLists.txt`中添加新文件路径（若未启用自动扫描）
4. 在`main.c`中包含头文件并调用功能函数


### 外设配置步骤

1. 打开`inc/user/stm32f10x_conf.h`
2. 取消对应外设的注释以启用驱动（例如启用GPIO：`#define USE_STDPERIPH_GPIO`）
3. 在用户代码中初始化外设（参考标准外设库官方示例）：
   ```c
   // 示例：初始化PA5为推挽输出（LED引脚）
   GPIO_InitTypeDef GPIO_InitStructure;
   RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
   GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
   GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
   GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
   GPIO_Init(GPIOA, &GPIO_InitStructure);
   ```


### 系统时钟调整

默认配置：8MHz外部晶振（HSE）→ 通过PLL倍频至72MHz。如需修改：

1. 编辑`src/system/system_stm32f10x.c`
2. 调整`SetSysClockTo72()`函数中的PLL参数（如倍频系数、时钟源）
3. 同步修改`stm32_flash.ld`中的Flash等待周期（若时钟频率变更）


## 注意事项

1. **芯片型号适配**：
   - 默认适配STM32F103C8T6（中等密度设备，`STM32F10X_MD`）
   - 更换其他F1系列芯片时，需修改：
     - `CMakeLists.txt`中的设备定义（如高密度设备改为`STM32F10X_HD`）
     - 链接器脚本`ld/stm32_flash.ld`中的Flash/RAM容量

2. **固件大小限制**：
   - STM32F103C8T6 Flash容量为64KB，编译时注意`text`段（代码）不超过此限制
   - 可通过`./f1flow build`输出的固件信息查看占用情况

3. **调试配置**：
   - VS Code用户可直接使用`.vscode/launch.json`配置OpenOCD调试
   - 需配合ST-Link V2调试器，确保`stlink-server`服务正常运行


## 许可证

本项目基于STM32标准外设库V3.6.0构建，遵循STMicroelectronics的许可协议。用户代码部分采用MIT许可，允许自由修改与二次分发。