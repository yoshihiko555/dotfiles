# ============================================
# General Functions
# ============================================

# lazygit は起動時だけ ~/.config を設定ディレクトリとして使う
lazygit() {
  XDG_CONFIG_HOME="$HOME/.config" command lazygit "$@"
}

# カスタムコマンド一覧を表示
cheat() {
  cat <<'HELP'
── General ─────────────────────────────────
  ll        ls -lah
  la        ls -A
  ..        cd ..  /  ...  cd ../..  /  ....  cd ../../..
  mkdir     mkdir -p (自動で親ディレクトリ作成)
  rm/cp/mv  確認付き (-i)

── Git ─────────────────────────────────────
  g         git
  gs        git status       ga   git add
  gc        git commit       gp   git push
  gl        git log (10件)   gd   git diff
  gb        git branch       gco  git checkout
  gsw       git switch       lg   lazygit
  wt        gtr の薄いラッパー
            `wt rm` は fzf 選択で削除可

── Docker ──────────────────────────────────
  d         docker           dc   docker compose
  dps       docker ps        dpsa docker ps -a
  conin     docker container exec -it

── Dev ─────────────────────────────────────
  v         nvim             vd   nvim-dev
  c         clear            h    history
  t         tmux             code code .
  zed       zed .
  cc        claude           ccp    claude (個人)
  ccw       会社Claude      cc-dg  権限スキップ
  cc-r      claude resume    cx     codex
  gm        gemini
  wails     Wails v2         wails3 Wails v3
  orche     ai-orchestra manager

── Digital Garden ──────────────────────────
  trend     今日のトレンドメモを開く
  daily     daily ノート一覧
  weekly    weekly クリッピング一覧

── Tmux ────────────────────────────────────
  t         tmux               ta   attach
  tl        list-sessions      td   detach
  tn        new-session
  tss       fzf でセッション切り替え
  tk        fzf でセッション kill
  tp        ghq プロジェクトでセッション作成
  -s NAME   セッション名を付けて作成  (tn -s work)
  -t NAME   対象セッションを指定      (ta -t work)

── Functions (fzf) ─────────────────────────
  repo      ghq リポジトリに移動
  fe        ファイル検索 → nvim で開く
  fh        コマンド履歴検索
  fb        git ブランチ切り替え
  fkill     プロセスを選んで kill
  dex       docker コンテナに入る
  dcf       compose ファイルを選んで docker compose 実行
  mdopen    Markdown を選んで Dia で開く

── Functions (util) ────────────────────────
  mkcd DIR  ディレクトリ作成して cd
  port NUM  ポート使用プロセス確認
  brewup    brew 管理ツールを一括更新 (-a で :latest cask も)
  cc_interrupt ... 中断証跡 (start|end|open|last|report)
  trust ... Codex trust を add/rm/list/audit/where
  cheat     このヘルプを表示
HELP
}

# fzf でMarkdownを選んでブラウザで開く
mdopen() {
  local dir="${1:-.}"
  dir="${dir%/}"
  local file target rc

  if [[ ! -d "$dir" ]]; then
    echo "ディレクトリが見つかりません: $dir"
    return 1
  fi

  file=$(cd "$dir" && find . -name "*.md" -type f | sed 's|^\./||' | sort -r \
    | fzf --preview 'head -40 -- {}')
  rc=$?
  [[ $rc -ne 0 ]] && return "$rc"
  [[ -z "$file" ]] && return 0

  target="$dir/$file"
  if command -v open >/dev/null 2>&1; then
    if open -Ra "Dia" >/dev/null 2>&1; then
      open -a "Dia" "$target"
    else
      open "$target"
    fi
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$target" >/dev/null 2>&1
  else
    echo "open/xdg-open が見つかりません: $target"
    return 1
  fi
}

# ディレクトリ作成してcd
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ポート使用プロセス確認
port() {
  if [[ -z "$1" ]]; then
    echo "Usage: port <port_number>"
    echo "Example: port 3000"
    return 1
  fi
  lsof -i :"$1"
}

# fzf + コマンド履歴検索
fh() {
  local selected
  selected=$(history -n 1 | fzf --tac --no-sort)
  [[ -n "$selected" ]] && print -z "$selected"
}

# fzf + git ブランチ切り替え
fb() {
  local branch
  branch=$(git branch -a | sed 's/^..//' | sed 's|remotes/origin/||' | sort -u | fzf)
  [[ -n "$branch" ]] && git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

# fzf + プロセスキル
fkill() {
  local pid
  pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# fzf + ファイル検索して nvim で開く
fe() {
  local file
  file=$(find . -type f 2>/dev/null | fzf --preview 'head -100 -- {}')
  [[ -n "$file" ]] && nvim "$file"
}

hermes-ui() {
  (sleep 2 && open "http://localhost:13000") &
  ssh -t macmini-hermes "/Users/agent/.local/bin/hermes dashboard"
}

# brew 管理ツールを一括更新（最新でないものだけ upgrade）
#   claude-code / codex / gemini-cli などの CLI agent を含む全 formula/cask が対象。
#   :latest cask（wezterm@nightly 等、brew がバージョン比較できず毎回再取得になるもの）は
#   既定で除外し、`brewup -a` を付けたときだけ再取得する。
brewup() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "brew が見つかりません"
    return 1
  fi

  local include_latest=0
  [[ "$1" == "-a" || "$1" == "--all" ]] && include_latest=1

  echo "🔄 brew update ..."
  brew update -q || { echo "brew update に失敗しました"; return 1; }

  # 更新対象（formula + 通常 cask + auto_updates cask）。:latest cask はここには出ない
  local outdated
  outdated=$(brew outdated --quiet --greedy-auto-updates 2>/dev/null)
  if [[ -n "$outdated" ]]; then
    echo "⬆️  更新対象:"
    echo "$outdated" | sed 's/^/   /'
    brew upgrade --greedy-auto-updates || return 1
  else
    echo "✅ 最新でないツールはありません"
  fi

  # version :latest の cask（brew がバージョン比較不可＝常に再取得）
  local latest_casks
  latest_casks=$(brew list --cask --versions 2>/dev/null | awk '$2=="latest"{print $1}')
  if [[ -n "$latest_casks" ]]; then
    if (( include_latest )); then
      echo "♻️  :latest cask を再取得: ${latest_casks//$'\n'/ }"
      echo "$latest_casks" | xargs brew upgrade --cask --greedy-latest
    else
      echo "ℹ️  :latest cask（毎回再取得・既定スキップ）: ${latest_casks//$'\n'/ }"
      echo "    更新するには: brewup -a"
    fi
  fi

  echo "🧹 brew cleanup ..."
  brew cleanup -q

  # 主要 CLI agent の現在バージョン
  echo "—— CLI agent ——"
  command -v claude >/dev/null 2>&1 && printf "  claude  %s\n" "$(claude --version 2>/dev/null)"
  command -v codex  >/dev/null 2>&1 && printf "  codex   %s\n" "$(codex --version 2>/dev/null)"
  command -v gemini >/dev/null 2>&1 && printf "  gemini  %s\n" "$(gemini --version 2>/dev/null)"
}
