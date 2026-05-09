# PhoneticIM (iOS IPA Keyboard)

中文 | [English](#english)

一个面向 iOS 15+ 的国际音标（IPA）输入法项目，支持 26 键助记码输入、最长匹配转换、内置英式小词典查询，并提供企业签名打包脚本。

## 功能特性

- 26 键助记码输入（如 `th -> θ`, `sh -> ʃ`, `aa -> ɑː`）
- 最长匹配优先转换（避免 `th` 被拆成 `t+h`）
- 两种输入工作模式：
  - 直输模式：助记码直接按规则转换
  - 词典模式：英文单词查询 IPA（内置 `en_UK.txt`）
- 聊天场景动作键自适应（根据 `returnKeyType` 显示发送/搜索/前往等）
- 宿主 App 内置使用说明页（启动即显示）
- iOS 企业签名打包脚本（输出 `.ipa` + 安装 `plist`）

## 项目结构

```text
App/                          # 宿主 App（说明页、资源）
ios/KeyboardExtension/        # 键盘扩展 UI 与交互
ios/IPAKeyboardCore/          # 转换引擎、词典服务、设置模型
data/en_UK.txt                # 内置小词典数据源
build_enterprise_ipa.sh       # 企业签名打包脚本
project.yml                   # XcodeGen 配置
```

## 环境要求

- macOS + Xcode（建议 Xcode 15+）
- iOS Deployment Target: 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Apple 开发者证书与描述文件（企业内部分发场景）

## 快速开始

1. 生成工程

```bash
xcodegen generate
```

2. 打开工程

```bash
open PhoneticIM.xcodeproj
```

3. 选择签名团队/描述文件后编译运行（真机或模拟器）

## 键盘启用步骤（iOS）

1. 安装并打开 `PhoneticIM` App
2. 进入系统设置：通用 -> 键盘 -> 键盘 -> 添加新键盘
3. 选择 `IPAKeyboard`
4. 在任意输入框切换到该键盘开始使用

## 词典说明

- 当前词典查询只走本地资源：`data/en_UK.txt`
- 不依赖远程词典包和在线 API
- 若词条未命中，会显示未命中提示

## 企业签名打包

项目根目录提供脚本：`build_enterprise_ipa.sh`

打包后默认输出到 `Release/`：

- `PhoneticIM.ipa`
- `manifest.plist`（用于企业内网页分发安装）

> 企业证书仅可用于企业内部设备分发，不可面向公众应用商店分发。

## 测试建议

- 转换规则单测：`Tests/IPATransliteratorTests.swift`
- 在 Notes / Safari / IM 输入框分别验证：
  - 助记码转换
  - 词典查询
  - 发送/搜索等动作键语义

## License

可按你的发布需求补充（如 MIT / Apache-2.0 / Proprietary）。

---

## English

PhoneticIM is an iOS 15+ custom keyboard project for IPA input. It provides mnemonic 26-key typing, longest-match transliteration, an embedded UK mini-lexicon, and enterprise IPA packaging scripts.

## Features

- 26-key mnemonic IPA mapping (e.g. `th -> θ`, `sh -> ʃ`, `aa -> ɑː`)
- Longest-match-first transliteration
- Two working modes:
  - Direct mode: mnemonic code transliteration
  - Dictionary mode: English word -> IPA lookup (`en_UK.txt`)
- Context-aware action key (`Send`, `Search`, `Go`, etc.) via `returnKeyType`
- Host app opens directly to the built-in usage guide
- Enterprise build script for signed `.ipa` + install `plist`

## Repository Layout

```text
App/                          # Host app (guide page, assets)
ios/KeyboardExtension/        # Keyboard extension UI & interactions
ios/IPAKeyboardCore/          # Transliteration, dictionary, settings
data/en_UK.txt                # Embedded mini lexicon
build_enterprise_ipa.sh       # Enterprise packaging script
project.yml                   # XcodeGen spec
```

## Requirements

- macOS + Xcode (Xcode 15+ recommended)
- iOS deployment target 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Valid Apple signing assets (enterprise/internal distribution)

## Quick Start

1. Generate project

```bash
xcodegen generate
```

2. Open in Xcode

```bash
open PhoneticIM.xcodeproj
```

3. Configure signing and run on simulator/device

## Enable Keyboard on iOS

1. Install and open `PhoneticIM`
2. Go to Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard
3. Add `IPAKeyboard`
4. Switch to the keyboard in any text field

## Dictionary Notes

- Dictionary lookup is local-only (`data/en_UK.txt`)
- No remote pack or online API dependency
- Misses will show a fallback “not found” state

## Enterprise Packaging

Use `build_enterprise_ipa.sh` in project root.

Artifacts are generated in `Release/`:

- `PhoneticIM.ipa`
- `manifest.plist`

> Enterprise-signed builds are for internal company devices only.

## Validation Checklist

- Transliteration tests: `Tests/IPATransliteratorTests.swift`
- Verify in Notes / Safari / IM fields:
  - mnemonic conversion
  - dictionary lookup
  - action key semantics (`Send/Search/Go`)
