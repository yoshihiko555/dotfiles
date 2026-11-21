#!/bin/sh
# fzf の各プレビューで、指定行数だけ表示する。
lines=$1
file=$2
[ -n "$file" ] || exit 0
case $file in
  /*) ;;
  *) file=./$file ;;
esac

if [ -d "$file" ]; then
  # 人が見る一覧。-q で改行などの制御文字も1文字に置き換える。
  # shellcheck disable=SC2012
  ls -1Apq -- "$file" | head -n "$lines"
elif [ -f "$file" ] && [ -r "$file" ]; then
  if command -v bat >/dev/null 2>&1; then
    exec bat --paging=never --color=always --style=numbers --line-range=":$lines" -- "$file"
  fi
  exec head -n "$lines" -- "$file"
fi
