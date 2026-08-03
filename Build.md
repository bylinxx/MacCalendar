# Build Guide

## 环境要求

- macOS 14.0+
- Xcode 16+
- 命令行工具：`xcode-select --install`

## 快速开始

```bash
# 编译并启动
./build.sh run

# 仅编译 Debug
./build.sh

# 编译 Release 并打包 DMG
./build.sh dmg
```

## 命令参考

| 命令 | 用途 | 默认架构 |
|---|---|---|
| `debug` | Debug 构建 | native（当前 CPU） |
| `release` | Release 构建（跳过签名） | universal |
| `dmg` | Release 构建 + DMG 打包 | universal |
| `run` | Debug 构建后启动 App | native |
| `clean` | 清理构建产物 | — |
| `help` | 显示帮助 | — |

## 架构选项

通过 `--arch` 指定目标架构：

| 参数 | 说明 |
|---|---|
| `native` | 当前 Mac CPU 架构（arm64 或 x86_64） |
| `universal` | 通用二进制，同时支持 Intel 和 Apple Silicon |
| `arm64` | Apple Silicon 专用 |
| `x86_64` | Intel 专用 |

示例：

```bash
# Debug 构建通用二进制
./build.sh debug --arch universal

# Release 仅构建 arm64
./build.sh release --arch arm64

# 打包仅 Intel 的 DMG
./build.sh dmg --arch x86_64
```

## 详细日志

加 `-v` 查看完整 xcodebuild 输出：

```bash
./build.sh dmg -v
```

## 构建产物

```
build/
├── universal/            # 通用二进制产物
│   ├── Debug/MacCalendar.app
│   ├── Release/MacCalendar.app
│   └── MacCalendar.dmg   # DMG 安装包
├── arm64/                # Apple Silicon 专用
└── x86_64/               # Intel 专用
```

## 常见问题

### 签名错误

Release 构建已跳过签名（`CODE_SIGN_IDENTITY="-"`），可直接运行。如需分发，需替换为有效的 Apple 开发者证书。

### 权限问题

```bash
# 首次运行 Release 构建的 App 需解除系统隔离
xattr -cr build/universal/Release/MacCalendar.app
```