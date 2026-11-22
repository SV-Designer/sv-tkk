---
name: sv-tkk
description: >-
  手機 mockup 補檔廣告出圖全流程：Gmail 抓需求信 → Notion 開需求卡 → Figma 新建 page 放模版副本、
  換封面圖與歌名／藝人 → 停下等使用者核對 → 指定 section 全部 frame 輸出 1x＋2x JPG 到交付夾。
  觸發詞：「tkk出圖」（可接單號，例「tkk出圖 1111」；觸發詞可依自己習慣改）。
  需要 Gmail MCP、Notion MCP、Figma MCP（use_figma／upload_assets／get_screenshot）。
---

# sv-tkk：手機 mockup 補檔廣告出圖

一封「補檔廣告 MMDD 設計需求」信 → 一張 Notion 卡 ＋ 一個 Figma page ＋ N 張 1x／N 張 2x JPG。

## 🔴 這是去識別化的公開版，安裝後要先設定

原始版本含公司內部真值（Figma 檔、node id、Notion 資料庫、人員、路徑）。本版全部改讀設定檔，**第一次用之前**：

```bash
mkdir -p ~/.config/sv-tkk
cat > ~/.config/sv-tkk/env <<'EOF'
FIGMA_FILE_KEY="<你的 Figma 檔 key>"
TPL_PAGE_ID="<模版 page 的 node id，例 0:1>"
TPL_COVER_ID="<Cover_change 元件 node id>"
TPL_WORK_ID="<Work here 元件 node id>"
TPL_EXPORT_SECTION_ID="<要輸出的 section node id（例 PC）>"
TPL_EXTRA_SECTION_IDS="<只做不輸出的 section node id，逗號分隔；沒有就留空>"
NOTION_DATA_SOURCE_ID="<Notion 需求資料庫 data_source_id，不開卡可留空>"
MY_EMAIL="<你自己的信箱，用來判斷哪封信已回過、查自己的 Notion user id>"
MAIL_SUBJECT_KEYWORD="補檔廣告"
OUTPUT_DIR="$HOME/Downloads/sv-tkk"
WORK_DIR="<素材暫存夾絕對路徑>"
EOF
chmod 600 ~/.config/sv-tkk/env
```

開工時先 `source ~/.config/sv-tkk/env`；下文的 `$變數` 都來自這裡。

## 你的 Figma 檔要有這個結構（本 skill 假設的骨架）

- 一個模版 page，內含：
  - `Cover_change`（COMPONENT）：封面圖，fill 是 IMAGE
  - `Work here`（COMPONENT）：手機播放畫面，內含 2 個 `Cover_change` instance、`song`／`artist` 兩個 TEXT
  - 一個要輸出的 SECTION（例 `PC`），內含多個 frame，**frame 名含 `寬x高`**（例 `PC_728x90`），每個 frame 裡有一個手機 mockup instance，mockup 內層套著 `Work here` instance
- 手機 mockup 元件放在另一個 page（本 skill 不動它）
- **不直接改模版本體**——每次都複製到新 page

## 停點（只有一個必停）

| # | 時機 | 做法 |
|---|---|---|
| G1 | Figma 套完 | 開 Figma 桌機版到新 page，提示語見步驟 7 ⛔ 無條件停 |

其他步驟遇到下列狀況才停：找到多封未處理的信（問做哪封）、素材下載不到、信裡寫「QR Code 要換」、Notion 已有同名卡（不重開，直接沿用）。

---

## 步驟

### 0. 準備
- 動 `use_figma` 前**一定先載入 `figma:figma-use` skill**（Figma MCP 官方硬性要求）。
- `create_session(fileKey)` 拿 sessionId，之後每個 Figma 呼叫都帶。
- 變數：`D=$(date +%Y%m%d)`（**用今天，不用來信日**；Figma page 名與輸出資料夾共用）。

### 1. 抓信
```
search_threads(query='subject:($MAIL_SUBJECT_KEYWORD) newer_than:30d')
```
- 觸發時有給單號（例 1111）→ 挑主旨含該單號的那封。
- 沒給 → 列出近 30 天的，排除「自己已回信過」的 thread（thread 內有 `$MY_EMAIL` 寄出的 Re:），剩 1 封直接做、多封就問。
- `get_thread(threadId, messageFormat='PLAIN_TEXT')`。🚫 不用 FULL_CONTENT（灌爆 context）。

從信抽出（以下是本 skill 原本對應的信件格式，你的格式不同就改這張表）：

| 欄位 | 怎麼抓 |
|---|---|
| 單號 MMDD | 主旨 `補檔廣告 (\d{4})` |
| 死線 | `期望收到日期：YYYY.MM.DD（週）`（舊信寫 `Deadline：`）→ `YYYY-MM-DD` |
| artist | `藝人改為[ ... ]` → 去頭尾空白 |
| song | `歌曲改為[ ... ]` |
| 素材連結 | `藝人照：` 下一行網址（Google Drive 或其他雲端） |
| 尺寸 | `尺寸：` 下一行，原文照抄 |
| 需求負責人 | 寄件者 email |
| QR Code | 寫「與之前相同」→ 不動；寫別的 → ⛔ 停下問 |
| 其他備註 | 看不懂的新要求 → 停下問 |

