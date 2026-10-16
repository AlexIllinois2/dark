# dark

一个极简 Android 应用：打开后只做一件事 —— **显示纯黑，让屏幕一个像素都不发光**。

## 安装

```bash
adb install -r dist/dark.apk
```

或者把 `dist/dark.apk`（46 KB）传到手机上点开安装。

- 包名 `app.dark`，版本 1.0，minSdk 23（Android 6.0+），targetSdk 34
- 已用 v2 + v3 方案签名，可直接安装

## 打开后发生什么

| 行为 | 说明 |
| --- | --- |
| 全屏纯黑 `#FF000000` | OLED 屏上这些像素完全不发光；LCD 屏背光也压到最低 |
| 沉浸式全屏 | 状态栏、导航栏全部隐藏，屏幕上不留任何亮色像素 |
| 亮度锁 0 | 窗口亮度设为最低 |
| 保持常亮 | 一直显示黑屏，而不是自动息屏 |
| 启动画面纯黑 | Android 12+ 的闪屏图标被替换为透明，点开瞬间就是黑的 |

## 退出

从屏幕底部/侧边向内滑，临时唤出导航栏后返回；或者直接用手势返回 / 多任务键。

## 想改

- 不想锁亮度：删掉 `MainActivity.java` 里 `params.screenBrightness = 0f;` 那三行
- 不想常亮：删掉 `window.addFlags(FLAG_KEEP_SCREEN_ON);` 那一行

## 重新构建

工具链已放在 `.toolchain/`（Temurin JDK 17 + Android SDK：build-tools 34.0.0、platforms/android-34、platform-tools）：

```bash
bash tools/build_apk.sh      # 直接调 aapt2 / javac / d8 / zipalign / apksigner 构建，产出 dark.apk
python tools/make_icons.py   # 重新生成黑底白字 "dark" 启动图标
```

也可以直接用 Android Studio 打开根目录（`app/` 是标准 Gradle 模块，AGP 8.5.2）。

## 签名

`keystore/dark.jks`（PKCS12），别名 `dark`，密码 `darkdark`。
覆盖安装升级必须用同一个密钥，请自行备份。

## 图标

![图标](docs/icon.png)

黑底白字「dark」，192px 传统图标 + 自适应图标（前景白色文字卡在 66dp 安全圆内，
圆形、圆角方形等任何遮罩下都不会被裁切）。预览图见 `docs/icon.png`。

## 目录结构

```
app/src/main/
  AndroidManifest.xml
  java/app/dark/MainActivity.java     # 全部逻辑：纯黑 + 沉浸式 + 亮度 0 + 常亮
  res/values/themes.xml               # 纯黑主题（含启动画面）
  res/mipmap-*/                       # 启动图标
tools/
  build_apk.sh                        # 构建脚本
  make_icons.py                       # 图标生成脚本
docs/icon.png                         # 图标预览图
dist/dark.apk                         # 成品（构建输出）
.toolchain/                           # 本地 JDK + Android SDK（可删，删了就得重装才能重新构建）
keystore/dark.jks                     # 签名密钥
```
