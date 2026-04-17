#!/bin/bash
SRC=/vaults/cruxss/phases/03-hunt.md
OUT=/vaults/cruxss/phases/03-hunt
mkdir -p "$OUT"
awk -v out="$OUT" '
/^## 3[A-Z]\./ {
  if (file) close(file)
  header = $0
  gsub(/^## /, "", header)
  gsub(/[^a-zA-Z0-9]/, "-", header)
  gsub(/-+/, "-", header)
  gsub(/^-|-$/, "", header)
  file = out "/" tolower(header) ".md"
}
file { print > file }
' "$SRC"
echo "Split complete:"
ls -1 "$OUT/"
