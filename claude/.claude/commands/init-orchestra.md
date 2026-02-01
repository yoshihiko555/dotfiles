このプロジェクトでオーケストラを有効化してください。

以下の手順を実行してください：

1. `.claude/settings.json` が存在するか確認
2. 存在しない場合は新規作成、存在する場合はhooks設定をマージ
3. UserPromptSubmitのhookに以下を追加：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$HOME/.claude/hooks/agent-router.py\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

4. 完了したら、設定内容を表示して確認
