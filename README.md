# yesika-zsh

A ZSH plugin that turns natural language into shell commands and lets you ask questions directly from your terminal, powered by **MiniMax M2.5 via OpenRouter** (or any OpenAI-compatible API).

---

## Features

- **`yesika <description>`** — translate natural language to a shell command, shows breakdown, executes immediately
- **`yesika? <question>`** — ask a question inline, print answer, no execution
- **`yesikall "<question>"`** — full CLI assistant with stdin/pipe support
- Command **breakdown** — each translated command shows what every flag does
- Supports **OpenRouter** (default: `minimax/minimax-m2.5`), **OpenAI**, or any OpenAI-compatible endpoint
- All JSON payloads built with `jq` and passed via temp file — handles any size, control chars, special characters safely
- API keys stored in `~/.zshenv` — loaded once at login, zero overhead on every shell

---

## Installation

### Automatic (recommended)

```shell
git clone https://github.com/youruser/yesika-zsh.git
cd yesika-zsh
bash install.sh
```

`install.sh` will:
- Check and install `jq` if missing
- Create the oh-my-zsh symlink (or add a `source` line if no oh-my-zsh)
- Add `yesika-zsh` to your `plugins=(...)` in `~/.zshrc`
- Prompt for API keys and save them to `~/.zshenv` with `chmod 600`

### Manual

**Step 1:** Clone or symlink into your oh-my-zsh custom plugins directory:

```shell
ln -s /path/to/yesika-zsh \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/yesika-zsh
```

**Step 2:** Add `yesika-zsh` to your plugins in `~/.zshrc`:

```zsh
plugins=(git yesika-zsh)
```

**Step 3:** Add your API key to `~/.zshenv` (loaded once at login):

```sh
# Option A — OpenRouter (recommended, default model: minimax/minimax-m2.5)
export OPENROUTER_API_KEY="sk-or-..."
# export OPENROUTER_MODEL="minimax/minimax-m2.5"   # optional override

# Option B — OpenAI direct
# export OPENAI_API_KEY="sk-..."
# export MODEL_NAME="gpt-4o"

# Option C — Any OpenAI-compatible endpoint (Ollama, DeepSeek, etc.)
# export OPENAI_ENDPOINT="https://api.deepseek.com/v1/chat/completions"
# export OPENAI_API_KEY="your-key"
# export MODEL_NAME="deepseek-chat"
```

**Step 4:** Reload:

```shell
source ~/.zshrc
```

---

## Usage

### Prompt shortcuts — type at the prompt and press Enter

```zsh
yesika list all running docker containers
# Shows breakdown then executes:
#   docker ps
#   docker: container management CLI
#   ps:     list running containers

yesika? what does the sticky bit do on a directory
# Prints answer. Nothing is executed.
```

### `yesikall` command

```zsh
yesikall "what is a zombie process"
yesikall "explain what awk does"

# Ask about file contents
yesikall "summarize this" < /etc/nginx/nginx.conf

# Pipe any command output
tail -100 /var/log/syslog | yesikall "summarize the errors"
docker logs myapp 2>&1 | yesikall "why is this crashing?"
git diff | yesikall "write a commit message for this diff"
curl -s https://api.example.com/status | yesikall "is this response healthy?"

# Raw output (no color, useful for scripting)
some-command | yesikall "explain this" --raw

# Help
yesikall --help
yesika-zsh-help
```

### Quick reference

| Input | Action |
|---|---|
| `yesika <text>` [Enter] | Translate to command, show breakdown, execute |
| `yesika? <text>` [Enter] | Ask question, print answer, no execution |
| `yesikall "<q>"` | Ask question, print answer |
| `yesikall "<q>" < file` | Ask about file contents |
| `cmd \| yesikall "<q>"` | Ask about command output |
| `cmd \| yesikall "<q>" --raw` | Same, plain text output |

---

## Dependencies

- `zsh`
- `curl`
- `jq` (auto-installed by `install.sh` if missing)

---

## Environment variables

| Variable | Description |
|---|---|
| `OPENROUTER_API_KEY` | OpenRouter key — highest priority |
| `OPENROUTER_MODEL` | Override OpenRouter model (default: `minimax/minimax-m2.5`) |
| `OPENAI_ENDPOINT` | Custom OpenAI-compatible base URL |
| `OPENAI_API_KEY` | OpenAI key |
| `MODEL_NAME` | Model override for OpenAI/custom endpoint |

Keys are stored in `~/.zshenv` — never committed, loaded once at login with zero shell startup overhead.

---

## License

See LICENSE for more information.
