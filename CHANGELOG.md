# Changelog

All notable changes to this project will be documented in this file.

---

## [Unreleased] — 2026-03-13

### Added
- **OpenRouter support** via `OPENROUTER_API_KEY` (default model: `deepseek/deepseek-v3.2`)
- **`OPENROUTER_MODEL`** env var to override the OpenRouter model
- **`yesica` command** — full CLI assistant with stdin/pipe support:
  - `yesica "question"` — plain question
  - `yesica "question" < file` — ask about file contents
  - `command | yesica "question"` — ask about any command output (any size)
  - `yesica "question" --raw` — plain text output, no color
  - `yesica --help` / `yesica -h` — print usage reference
- **`#?` prompt shortcut** — ask a free-form question inline, prints answer without executing
- **`chat-zsh-help`** function — colored interactive help
- **`_chat_zsh_call`** internal function — all JSON payloads built via `jq` for safe escaping of multi-line content, special characters, and quotes
- **`--max-time 60`** on all `curl` calls to prevent terminal freezes on slow/dead APIs
- **Error reporting** in API responses: surfaces `.error.message` if the call fails

### Changed
- `prompt_to_command_sh` and `prompt_to_answer_sh` refactored into `_chat_zsh_translate` and `_chat_zsh_answer`
- `_chat_zsh_endpoint_and_key` now uses the `$reply` array (ZSH idiom) instead of echoing space-separated values
- API endpoint priority: `OPENROUTER_API_KEY` > `OPENAI_ENDPOINT` > OpenAI default
- Full header block added to plugin file with usage reference

---

## [1.0.0] — original

### Added
- Initial plugin: `# <description>` prompt shortcut to translate natural language to shell command via OpenAI API
- `generate_command_response` using `curl` + `jq`
- `OPENAI_API_KEY`, `OPENAI_ENDPOINT`, `MODEL_NAME` env var support