### 2. Notion 開卡（`NOTION_DATA_SOURCE_ID` 空的就跳過）
先查重：
```
query_data_sources(data={data_source_urls:['collection://$NOTION_DATA_SOURCE_ID'],
  query:'SELECT url, Name FROM "collection://$NOTION_DATA_SOURCE_ID" WHERE Name LIKE ?',
  params:['%$MAIL_SUBJECT_KEYWORD%{MMDD}%']})
```
→ **有就不開新卡**，告知使用者沿用該卡（附連結）。

沒有才建，`notion-create-pages`（`allow_async:false`），parent＝`{data_source_id:'$NOTION_DATA_SOURCE_ID'}`。
先 `notion-fetch` 資料庫看欄位，**欄位名與選項照你的資料庫**；本 skill 原本的對應：
- `Name`：`<網站名>_補檔廣告 {MMDD}`
- 日期欄（死線）：`date:<欄位>:start`＝`YYYY-MM-DD`、`date:<欄位>:is_datetime`＝`0`
- 負責製作的人（person 陣列）：`notion-get-users(query=<MY_EMAIL 的帳號>)` 查自己的 user id
- 需求負責人（person，**單一** id、不是陣列）：用寄件者 email 查；查不到就留空並告知
- icon：workspace 自訂 emoji 可以傳 `":<名稱>:"`

建完 `notion-fetch` 回讀一次，核對屬性與內文。內文範例：
```
期望收到日期：**YYYY.MM.DD（週）**

- 素材：<素材網址>
- 尺寸：`<信裡的尺寸原文>`
- 文字：
  - Song：<song>
  - Artist：<artist>
```
> ⚠️ 把別人加進 person 欄位，Notion 可能會通知對方；測試時先別填需求負責人。

### 3. 下載素材
工作夾：`W="$WORK_DIR/$D-<artist>"`
- **Google Drive** `drive.google.com/file/d/<ID>/...` →
  `curl -sL -o "$W/cover.bin" "https://drive.google.com/uc?export=download&id=<ID>"`，再 `file` 確認是 JPEG/PNG。
  拿到 HTML（非公開或檔案太大）→ 改用 Google Drive MCP `download_file_content`；再不行 ⛔ 請使用者手動下載。
- **Drive 資料夾** → 用 Google Drive MCP 列出檔案；多張就 ⛔ 問用哪張。
- **要登入的雲端** → 不自己找帳密，⛔ 請使用者下載後給路徑。
- 轉成上傳檔（< 10MB 才能上傳）：長邊 > 2400 才縮，🚫 小圖別用 `sips -Z` 硬放大
```bash
L=$(sips -g pixelWidth -g pixelHeight "$W/cover.bin" | awk '/pixel/{print $2}' | sort -n | tail -1)
if [ "$L" -gt 2400 ]; then sips -s format jpeg -s formatOptions 92 -Z 2400 "$W/cover.bin" --out "$W/cover.jpg"
else sips -s format jpeg -s formatOptions 100 "$W/cover.bin" --out "$W/cover.jpg"; fi
```

### 4. Figma：建 page＋接線（一次 `use_figma`）
（`<...>` 換成 env 裡的值；`use_figma` 不會讀 shell 變數，要寫成字串常數）
```js
const tpl = await figma.getNodeByIdAsync('<TPL_PAGE_ID>');
await figma.setCurrentPageAsync(tpl);
const cover = await figma.getNodeByIdAsync('<TPL_COVER_ID>');
const work  = await figma.getNodeByIdAsync('<TPL_WORK_ID>');
const pc    = await figma.getNodeByIdAsync('<TPL_EXPORT_SECTION_ID>');
const np = figma.createPage(); np.name = '<D>-<artist>';
figma.root.insertChild(0, np);
const c2 = cover.clone(); np.appendChild(c2); c2.x = cover.x; c2.y = cover.y;
const w2 = work.clone();  np.appendChild(w2); w2.x = work.x;  w2.y = work.y;
const p2 = pc.clone();    np.appendChild(p2); p2.x = pc.x;    p2.y = pc.y;
const MOCKUP = 'INSTANCE[name="<手機 mockup instance 名稱>"]';
for (const i of w2.query('INSTANCE[name=Cover_change]')) i.swapComponent(c2);
for (const m of p2.query(MOCKUP)) {
  m.findOne(n => n.type === 'INSTANCE' && n.name === 'Work here').swapComponent(w2);
}
// TPL_EXTRA_SECTION_IDS 裡每個 section：一樣 clone 到 np＋同樣 swap（只做不輸出）
// 回傳 np.id、c2.id、w2.id、p2.id、各 swap 計數，以及 p2.children 的 name+id
```
🔴 **一定要 swap**：mockup 主元件在別的 page，裡面的 `Work here` 預設連回**模版**的元件；不 swap 就會改到模版、或新 page 換了沒反應。
驗收：swap 計數＝mockup 數；再讀一次確認每個 mockup 內 `Work here` 的 mainComponent 都是 `w2`。

