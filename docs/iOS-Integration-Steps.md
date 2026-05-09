# Xcode 接入步骤（iOS 15+）

## 1) 创建工程与 Target

1. 新建 iOS App 工程（例如 `PhoneticIM`）。
2. `File > New > Target...` 添加 `Custom Keyboard Extension`（例如 `IPAKeyboard`）。
3. 将 Extension 的 Deployment Target 设为 `iOS 15.0`。

## 2) 添加代码文件

- 添加到 **App + Extension**：
  - `ios/IPAKeyboardCore/IPAKeyMap.swift`
  - `ios/IPAKeyboardCore/IPAComposer.swift`
- 只添加到 **Extension**：
  - `ios/KeyboardExtension/KeyboardView.swift`
  - `ios/KeyboardExtension/KeyboardViewController.swift`

确保 `KeyboardViewController.swift` 的 target membership 是键盘扩展 target。

## 3) 配置 Info.plist（Extension）

在扩展的 `Info.plist` 中确认：

- `NSExtension` > `NSExtensionPointIdentifier` = `com.apple.keyboard-service`
- `NSExtension` > `NSExtensionPrincipalClass` = `$(PRODUCT_MODULE_NAME).KeyboardViewController`
- `RequestsOpenAccess` = `NO`（MVP 离线建议）

## 4) 签名与安装

1. 在 App 和 Extension 的 `Signing & Capabilities` 里选同一个 Team。
2. 连接 iPhone（iOS 15+），选择真机运行。
3. 首次安装后到系统设置启用键盘：
   - `设置 > 通用 > 键盘 > 键盘 > 添加新键盘`
   - 选择你的 `IPAKeyboard`

## 5) 使用与验证

- 在备忘录/Safari 输入框切换到 IPAKeyboard。
- 点击主键应上屏 primary 字符。
- 点击候选条应替换为候选字符。
- 验证 `Space/Delete/Return/Globe` 行为。

