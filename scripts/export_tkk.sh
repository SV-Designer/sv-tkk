#!/bin/bash
# sv-tkk 輸出：下載 Figma 截圖 PNG → 轉 JPEG(q100) → 依檔名尺寸驗像素
# 用法：export_tkk.sh <輸出資料夾> <對照表.tsv>
#   TSV 每行：image_url<TAB>frame名<TAB>1|2
#   1 → <輸出資料夾>/<frame名>.jpg；2 → <輸出資料夾>/2x/<frame名>.jpg
#   frame 名須含 <寬>x<高>（例 PC_728x90），用來驗尺寸（2x 則乘 2）
# 退出碼：0＝全部合格；1＝參數錯；2＝有檔案下載／轉檔／尺寸不合格（不合格檔會被刪掉）
set -u
OUT="${1:-}"; TSV="${2:-}"
[ -n "$OUT" ] && [ -f "$TSV" ] || { echo "用法：$0 <輸出資料夾> <對照表.tsv>"; exit 1; }
mkdir -p "$OUT/2x" || exit 1
TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT
ok=0; bad=0
while IFS=$'\t' read -r url name scale || [ -n "${url:-}" ]; do
  [ -z "${url:-}" ] && continue
  name=$(printf '%s' "$name" | sed 's/[[:space:]]*$//')
  scale=$(printf '%s' "$scale" | tr -d '[:space:]')
  case "$scale" in 1) dest="$OUT/$name.jpg";; 2) dest="$OUT/2x/$name.jpg";; *) echo "[!] $name：倍率欄要是 1 或 2（拿到 '$scale'）"; bad=$((bad+1)); continue;; esac
  if ! curl -sfL -o "$TMP/s.png" "$url"; then echo "[!] $name@${scale}x 下載失敗（網址可能過期，重取 get_screenshot）"; bad=$((bad+1)); continue; fi
  if ! sips -s format jpeg -s formatOptions 100 "$TMP/s.png" --out "$dest" >/dev/null 2>&1; then echo "[!] $name@${scale}x 轉 JPEG 失敗"; bad=$((bad+1)); continue; fi
  if [[ "$name" =~ ([0-9]+)x([0-9]+) ]]; then
    ew=$(( BASH_REMATCH[1] * scale )); eh=$(( BASH_REMATCH[2] * scale ))
    w=$(sips -g pixelWidth "$dest" | awk '/pixelWidth/{print $2}'); h=$(sips -g pixelHeight "$dest" | awk '/pixelHeight/{print $2}')
    if [ "$w" != "$ew" ] || [ "$h" != "$eh" ]; then echo "[!] $name@${scale}x 尺寸 ${w}x${h}，應為 ${ew}x${eh} → 已刪除，請重匯"; rm -f "$dest"; bad=$((bad+1)); continue; fi
  else
    echo "[?] $name 檔名沒有 寬x高，略過尺寸驗證"
  fi
  echo "✓ ${dest#$OUT/}"; ok=$((ok+1))
done < "$TSV"
echo "完成：合格 $ok 張，不合格 $bad 張 → $OUT"
[ "$bad" -eq 0 ] || exit 2
