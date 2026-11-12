# Changelog

格式依 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版號依 [SemVer](https://semver.org/lang/zh-TW/)。

## [0.1.0] - 2026-11-12

### Added
- 首次公開發布：補檔廣告（手機 mockup 廣告）從需求信到 1x／2x JPG 的全流程 skill。
- 為什麼做：每張補檔廣告都是「同一套模版，只換封面、歌名、藝人」，手動複製模版、逐張換圖再輸出 9 種尺寸×2 倍率，重複又容易漏；交給 skill 後只剩一次人工核對。
- 建 page 時自動把手機 mockup 內層的元件改連到新 page（不改到模版本體）。
- 2x 輸出：Figma MCP 截圖不會放大，改用「暫存放大兩倍版」截圖、截完自動刪除。
- `scripts/export_tkk.sh`：下載截圖 → JPEG 品質 100 → 依檔名 `寬x高` 逐張驗像素，不合格自動刪並回退出碼 2。
- Notion 開卡前先查重，同單號已有卡就沿用。
- 所有公司內部真值改讀 `~/.config/sv-tkk/env`。
