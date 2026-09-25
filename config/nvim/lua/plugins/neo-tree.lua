-- 既定マッピングに desc を付けて ? のヘルプを日本語化する
-- desc 以外（config / nowait）は既定値と deep merge されるので書かない

-- filesystem / buffers / git_status に共通するキー
local function source_mappings(extra)
  return vim.tbl_extend("force", {
    ["i"] = { "show_file_details", desc = "ファイル詳細を表示" },
    ["b"] = { "rename_basename", desc = "拡張子を残して名前を変更" },
    ["o"] = { "show_help", desc = "並び替えメニュー", config = { title = "並び替え" } },
    ["oc"] = { "order_by_created", desc = "作成日時で並び替え" },
    ["od"] = { "order_by_diagnostics", desc = "診断で並び替え" },
    ["om"] = { "order_by_modified", desc = "更新日時で並び替え" },
    ["on"] = { "order_by_name", desc = "名前で並び替え" },
    ["os"] = { "order_by_size", desc = "サイズで並び替え" },
    ["ot"] = { "order_by_type", desc = "種類で並び替え" },
  }, extra)
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = { "Neotree" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "ファイル一覧を開閉" },
    { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "現在のファイルを表示" },
  },
  init = function()
    vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
      pattern = "*",
      callback = function()
        local manager = package.loaded["neo-tree.sources.manager"]
        if not manager then
          return
        end

        local state = manager.get_state("filesystem")
        local renderer = require("neo-tree.ui.renderer")
        if state and state.tree and renderer.window_exists(state) then
          require("neo-tree.sources.filesystem.commands").refresh(state)
        end
      end,
    })
  end,
  opts = {
    default_component_configs = {
      -- ウィンドウ幅 35 でもサイズ列を表示する（既定は required_width = 64）
      file_size = {
        enabled = true,
        width = 8,
        required_width = 30,
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      window = {
        mappings = source_mappings({
          ["d"] = { "delete", desc = "削除" },
          ["A"] = { "add_directory", desc = "ディレクトリを作成" },
          ["H"] = { "toggle_hidden", desc = "隠しファイルの表示を切り替え" },
          ["/"] = { "fuzzy_finder", desc = "あいまい検索" },
          ["D"] = { "fuzzy_finder_directory", desc = "ディレクトリをあいまい検索" },
          ["#"] = { "fuzzy_sorter", desc = "あいまい検索で並び替え" },
          ["f"] = { "filter_on_submit", desc = "フィルタ（Enter で適用）" },
          ["<C-x>"] = { "clear_filter", desc = "フィルタを解除" },
          ["<bs>"] = { "navigate_up", desc = "親ディレクトリへ移動" },
          ["."] = { "set_root", desc = "ルートに設定" },
          ["[g"] = { "prev_git_modified", desc = "前の Git 変更へ" },
          ["]g"] = { "next_git_modified", desc = "次の Git 変更へ" },
          ["og"] = { "order_by_git_status", desc = "Git 状態で並び替え" },
        }),
      },
    },
    buffers = {
      window = {
        mappings = source_mappings({
          ["d"] = { "buffer_delete", desc = "バッファを削除" },
          ["bd"] = { "buffer_delete", desc = "バッファを削除" },
          ["A"] = { "add_directory", desc = "ディレクトリを作成" },
          ["<bs>"] = { "navigate_up", desc = "親ディレクトリへ移動" },
          ["."] = { "set_root", desc = "ルートに設定" },
        }),
      },
    },
    git_status = {
      window = {
        position = "float",
        mappings = source_mappings({
          ["d"] = { "delete", desc = "削除" },
          ["A"] = { "git_add_all", desc = "すべてステージ" },
          ["gu"] = { "git_unstage_file", desc = "アンステージ" },
          ["gU"] = { "git_undo_last_commit", desc = "直前のコミットを取り消し" },
          ["ga"] = { "git_add_file", desc = "ステージ" },
          ["gt"] = { "git_toggle_file_stage", desc = "ステージを切り替え" },
          ["gr"] = { "git_revert_file", desc = "変更を破棄" },
          ["gc"] = { "git_commit", desc = "コミット" },
          ["gp"] = { "git_push", desc = "プッシュ" },
          ["gl"] = { "git_pull", desc = "プル" },
          ["gg"] = { "git_commit_and_push", desc = "コミットしてプッシュ" },
        }),
      },
    },
    window = {
      width = 35,
      -- d / A はソースごとに割り当てが違うため各ソース側で定義する
      -- （ここに置くと buffers / git_status の既定を上書きしてしまう）
      mappings = {
        ["<C-s>"] = { "quick_jump", desc = "ラベルでジャンプ" },
        ["<Tab>"] = { "select", desc = "選択を切り替え" },
        ["<C-S-i>"] = { "invert_selection", desc = "選択を反転" },
        ["<C-;>"] = { "clear_selection", desc = "選択を解除" },
        ["<2-LeftMouse>"] = { "open", desc = "開く" },
        ["<cr>"] = { "open", desc = "開く" },
        ["<esc>"] = { "cancel", desc = "プレビュー/フロートを閉じる" },
        ["P"] = { "toggle_preview", desc = "プレビューを切り替え" },
        ["<C-f>"] = { "scroll_preview", desc = "プレビューを下へスクロール" },
        ["<C-b>"] = { "scroll_preview", desc = "プレビューを上へスクロール" },
        ["l"] = { "focus_preview", desc = "プレビューへ移動" },
        ["S"] = { "open_split", desc = "水平分割で開く" },
        ["s"] = { "open_vsplit", desc = "垂直分割で開く" },
        ["t"] = { "open_tabnew", desc = "新しいタブで開く" },
        ["w"] = { "open_with_window_picker", desc = "ウィンドウを選んで開く" },
        ["C"] = { "close_node", desc = "ノードを閉じる" },
        ["z"] = { "close_all_nodes", desc = "すべてのノードを閉じる" },
        ["R"] = { "refresh", desc = "再読み込み" },
        ["a"] = { "add", desc = "作成（末尾 / でディレクトリ）" },
        ["T"] = { "trash", desc = "ゴミ箱へ移動" },
        ["u"] = { "undo", desc = "元に戻す" },
        ["U"] = { "restore_from_trash", desc = "ゴミ箱から復元" },
        ["r"] = { "rename", desc = "名前を変更" },
        ["y"] = { "copy_to_clipboard", desc = "コピー対象にする" },
        ["x"] = { "cut_to_clipboard", desc = "切り取り対象にする" },
        ["p"] = { "paste_from_clipboard", desc = "貼り付け" },
        ["<C-r>"] = { "clear_clipboard", desc = "コピー/切り取りを解除" },
        ["c"] = { "copy", desc = "コピー（コピー先を入力）" },
        ["m"] = { "move", desc = "移動（移動先を入力）" },
        ["e"] = { "toggle_auto_expand_width", desc = "幅の自動拡張を切り替え" },
        ["q"] = { "close_window", desc = "ウィンドウを閉じる" },
        ["?"] = { "show_help", desc = "ヘルプを表示" },
        ["<"] = { "prev_source", desc = "前のソースへ" },
        [">"] = { "next_source", desc = "次のソースへ" },
        ["<space>"] = "none",
        ["Y"] = {
          function(state)
            local node = state.tree:get_node()
            if not node or (node.type ~= "file" and node.type ~= "directory") then
              return
            end
            local path = vim.fn.fnamemodify(node.path, ":p")
            vim.fn.setreg("+", path)
            vim.notify("絶対パスをコピーしました: " .. path)
          end,
          desc = "絶対パスをクリップボードにコピー",
        },
      },
    },
  },
}
