## Claude Code

- 曖昧な点のヒアリングには AskUserQuestion ツールで選択肢を提示してください。
- 文書の判断（D1, D2 …）を AskUserQuestion で聞くときは、質問文に同じ番号を入れてください。
- 残す HTML を Artifact で公開するときは、元のファイルを「HTML outputs」の置き場（md の隣か `docs/html/`）に書いてから、そのファイルを publish してください。対になる md があれば Artifact の URL を書きます。使い捨てのページは scratchpad のままで構いません。