### 5. 換封面圖
```
upload_assets(fileKey, count=1, nodeIds=['<c2 id>'], scaleMode='FILL', currentPageId='<np id>')
curl -s -F "file=@$W/cover.jpg;type=image/jpeg" "<submitUrl>"   # 回 success:true 才算
```
目標是**新 page 的 `Cover_change` 元件本身**（c2），所有 mockup 會一起更新。

### 6. 換文字
Figma 雲端不一定有模版用的字型（例 `Noto Sans CJK TC`）→ 載不到就換 `Noto Sans TC`，字重照原本。
```js
const w2 = await figma.getNodeByIdAsync('<w2 id>');
const sub = { family: 'Noto Sans TC', style: 'Medium' };
await figma.loadFontAsync(sub);
for (const [name, val] of [['song', '<song>'], ['artist', '<artist>']]) {
  const t = w2.findOne(n => n.type === 'TEXT' && n.name === name);
  let fontOk = true;
  for (const s of t.getStyledTextSegments(['fontName'])) { try { await figma.loadFontAsync(s.fontName); } catch (e) { fontOk = false; } }
  if (!fontOk) t.setRangeFontName(0, t.characters.length, sub);
  t.characters = val;
}
```
文字框若是 `TRUNCATE`（固定寬、超出變 …），長歌名可能被截 → G1 請使用者特別看。

### 7. 開 Figma ＋ ⛔ G1
```bash
open "figma://file/$FIGMA_FILE_KEY?node-id=<np id 把 : 換成 ->"
```
同時附一張 `get_screenshot` 給使用者先看。提示語（回覆第一行起）：
> **下一步**：
> 1. 請核對封面裁切與歌名／藝人，確認無誤打 OK 就跑輸出

使用者在 Figma 手動調過（例：封面裁切）沒關係，輸出時讀的是當下畫面。

### 8. 輸出（收到 OK 才做）
`OUT="$OUTPUT_DIR/$D-<artist>"`；已存在 → ⛔ 停下問（不覆蓋）。

1. **2x 要先做暫存放大版**（`get_screenshot` 不會放大，maxDimension 給 2 倍也只回原尺寸）：
```js
const np = await figma.getNodeByIdAsync('<np id>'); await figma.setCurrentPageAsync(np);
const p2 = await figma.getNodeByIdAsync('<p2 id>');
let x = p2.x + p2.width + 1000; const tmp = [];
for (const f of p2.children.filter(n => n.type === 'FRAME')) {
  const c = f.clone(); np.appendChild(c); c.x = x; c.y = p2.y; x += f.width * 2 + 200;
  c.rescale(2); c.name = '_tmp2x_' + f.name; tmp.push({ id: c.id, name: f.name, w: c.width, h: c.height });
}
return tmp;
```
2. 每個原 frame 各 `get_screenshot(nodeId, maxDimension=長邊, contentsOnly=true)`；每個 `_tmp2x_` 各 `get_screenshot(maxDimension=2x 長邊)`。可平行呼叫。
3. 把網址寫成 TSV（`url⇥frame名⇥1或2`，frame 名用**原名**不帶 `_tmp2x_`），**TSV 放 session scratchpad（沒有就 `/tmp`），不放工作夾或輸出夾**；**拿到就立刻跑**（網址短效、視同機密，跑完刪 TSV）：
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/export_tkk.sh" "$OUT" "<tsv>"
```
退出碼 0＝全合格；2＝有不合格（已自動刪），重取該張截圖再跑。
4. **刪掉暫存放大版**（所有 `_tmp2x_` 開頭節點）並回傳刪除數。🚫 不要留在使用者的檔案裡。

### 9. 收尾
- `open "$OUT"`；TSV 刪掉。
- **最後回覆固定只有這一行**：
  > **剛剛**：完稿已存：`<$OUT 絕對路徑>`
- 只有出錯（張數不對、驗尺寸失敗、暫存版沒刪乾淨）才在這行之外另外說明。

---

## 🕳️ 已知地雷（實測過）
- 正在顯示的 page 不能 `remove()` → 刪 page 前先 `setCurrentPageAsync` 到別頁。
- `get_screenshot` 不會放大 → 2x 只能靠「clone＋`rescale(2)`」暫存版。
- Figma 雲端字型清單跟你本機不同（例：沒有 `Noto Sans CJK TC`）；用 `figma.listAvailableFontsAsync()` 現查。
- 被 detach 過的舊成品 page 不能當模版，一律從模版 page 複製。
- `upload_assets` 只能上傳 < 10MB 的圖；`use_figma` 裡不能用 `createImageAsync`。
