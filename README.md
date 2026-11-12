# sv-tkk

手機 mockup 補檔廣告出圖的 Claude Code skill：讀需求信 → Notion 開需求卡 → Figma 複製模版、換封面圖與歌名／藝人 → 停下讓你核對 → 輸出 1x＋2x JPG。

**觸發詞**：「tkk出圖」（可接單號，例「tkk出圖 1111」；可依自己習慣改）

## 這是去識別化的公開版

原始版本含公司內部真值（Figma fileKey、node id、Notion data_source_id、人員、路徑）。本版全部改讀 `~/.config/sv-tkk/env`，**安裝後必須自行設定**，見 `SKILL.md` 開頭。

| 設定 | 意思 | 必填 |
|---|---|---|
| `FIGMA_FILE_KEY` | 你的 Figma 檔 key | ✅ |
| `TPL_PAGE_ID`／`TPL_COVER_ID`／`TPL_WORK_ID` | 模版 page、封面元件、播放畫面元件的 node id | ✅ |
| `TPL_EXPORT_SECTION_ID` | 要輸出的 section | ✅ |
| `TPL_EXTRA_SECTION_IDS` | 只做不輸出的 section | 選填 |
| `NOTION_DATA_SOURCE_ID` | Notion 需求資料庫 | 選填（空的就不開卡） |
| `MY_EMAIL` | 你的信箱 | ✅ |
| `MAIL_SUBJECT_KEYWORD` | 需求信主旨關鍵字 | ✅ |
| `OUTPUT_DIR`／`WORK_DIR` | 交付夾、素材暫存夾 | ✅ |

## 你的 Figma 檔要長什麼樣

一個模版 page，內含 `Cover_change`、`Work here` 兩個元件，和一個 frame 名含 `寬x高` 的 section。詳見 `SKILL.md`〈你的 Figma 檔要有這個結構〉。

## 需要的 MCP

Figma（含 `use_figma`／`upload_assets`／`get_screenshot`）必要；Gmail、Notion 依流程需要。macOS（用 `sips` 轉檔驗尺寸）。

## 安裝

```bash
git clone https://github.com/SV-Designer/sv-tkk.git ~/.claude/skills/sv-tkk
```

## 2x 怎麼做到的

Figma MCP 的截圖不會放大，所以輸出 2x 時會先在 Figma 複製一份放大兩倍的暫存版來截圖，截完立刻刪掉。`scripts/export_tkk.sh` 負責下載、轉 JPEG（品質 100）、依檔名尺寸逐張驗像素，不合格自動刪掉並回非零退出碼。
