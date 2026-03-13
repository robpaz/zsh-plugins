# =============================================================================
# yesika-zsh.plugin.zsh - Natural language shell assistant
# =============================================================================
#
# -- PROMPT SHORTCUTS ---------------------------------------------------------
#
#   yesika <description>
#       Translates natural language to a shell command and EXECUTES it
#       immediately (single Enter press).
#       Example:  yesika listar archivos ocultos
#       Result:   runs: ls -la
#
#   yesika? <question>
#       Asks the LLM a free-form question. Prints the answer on screen.
#       Does NOT execute anything. Prompt is restored after.
#       Example:  yesika? que hace el comando chmod 777
#       Result:   prints explanation, no command runs
#
# -- yesikall COMMAND -----------------------------------------------------------
#
#   yesikall "<question>"
#       Ask a plain question, prints answer.
#       Example:  yesikall "what is a zombie process"
#
#   yesikall "<question>" < file
#       Ask about the contents of a file.
#       Example:  yesikall "summarize this" < /etc/nginx/nginx.conf
#
#   <cmd> | yesikall "<question>"
#       Pipe ANY command output (large or small) and ask about it.
#       Example:  docker logs myapp 2>&1 | yesikall "why is this crashing?"
#       Example:  cat /var/log/syslog | yesikall "summarize the errors"
#       Example:  git diff | yesikall "write a commit message for this diff"
#       Example:  curl -s https://api/status | yesikall "is this response ok?"
#
#   <cmd> | yesikall "<question>" --raw
#       Same as above but output has no color (useful for scripting/pipes).
#       Example:  journalctl -n 50 | yesikall "any critical errors?" --raw
#
#   yesikall --help / yesikall -h
#       Print this usage reference.
#
# -- SUMMARY TABLE ------------------------------------------------------------
#
#   Input                        Action
#   --------------------------   ------------------------------------------
#   yesika <text>        [Enter]      Translate to command → execute immediately
#   yesika? <text>       [Enter]      Ask question → print answer, no execution
#   yesikall "<q>"                 Ask question → print answer
#   yesikall "<q>" < file          Ask about file contents → print answer
#   cmd | yesikall "<q>"           Ask about cmd output → print answer
#   cmd | yesikall "<q>" --raw     Same, plain text (no color)
#
# -- ENVIRONMENT VARIABLES ----------------------------------------------------
#
#   OPENROUTER_API_KEY   Use OpenRouter (default model: deepseek/deepseek-v3.2)
#   OPENROUTER_MODEL     Override OpenRouter model (optional)
#   OPENAI_API_KEY       Use OpenAI directly
#   OPENAI_ENDPOINT      Override OpenAI-compatible endpoint URL (optional)
#   MODEL_NAME           Override model name for OpenAI/custom endpoint (optional)
#
#   Priority: OPENROUTER_API_KEY > OPENAI_ENDPOINT > OpenAI default
#
# HELP:
#   yesika-zsh-help      Print this usage reference
#   yesikall --help      Same as yesika-zsh-help
# =============================================================================


function yesika-zsh-help() {
  print -P "%F{yellow}yesika-zsh - Natural language shell assistant%f"
  print ""
  print -P "%F{green}PROMPT SHORTCUTS%f (type at prompt and press Enter):"
  print ""
  print -P "  %F{cyan}yesika <description>%f   [Enter]"
  print -P "      Translate natural language to a shell command and %F{red}execute immediately%f."
  print -P "      Example:  %F{white}yesika listar archivos ocultos%f"
  print -P "      Result:   runs %F{white}ls -la%f"
  print ""
  print -P "  %F{cyan}yesika? <question>%f   [Enter]"
  print -P "      Ask the LLM a question. Prints answer. %F{red}Nothing is executed%f."
  print -P "      Example:  %F{white}yesika? que hace el comando chmod 777%f"
  print -P "      Result:   prints explanation, prompt is restored"
  print ""
  print -P "%F{green}yesikall COMMAND%f:"
  print ""
  print -P "  %F{cyan}yesikall \"<question>\"%f"
  print -P "      Plain question → prints answer."
  print -P "      Example:  %F{white}yesikall \"what is a zombie process\"%f"
  print ""
  print -P "  %F{cyan}yesikall \"<question>\" < file%f"
  print -P "      Ask about file contents → prints answer."
  print -P "      Example:  %F{white}yesikall \"summarize this\" < /etc/nginx/nginx.conf%f"
  print ""
  print -P "  %F{cyan}<cmd> | yesikall \"<question>\"%f"
  print -P "      Pipe any command output and ask about it (any size)."
  print -P "      Example:  %F{white}docker logs myapp 2>&1 | yesikall \"why is this crashing?\"%f"
  print -P "      Example:  %F{white}cat /var/log/syslog | yesikall \"summarize the errors\"%f"
  print -P "      Example:  %F{white}git diff | yesikall \"write a commit message for this diff\"%f"
  print ""
  print -P "  %F{cyan}<cmd> | yesikall \"<question>\" --raw%f"
  print -P "      Same but plain text output (no color, useful for scripting)."
  print -P "      Example:  %F{white}journalctl -n 50 | yesikall \"any critical errors?\" --raw%f"
  print ""
  print -P "%F{green}SUMMARY%f:"
  print -P "  %F{white}yesika <text>%f         [Enter]   → translate to command, execute immediately"
  print -P "  %F{white}yesika? <text>%f        [Enter]   → ask question, print answer, no execution"
  print -P "  %F{white}yesikall \"<q>\"%f              → ask question, print answer"
  print -P "  %F{white}yesikall \"<q>\" < file%f       → ask about file, print answer"
  print -P "  %F{white}cmd | yesikall \"<q>\"%f        → ask about output, print answer"
  print -P "  %F{white}cmd | yesikall \"<q>\" --raw%f  → same, plain text"
  print ""
  print -P "%F{green}ENV VARS%f:"
  print -P "  OPENROUTER_API_KEY   sk-or-...   (uses minimax/minimax-m2.5 by default)"
  print -P "  OPENROUTER_MODEL     override OpenRouter model"
  print -P "  OPENAI_API_KEY       sk-...      (direct OpenAI)"
  print -P "  OPENAI_ENDPOINT      custom OpenAI-compatible base URL"
  print -P "  MODEL_NAME           override model for OpenAI/custom endpoint"
}

