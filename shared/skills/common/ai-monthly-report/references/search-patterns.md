# 検索クエリパターン集

## 1. 企業別ニュース検索

```
# 基本パターン
"{company} announcement {month} {year}"
"{company} release {month} {year}"
"{company} news {month} {year}"

# 例（2026年1月の場合）
"OpenAI announcement January 2026"
"Anthropic release January 2026"
"Google Gemini news January 2026"
"Microsoft Copilot announcement January 2026"
```

## 2. リリースノート・Changelog検索

```
# モデル別
"{model} release notes changelog {year}"
"{product} developer changelog"

# 公式ソース（直接アクセス推奨）
- OpenAI ChatGPT: help.openai.com/en/articles/6825453-chatgpt-release-notes
- OpenAI Codex: developers.openai.com/codex/changelog/
- Anthropic Claude: support.claude.com/en/articles/12138966-release-notes
- Claude Code: github.com/anthropics/claude-code/blob/main/CHANGELOG.md
- Google Gemini API: ai.google.dev/gemini-api/docs/changelog
- Gemini CLI: geminicli.com/docs/changelogs/
```

## 3. バズ投稿検索

```
# 一般的なバイラル検索
"AI viral tweet {month} {year}"
"went viral AI tweet {year}"

# 人名 + トピック検索
"{person} tweet {topic} {year}"
```

### 主要人物リスト
| 名前 | ハンドル | 所属・役職 |
|------|----------|-----------|
| Andrej Karpathy | @karpathy | OpenAI共同創業者 |
| Sam Altman | @sama | OpenAI CEO |
| Boris Cherny | @bcherny | Claude Code開発責任者 |
| Jaana Dogan | @rakyll | Google Principal Engineer |
| Peter Steinberger | @steipete | Moltbot開発者 |
| Dario Amodei | @DarioAmodei | Anthropic CEO |
| Sundar Pichai | @sundarpichai | Google CEO |
| Satya Nadella | @satabordeaux | Microsoft CEO |

## 4. 統計・数字検索

```
"AI market share {month} {year}"
"ChatGPT users {month} {year}"
"Claude usage statistics {year}"
"Gemini market share {year}"
"AI chatbot traffic {month} {year} similarweb"
```

## 5. 来月の注目点検索

```
"AI upcoming {next_month} {year}"
"{company} roadmap {year}"
"AI events {next_month} {year}"
```

## 検索時の注意

- X（Twitter）のURLは直接取得できない（PERMISSIONS_ERROR）
- ただし検索経由でニュース記事化された情報は取得可能
- バイラルツイートは The Decoder, VentureBeat, TechCrunch 等が記事化
- 複数ソースを組み合わせると漏れが少ない
