#!/usr/bin/env bash
# 役割:
# - Codex trust 設定の更新（add / rm / list）を一元管理
# - [projects."..."] の定義を重複排除して管理ブロックに集約
# - 設定全体を再構成して、trust 設定をまとまった位置で維持
# 対象設定ファイル:
# - CODEX_CONFIG_PATH があればそれを使用
# - 未指定時は ~/.codex/config.toml
set -euo pipefail

CONFIG_PATH="${CODEX_CONFIG_PATH:-$HOME/.codex/config.toml}"
ACTION="${1:-}"
INPUT_PATH="${2:-$PWD}"
LEVEL="${3:-trusted}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "config が見つかりません: $CONFIG_PATH"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

entries_file="$tmp_dir/entries.tsv"
entries_new_file="$tmp_dir/entries.new.tsv"
base_file="$tmp_dir/base.toml"
managed_file="$tmp_dir/managed.toml"
final_file="$tmp_dir/final.toml"

resolve_abs_path() {
  local p="${1:-$PWD}"
  cd "$p" 2>/dev/null && pwd -P
}

extract_entries() {
  awk '
    BEGIN {
      in_project = 0
      path = ""
      level = ""
    }
    function flush_project() {
      if (in_project == 1 && path != "" && level != "") {
        print path "\t" level
      }
      path = ""
      level = ""
      in_project = 0
    }
    {
      if (in_project == 1) {
        if ($0 ~ /^[[:space:]]*\[/) {
          flush_project()
          # 次のブロック判定のため、この行を続けて評価する
        } else {
          if ($0 ~ /^trust_level[[:space:]]*=/) {
            v = $0
            sub(/^[^=]*=[[:space:]]*/, "", v)
            gsub(/"/, "", v)
            level = v
          }
          next
        }
      }

      if ($0 ~ /^[[:space:]]*\[projects\."/) {
        in_project = 1
        path = $0
        sub(/^[[:space:]]*\[projects\."/, "", path)
        sub(/"\][[:space:]]*$/, "", path)
        level = ""
        next
      }
    }
    END {
      flush_project()
    }
  ' "$CONFIG_PATH"
}

canonicalize_entries() {
  awk -F'\t' '
    NF >= 2 && $1 != "" && $2 != "" {
      entries[$1] = $2
    }
    END {
      for (k in entries) {
        print k "\t" entries[k]
      }
    }
  ' | LC_ALL=C sort
}

extract_base_without_projects() {
  awk '
    BEGIN {
      in_managed = 0
      in_project = 0
    }
    /^# BEGIN managed-trust-projects$/ {
      in_managed = 1
      next
    }
    /^# END managed-trust-projects$/ {
      in_managed = 0
      next
    }
    in_managed == 1 {
      next
    }
    {
      if (in_project == 1) {
        if ($0 ~ /^[[:space:]]*\[/) {
          in_project = 0
          # 次のブロック判定のため、この行を続けて評価する
        } else {
          next
        }
      }

      if ($0 ~ /^[[:space:]]*\[projects\."/) {
        in_project = 1
        next
      }

      print
    }
  ' "$CONFIG_PATH"
}

toml_escape_path() {
  local p="$1"
  p="${p//\\/\\\\}"
  p="${p//\"/\\\"}"
  printf '%s' "$p"
}

render_managed_block() {
  local entries="$1"
  {
    echo "# BEGIN managed-trust-projects"
    echo "# trust add/rm で自動更新"
    if [[ ! -s "$entries" ]]; then
      echo "# (empty)"
    else
      while IFS=$'\t' read -r p lv; do
        [[ -n "$p" && -n "$lv" ]] || continue
        esc="$(toml_escape_path "$p")"
        echo "[projects.\"$esc\"]"
        echo "trust_level = \"$lv\""
        echo ""
      done < "$entries"
    fi
    echo "# END managed-trust-projects"
  } > "$managed_file"
}

insert_managed_block() {
  local base="$1"
  local managed="$2"
  local mode

  mode="$(awk '
    /^personality[[:space:]]*=/ {
      seen_personality = 1
    }
    /^# ---- 信頼済みプロジェクト ----$/ {
      seen_trust_header = 1
    }
    END {
      if (seen_personality == 1) {
        print "personality"
      } else if (seen_trust_header == 1) {
        print "trust_header"
      } else {
        print "append"
      }
    }
  ' "$base")"

  awk -v mode="$mode" -v managed_file="$managed" '
    function emit_managed( line) {
      while ((getline line < managed_file) > 0) {
        print line
      }
      close(managed_file)
    }
    {
      print
      if (inserted == 0 && mode == "personality" && $0 ~ /^personality[[:space:]]*=/) {
        print ""
        emit_managed()
        inserted = 1
      } else if (inserted == 0 && mode == "trust_header" && $0 ~ /^# ---- 信頼済みプロジェクト ----$/) {
        print ""
        emit_managed()
        inserted = 1
      }
    }
    END {
      if (inserted == 0) {
        print ""
        emit_managed()
      }
    }
  ' "$base" > "$final_file"
}

write_final_preserve_symlink() {
  # symlink 自体を置き換えないため、ファイルへ上書きする
  cat "$final_file" > "$CONFIG_PATH"
}

rewrite_config() {
  local entries="$1"
  extract_base_without_projects > "$base_file"
  render_managed_block "$entries"
  insert_managed_block "$base_file" "$managed_file"
  write_final_preserve_symlink
}

extract_entries | canonicalize_entries > "$entries_file"

case "$ACTION" in
  add)
    if [[ "$LEVEL" != "trusted" && "$LEVEL" != "untrusted" ]]; then
      echo "Usage: add [path] [trusted|untrusted]"
      exit 1
    fi
    target="$(resolve_abs_path "$INPUT_PATH" || true)"
    if [[ -z "$target" ]]; then
      echo "パスが不正です: $INPUT_PATH"
      exit 1
    fi
    {
      cat "$entries_file"
      printf '%s\t%s\n' "$target" "$LEVEL"
    } | canonicalize_entries > "$entries_new_file"
    rewrite_config "$entries_new_file"
    echo "設定しました: $target ($LEVEL)"
    echo "config: $CONFIG_PATH"
    ;;
  rm)
    target="$(resolve_abs_path "$INPUT_PATH" || true)"
    if [[ -z "$target" ]]; then
      echo "パスが不正です: $INPUT_PATH"
      exit 1
    fi
    awk -F'\t' -v target="$target" '$1 != target { print $0 }' "$entries_file" > "$entries_new_file"
    if cmp -s "$entries_file" "$entries_new_file"; then
      echo "対象が見つかりません: $target"
      exit 1
    fi
    canonicalize_entries < "$entries_new_file" > "$entries_new_file.sorted"
    rewrite_config "$entries_new_file.sorted"
    echo "削除しました: $target"
    echo "config: $CONFIG_PATH"
    ;;
  list)
    if [[ ! -s "$entries_file" ]]; then
      echo "projects.*.trust_level は未設定です。"
      exit 0
    fi
    printf "%-8s %s\n" "level" "path"
    printf "%-8s %s\n" "--------" "------------------------------"
    awk -F'\t' '{ printf "%-8s %s\n", $2, $1 }' "$entries_file"
    ;;
  *)
    cat <<'HELP'
Usage:
  codex-trust-manage.sh add [path] [trusted|untrusted]
  codex-trust-manage.sh rm [path]
  codex-trust-manage.sh list
HELP
    exit 1
    ;;
esac
