# yesica-zsh

A ZSH plugin that turns natural language into shell commands — and lets you ask questions directly from your terminal, powered by **DeepSeek V3.2 via OpenRouter** (or any OpenAI-compatible API).

---

## Features

- **`# <description>`** — translate natural language to a shell command and execute it
- **`#? <question>`** — ask a question inline, print answer, no execution
- **`yesica "<question>"`** — full CLI assistant with stdin/pipe support
- Supports **OpenRouter** (DeepSeek V3.2), **OpenAI**, or any OpenAI-compatible endpoint
- All JSON payloads built with `jq` — handles multi-line output, special characters, quotes safely

---

## Installation

**Step 1:** Clone into your oh-my-zsh custom plugins directory:

```shell
git clone https://github.com/likai-hust/chat-zsh.git \
  ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/yesica-zsh
```

**Step 2:** Add `yesica-zsh` to your plugins in `~/.zshrc`:

```zsh
plugins=(git yesica-zsh)
```

**Step 3:** Create your local credentials file (never committed):

```shell
cp ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/yesica-zsh/.env.example \
   ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/yesica-zsh/.env
```

Edit `.env` with your keys — the plugin loads it automatically on startup:

```sh
# Option A — OpenRouter (recommended, uses deepseek/deepseek-v3.2 by default)
OPENROUTER_API_KEY="sk-or-..."
# OPENROUTER_MODEL="deepseek/deepseek-v3.2"   # optional, this is the default

# Option B — OpenAI direct
# OPENAI_API_KEY="sk-..."
# MODEL_NAME="gpt-4o"

# Option C — Any OpenAI-compatible endpoint (DeepSeek, Ollama, etc.)
# OPENAI_ENDPOINT="https://api.deepseek.com/v1/chat/completions"
# OPENAI_API_KEY="your-key"
# MODEL_NAME="deepseek-chat"
```

> `.env` is in `.gitignore` — it will never be committed or overwritten by `git pull`.
> See `.env.example` for the full template.

**Step 4:** Reload:

```shell
source ~/.zshrc
```

---

## Usage

### Prompt shortcuts

Type directly at the prompt and press **Enter**:

```zsh
# find all jpg files modified in the last 7 days
# → executes: find . -name "*.jpg" -mtime -7

#? what does the sticky bit do on a directory
# → prints answer, nothing is executed
```

### `yesica` command

```zsh
yesica "what is a zombie process"
yesica "explain what awk does"

# Ask about file contents
yesica "summarize this" < README.md

# Pipe any command output
cat /var/log/syslog | yesica "summarize the errors"
docker logs myapp 2>&1 | yesica "why is this crashing?"
git diff | yesica "write a commit message for this diff"
curl -s https://api.example.com/status | yesica "is this response healthy?"

# Raw output (no color, useful for scripting)
some-command | yesica "explain this" --raw

# Help
yesica --help
yesica-zsh-help
```

---

## Dependencies

- `curl`
- `jq`

---

## Environment variable priority

| Variable | Description |
|---|---|
| `OPENROUTER_API_KEY` | OpenRouter key — highest priority |
| `OPENROUTER_MODEL` | Override OpenRouter model (default: `deepseek/deepseek-v3.2`) |
| `OPENAI_ENDPOINT` | Custom OpenAI-compatible base URL |
| `OPENAI_API_KEY` | OpenAI key |
| `MODEL_NAME` | Model override for OpenAI/custom endpoint |

---

## License

See LICENSE for more information.
