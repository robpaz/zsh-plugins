# =============================================================================
# yesica-zsh.plugin.zsh — Natural language shell assistant
# =============================================================================
#
# PROMPT SHORTCUTS (press Enter after typing):
#
#   # <description>     Translate natural language to a shell command and run it
#                       Example:  # find all jpg files modified in the last 7 days
#
#   #? <question>       Ask a free-form question; print answer, do NOT execute
#                       Example:  #? what does the sticky bit do on a directory
#
# PIPE / STDIN COMMANDS:
#
#   yesica "<question>"                   Ask a plain question
#   yesica "<question>" < file.txt        Ask about file contents
#   <cmd> | yesica "<question>"           Ask about command output (any size)
#   <cmd> | yesica "<question>" --raw     Same but print raw output (no color)
#
#   Examples:
#     yesica "what is a zombie process"
#     cat /var/log/syslog | yesica "summarize the errors"
#     docker logs myapp 2>&1 | yesica "why is this crashing?"
#     curl -s https://api.example.com/status | yesica "is this response healthy?"
#     git diff | yesica "write a commit message for this diff"
#     yesica "explain this error" < error.txt
#
# ENVIRONMENT VARIABLES:
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
#   yesica-zsh-help      Print this usage reference
#   yesica --help         Same as yesica-zsh-help
# =============================================================================

# Auto-load .env from the plugin directory if present (never committed, see .env.example)
_YESICA_ZSH_DIR="${0:A:h}"
[[ -f "$_YESICA_ZSH_DIR/.env" ]] && source "$_YESICA_ZSH_DIR/.env"
unset _YESICA_ZSH_DIR

function yesica-zsh-help() {
  print -P "%F{yellow}yesica-zsh — Natural language shell assistant%f"
  print ""
  print -P "%F{green}PROMPT SHORTCUTS%f (type and press Enter):"
  print -P "  %F{cyan}# <description>%f     Translate to shell command and execute"
  print -P "  %F{cyan}#? <question>%f       Ask a question, print answer only (no execution)"
  print ""
  print -P "%F{green}PIPE / STDIN — ask command%f:"
  print -P "  %F{cyan}yesica \"<question>\"%f                     Plain question"
  print -P "  %F{cyan}yesica \"<question>\" < file%f              Ask about file contents"
  print -P "  %F{cyan}<cmd> | yesica \"<question>\"%f             Ask about command output"
  print -P "  %F{cyan}<cmd> | yesica \"<question>\" --raw%f       Same, plain text output"
  print ""
  print -P "%F{green}EXAMPLES%f:"
  print -P "  # find all jpg files modified in the last 7 days"
  print -P "  #? what does the sticky bit do on a directory"
  print -P "  cat /var/log/syslog | yesica \"summarize the errors\""
  print -P "  docker logs myapp 2>&1 | yesica \"why is this crashing?\""
  print -P "  git diff | yesica \"write a commit message for this diff\""
  print -P "  yesica \"what is a zombie process\""
  print ""
  print -P "%F{green}ENV VARS%f:"
  print -P "  OPENROUTER_API_KEY   sk-or-...   (uses deepseek/deepseek-v3.2 by default)"
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
    reply=("https://openrouter.ai/api/v1/chat/completions" "$OPENROUTER_API_KEY" "${OPENROUTER_MODEL:-deepseek/deepseek-v3.2}")
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

  payload=$(jq -n \
    --arg model "$model" \
    --argjson temp "$temperature" \
    --argjson messages "$messages" \
    '{"model": $model, "messages": $messages, "temperature": $temp, "stream": false}')

  response=$(curl -s --max-time 60 "$endpoint" \
    --header "Authorization: Bearer $api_key" \
    --header "Content-Type: application/json" \
    --data "$payload")

  echo "$response" | jq -r '.choices[0].message.content // "Error: \(.error.message // "unknown error")"'
}

# -----------------------------------------------------------------------------
# Internal: translate natural language to shell command
# -----------------------------------------------------------------------------
function _chat_zsh_translate() {
  local desc="$1"
  local messages

  messages=$(jq -n \
    --arg desc "$desc" \
    '[
      {"role":"system","content":"You are a senior engineer who has mastered the command line ability of natural language translation. For the natural language input by the user, it is converted into a command line command according to the description content. Output may only contain executable commands, any other descriptive or explanatory text is prohibited. For the answer, you simply output a one-line translatable command, stripping out any description preceding the command. 1. For multi-line commands, use & or && to connect. 2. For dangerous commands, add DANGEROUS at the beginning of the command"},
      {"role":"user","content":"mac install node js"},
      {"role":"assistant","content":"brew install node"},
      {"role":"user","content":"delete all files and folders"},
      {"role":"assistant","content":"DANGEROUS rm -rf *"},
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
  local question="$1" context="$2"
  local messages

  if [[ -n $context ]]; then
    messages=$(jq -n \
      --arg ctx "$context" \
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
# Public: yesica — question with optional stdin context
# Usage:
#   yesica "question"
#   yesica "question" < file
#   command | yesica "question"
#   command | yesica "question" --raw
# -----------------------------------------------------------------------------
function yesica() {
  local question="" raw=0 context=""

  if [[ $1 == "--help" || $1 == "-h" ]]; then
    yesica-zsh-help
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
    print -P "%F{red}Usage: yesica \"your question\" [< file | pipe] [--raw]%f" >&2
    return 1
  fi

  if [[ ! -t 0 ]]; then
    context=$(cat)
  fi

  local answer
  answer=$(_chat_zsh_answer "$question" "$context")

  if (( raw )); then
    echo "$answer"
  else
    print -P "%F{cyan}${answer}%f"
  fi
}

# -----------------------------------------------------------------------------
# ZLE widget: intercept Enter key for # and #? prefixes
# -----------------------------------------------------------------------------
function zsh_line_finish() {
  local buffer=$BUFFER
  local first_two="${buffer:0:2}"
  local first_letter="${buffer:0:1}"

  if [[ -n $buffer && $first_two == '#?' ]]; then
    local question="${buffer:2}"
    zle -I
    print
    print -P "%F{cyan}$(_chat_zsh_answer "$question")%f"
    zle reset-prompt
  elif [[ -n $buffer && $first_letter == '#' ]]; then
    local remaining="${buffer:1}"
    local new_str
    new_str=$(_chat_zsh_translate "$remaining")
    zle -U "$new_str"
    zle accept-line
  else
    zle accept-line
  fi
}
zle -N zsh_line_finish

bindkey '^M' zsh_line_finish