# -----------------------------------------------------------------------------
# Internal: resolve endpoint, api_key, model into $reply array
# -----------------------------------------------------------------------------
function _chat_zsh_endpoint_and_key() {
  if [[ -n $OPENROUTER_API_KEY ]]; then
    reply=("https://openrouter.ai/api/v1/chat/completions" "$OPENROUTER_API_KEY" "${OPENROUTER_MODEL:-minimax/minimax-m2.5}")
  elif [[ -n $OPENAI_ENDPOINT ]]; then
    reply=("$OPENAI_ENDPOINT" "$OPENAI_API_KEY" "${MODEL_NAME:-gpt-4o}")
  else
    reply=("https://api.openai.com/v1/chat/completions" "$OPENAI_API_KEY" "${MODEL_NAME:-gpt-4o}")
  fi
}

# -----------------------------------------------------------------------------
# Internal: send messages array (JSON string) to LLM, return content
# $1 = messages JSON array (already valid JSON)
# $2 = endpoint, $3 = api_key, $4 = model, $5 = temperature
# -----------------------------------------------------------------------------
function _chat_zsh_call() {
  local messages="$1" endpoint="$2" api_key="$3" model="$4" temperature="${5:-0}"
  local payload response

  local _payload_file
  _payload_file=$(mktemp)

  jq -n \
    --arg model "$model" \
    --argjson temp "$temperature" \
    --argjson messages "$messages" \
    '{"model": $model, "messages": $messages, "temperature": $temp, "stream": false}' \
    > "$_payload_file"

  response=$(curl -s --max-time 60 "$endpoint" \
    --header "Authorization: Bearer $api_key" \
    --header "Content-Type: application/json" \
    --data "@$_payload_file")

  rm -f "$_payload_file"

  printf '%s' "$response" | tr -d '\000-\010\013\014\016-\037' | jq -r '.choices[0].message.content // "Error: \(.error.message // "unknown error")"'
}

# -----------------------------------------------------------------------------
# Internal: translate natural language to shell command
# -----------------------------------------------------------------------------
function _chat_zsh_translate() {
  local desc="${1//[$'\t\r\n']/ }"
  desc="${desc## }"
  desc="${desc%% }"
  local messages

  messages=$(jq -n \
    --arg desc "$desc" \
    '[
      {"role":"system","content":"You are a senior engineer expert in shell commands. Translate the user natural language input into a shell command. Respond ONLY in this exact format (no markdown, no extra text):\nCMD: <the full executable command>\nBREAKDOWN:\n<command_or_flag>: <one-line explanation>\n<command_or_flag>: <one-line explanation>\n...\nRules: 1. CMD line must contain only the executable command. 2. For multi-line commands use && to connect. 3. For dangerous commands prefix CMD with DANGEROUS. 4. BREAKDOWN must list each command and each flag separately with a colon and short explanation."},
      {"role":"user","content":"mac install node js"},
      {"role":"assistant","content":"CMD: brew install node\nBREAKDOWN:\nbrew: macOS package manager\ninstall: install a package\nnode: Node.js runtime"},
      {"role":"user","content":"delete all files and folders"},
      {"role":"assistant","content":"CMD: DANGEROUS rm -rf *\nBREAKDOWN:\nrm: remove files or directories\n-r: recursive (all subdirectories)\n-f: force (no confirmation)\n*: all files in current directory"},
      {"role":"user","content":"list directory"},
      {"role":"assistant","content":"CMD: ls -la\nBREAKDOWN:\nls: list directory contents\n-l: long format showing permissions, size, and date\n-a: include hidden files (starting with .)"},
      {"role":"user","content":$desc}
    ]')

  _chat_zsh_endpoint_and_key
  _chat_zsh_call "$messages" "${reply[1]}" "${reply[2]}" "${reply[3]}" 0
}

