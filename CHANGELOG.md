# Changelog

All notable changes to this project will be documented in this file.

---

## [2.0.0] — 2026-03-13

### Added
- **`install.sh`** — automated installer: checks deps, creates oh-my-zsh symlink, adds plugin to `.zshrc`, saves API keys to `~/.zshenv`
- **Command breakdown** — `yesika <text>` now shows each command and flag with a one-line explanation before executing
- **`yesikall` command** — full CLI assistant (renamed from `yesica`):
  - `yesikall "question"` — plain question
  - `yesikall "question" < file` — ask about file contents
  - `command | yesikall "question"` — ask about any command output
  - `command | yesikall "question" --raw` — plain text, no color
  - `yesikall --help` / `yesikall -h` — print usage reference
- **`yesika` prompt shortcut** — renamed from `#` prefix; type `yesika <text>` at prompt and press Enter to translate and execute
- **`yesika?` prompt shortcut** — renamed from `#?` prefix; ask a question inline, prints answer, nothing executed
- **`yesika` function** — direct call shows breakdown without executing; `yesika --help` shows full help

### Changed
- **Default model** changed to `minimax/minimax-m2.5` (was `deepseek/deepseek-v3.2`)
- **Plugin renamed** from `yesica-zsh.plugin.zsh` to `yesika-zsh.plugin.zsh`
- **API keys** moved from `.env` file (sourced on every shell) to `~/.zshenv` (loaded once at login) — eliminates shell startup delay
- **Context (stdin) passing** — now uses a temp file + `jq --rawfile` instead of shell variable to prevent corruption of large inputs
- **Payload delivery** — `curl` now uses `--data @file` instead of `--data "$payload"` to safely handle large JSON payloads
- **API response sanitization** — `tr` strips control characters from LLM response before `jq` parsing, fixing parse errors when LLM returns control chars in output
- **`_chat_zsh_answer`** — context parameter is now a file path, not a raw string

### Fixed
- `parse error: Invalid string: control characters from U+0000 through U+001F must be escaped` when piping log files or command output with control characters
- `parse error` caused by LLM response containing control characters
- `command not found: yesika` error — `yesika` is now a real shell function, not just a ZLE trigger
- `.env` sourcing causing ~30 second shell startup delay on some systems

---

## [1.1.0] — 2026-03-13

### Added
- **OpenRouter support** via `OPENROUTER_API_KEY` (default model: `deepseek/deepseek-v3.2`)
- **`OPENROUTER_MODEL`** env var to override the OpenRouter model
- **`yesica` command** — full CLI assistant with stdin/pipe support
- **`#?` prompt shortcut** — ask a free-form question inline, prints answer without executing
- **`yesica-zsh-help`** function — colored interactive help with full examples
- **`_chat_zsh_call`** — all JSON payloads built via `jq` for safe escaping
- **`--max-time 60`** on all `curl` calls to prevent terminal freezes
- **`.env` / `.env.example`** — API key management that survives `git pull`
- **`.gitignore`** — `.env` excluded, `.env.example` tracked
- **`CHANGELOG.md`** and **`README.md`** added to project

### Changed
- `prompt_to_command_sh` / `prompt_to_answer_sh` refactored into `_chat_zsh_translate` / `_chat_zsh_answer`
- `_chat_zsh_endpoint_and_key` uses ZSH `$reply` array
- API priority: `OPENROUTER_API_KEY` > `OPENAI_ENDPOINT` > OpenAI default
- Plugin renamed from `chat-zsh.plugin.zsh` to `yesica-zsh.plugin.zsh`

### Fixed
- Input sanitization: strip control characters and trim whitespace from ZSH buffer before passing to `jq` for both `#` and `#?` shortcuts

---

## [1.0.0] — original

### Added
- Initial plugin: `# <description>` prompt shortcut — translate natural language to shell command via OpenAI API
- `generate_command_response` using `curl` + `jq`
- `OPENAI_API_KEY`, `OPENAI_ENDPOINT`, `MODEL_NAME` env var support
