## MacCalendar - 完全免费&开源的离线小而美 macOS 菜单栏日历 App

![SwiftUI](https://img.shields.io/badge/SwiftUI-EC662F?style=flat&logo=swift&logoColor=white)
[![macOS](https://img.shields.io/badge/macOS-14.0+-green.svg)](https://github.com/bylinxx/MacCalendar/releases/latest)
![GitHub Release](https://img.shields.io/github/v/release/bylinxx/MacCalendar)


## 主要功能

- 界面简洁精致，轻量化占用资源极小，完全离线不需要联网

- 运行后静默显示在菜单栏，右键或者按快捷键[Command + ，]打开设置窗口

- 中国农历、24节气、大部分节日（公历或农历）

- 中国法定放假安排（自2015年以来）
  
- 个性化图标、日历类型、周数等显示

- 读取系统日历数据，可按类型筛选显示，支持修改和删除

- 自定义菜单栏显示内容，支持图标/日期/时间/自定义格式

- 输入年/月快捷跳转

<img width="339" height="409" alt="截屏2025-12-16 23 14 34" src="https://github.com/user-attachments/assets/130caa88-df33-4415-ba0c-8f2818729a51" />
<img width="335" height="345" alt="截屏2025-12-16 23 12 04" src="https://github.com/user-attachments/assets/6de91408-3a1d-48e7-867b-4803e608019d" />
<img width="511" height="391" alt="截屏2025-12-19 23 38 07" src="https://github.com/user-attachments/assets/37957e03-7ce2-4868-98a9-c936be371e2b" />

## 安装

### 手动安装
1. 从 [GitHub Releases](https://github.com/bylinxx/MacCalendar/releases/latest) 下载最新版本 dmg 格式的镜像
2. 双击打开下载的 dmg 镜像
3. 拖动MacCalendar图标到Applications图标完成安装
4. 如何更新？ 重复上述过程，当提示存在的时候点击“替换”

### homebrew安装
1. 在命令行执行 brew tap bylinxx/tap 引入tap
2. 在命令行执行 brew install maccalendar 完成安装
3. 由于没有购买开发者签名，首次打开会提示“无法验证开发者”或“应用已损坏”，必须在“系统设置 -> 隐私与安全性 -> 安全性”中点击“仍要打开”，或者在终端执行 xattr -cr /Applications/MacCalendar.app 来移除安全隔离标记
4. 如何更新？ 在命令行执行 brew update 拉取更新，再执行 brew upgrade maccalendar 安装更新

## 中国法定节假日数据来源

- [NateScarlet/holiday-cn](https://github.com/NateScarlet/holiday-cn)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=bylinxx/MacCalendar&type=Timeline)](https://www.star-history.com/#bylinxx/MacCalendar&Timeline)
