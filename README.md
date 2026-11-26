# LKK-IME

LKK 是一款源自 Yahoo! KeyKey 的開源繁體中文輸入法。出於對經典輸入法的懷念，本專案希望透過移植與維護，讓熟悉 Yahoo! KeyKey 的使用者能夠在現代 macOS 上延續原有的使用體驗。

LKK is an open-source Traditional Chinese input method derived from Yahoo! KeyKey. Inspired by nostalgia for the classic input method, this project aims to preserve its original user experience and keep it running on modern macOS.

原始碼基礎 / Upstream: [YahooArchive/KeyKey](https://github.com/YahooArchive/KeyKey) 1.1.2528. [Porting scope](docs/UPSTREAM.md).

## 功能 / Features

- 原版智慧注音、傳統注音、倉頡及速成 / Original Smart Mandarin, Traditional Mandarin, Cangjie and Simplex.
- 原版組字、候選視窗、標點、快捷鍵與偏好設定 / Original composition, candidate panels, punctuation, shortcuts and preferences.
- Apple Silicon 原生建置 / Native ARM64 build.
- 本機詞庫及學習資料 / Local vocabulary and learning data.
- 不使用已停止的 Yahoo 線上服務或遙測 / No retired Yahoo online services or telemetry.

## 建置 / Build

需要 Apple Silicon Mac、macOS 26 或更新版本、完整 Xcode 與 Python 3。首次建置會下載並核對公開詞庫資料。執行：

Requires an Apple Silicon Mac, macOS 26 or later, Xcode and Python 3. The first build downloads and verifies public vocabulary data.

```sh
bash scripts/build.sh
```

建置程序保留原版 Xcode 目標，產生替代詞庫並執行測試，最後在 `build/artifacts/` 輸出開發版 ZIP、PKG 及 SHA-256 校驗值。

The script builds the original Xcode targets, generates the replacement SQLite database, tests the original input contexts, and creates an ad-hoc-signed development ZIP, PKG, and SHA-256 checksums in `build/artifacts/`.

## 狀態 / Status

目前為開發測試版本，尚未完成 Apple 公證。原始商業詞庫未包含於本專案，因此候選詞排序與繁簡轉換結果可能有所不同。已停止的 Yahoo 字典、更新、MobileMe 與網路服務不再提供；正式發布前仍需完成實際應用程式與外觀驗收。

This is a development build, not a notarized public installer. The original proprietary language model is not redistributed; word ranking and phrase conversion may therefore differ. The retired dictionary, update, MobileMe and web services are unavailable. Manual cross-application and visual acceptance remain necessary before a production release.

## 授權 / License

BSD-3-Clause. See [LICENSE](LICENSE) and [third-party notices](docs/THIRD-PARTY-NOTICES.md). LKK is an independent project, not affiliated with or endorsed by Yahoo.