# -----------------------------------------------------------------------------
# Internal: answer a free-form question, optionally with context
# $1 = question, $2 = context (optional, can be multi-line)
# -----------------------------------------------------------------------------
function _chat_zsh_answer() {
  local question="${1//[$'\t\r\n']/ }"
  question="${question## }"
  question="${question%% }"
  local ctx_file="$2"
  local messages

  if [[ -n $ctx_file && -f $ctx_file ]]; then
    messages=$(jq -n \
      --rawfile ctx "$ctx_file" \
      --arg q "$question" \
      '[
        {"role":"system","content":"You are a helpful assistant. Answer the user'\''s question concisely and clearly based on the provided context."},
        {"role":"user","content":("Context:\n" + $ctx + "\n\nQuestion: " + $q)}
      ]')
  else
    messages=$(jq -n \
      --arg q "$question" \
      '[
        {"role":"system","content":"You are a helpful assistant. Answer the user'\''s question concisely and clearly."},
        {"role":"user","content":$q}
      ]')
  fi

  _chat_zsh_endpoint_and_key
  _chat_zsh_call "$messages" "${reply[1]}" "${reply[2]}" "${reply[3]}" 0.3
}

# -----------------------------------------------------------------------------
# Public: yesikall - question with optional stdin context
# Usage:
#   yesikall "question"
#   yesikall "question" < file
#   command | yesikall "question"
#   command | yesikall "question" --raw
# -----------------------------------------------------------------------------
function yesikall() {
  local question="" raw=0 context=""

  if [[ $1 == "--help" || $1 == "-h" ]]; then
    yesika-zsh-help
    return 0
  fi

  for arg in "$@"; do
    if [[ $arg == "--raw" ]]; then
      raw=1
    else
      question="$arg"
    fi
  done

  if [[ -z $question ]]; then
    print -P "%F{red}Usage: yesikall \"your question\" [< file | pipe] [--raw]%f" >&2
    return 1
  fi

  local _ctx_file
  if [[ ! -t 0 ]]; then
    _ctx_file=$(mktemp)
    cat | tr -d '\000-\010\013\014\016-\037' > "$_ctx_file"
  fi

  local answer
  answer=$(_chat_zsh_answer "$question" "$_ctx_file")

  if (( raw )); then
    echo "$answer"
  else
    print -P "%F{cyan}${answer}%f"
  fi
  [[ -n $_ctx_file && -f $_ctx_file ]] && rm -f "$_ctx_file"
}

# -----------------------------------------------------------------------------
# Public: yesika - prompt shortcut stub (real magic happens via ZLE widget)
# When called as a command directly, shows usage hint.
# -----------------------------------------------------------------------------
function yesika() {
  if [[ $# -eq 0 || $1 == "--help" || $1 == "-h" ]]; then
    yesika-zsh-help
    return 0
  fi
  local raw_response cmd_line breakdown
  raw_response=$(_chat_zsh_translate "$*")
  cmd_line=$(printf '%s' "$raw_response" | grep '^CMD:' | head -1 | sed 's/^CMD: *//')
  breakdown=$(printf '%s' "$raw_response" | awk '/^BREAKDOWN:/{found=1; next} found{print}')
  [[ -z $cmd_line ]] && cmd_line="$raw_response"
  print -P "%F{yellow}${cmd_line}%f"
  [[ -n $breakdown ]] && print -P "%F{240}${breakdown}%f"
}

# -----------------------------------------------------------------------------
# ZLE widget: intercept Enter key for # and #? prefixes
# -----------------------------------------------------------------------------
function zsh_line_finish() {
  local buffer=$BUFFER
  local first_seven="${buffer:0:7}"
  

  if [[ -n $buffer && $first_seven == 'yesika?' ]]; then
    local question="${buffer:7}"
    question="${question//[$'\t\r\n']/ }"
    question="${question## }"
    question="${question%% }"
    zle -I
    print
    print -P "%F{cyan}$(_chat_zsh_answer "$question")%f"
    zle reset-prompt
  elif [[ -n $buffer && $buffer[1,7] == 'yesika ' ]]; then
    local remaining="${buffer:7}"
    remaining="${remaining//[$'\t\r\n']/ }"
    remaining="${remaining## }"
    remaining="${remaining%% }"
    local raw_response cmd_line breakdown
    raw_response=$(_chat_zsh_translate "$remaining")
    cmd_line=$(printf '%s' "$raw_response" | grep '^CMD:' | head -1 | sed 's/^CMD: *//')
    breakdown=$(printf '%s' "$raw_response" | awk '/^BREAKDOWN:/{found=1; next} found{print}')
    if [[ -z $cmd_line ]]; then
      cmd_line="$raw_response"
    fi
    zle -I
    print
    [[ -n $breakdown ]] && print -P "%F{yellow}${cmd_line}%f" && print -P "%F{240}${breakdown}%f"
    zle -U "$cmd_line"
    zle accept-line
  else
    zle accept-line
  fi
}
zle -N zsh_line_finish

bindkey '^M' zsh_line_finish
