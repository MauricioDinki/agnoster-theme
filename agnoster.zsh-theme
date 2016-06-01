# FONT ICONS
################################################################
SEGMENT_SEPARATOR="\ue0b0"
ROOT_ICON="\u26A1"
BACKGROUND_JOBS_ICON="\u2699"
OK_ICON="\u2713"
FAIL_ICON="\u2718"

# CUSTOM ICONS
################################################################
VIRTUAL_ENV_ICON="🐍"

VCS_GIT_ICON="\ue80c  "
VCS_BRANCH_ICON="\ue822 "
VCS_UNTRACKED_ICON="\ue16c "
VCS_STAGED_ICON="\ue168 "
VCS_UNSTAGED_ICON="\ue17c "
VCS_TAG_ICON="\ue817 "
VCS_STASH_ICON="\uE133 "
VCS_INCOMING_CHANGES="\ue1eb  "
VCS_OUTGOING_CHANGES="\ue1ec  "

# COLOR SCHEME
################################################################
DEFAULT_COLOR=black
DEFAULT_COLOR_INVERTED=white
DEFAULT_COLOR_DARK="236"

VCS_FOREGROUND_COLOR=$DEFAULT_COLOR
VCS_FOREGROUND_COLOR_DARK=$DEFAULT_COLOR_DARK


# VCS SETTINGS
################################################################

setopt prompt_subst
autoload -Uz vcs_info

local VCS_CHANGESET_HASH_LENGTH=5

VCS_WORKDIR_DIRTY=false
VCS_CHANGESET_PREFIX="%F{$VCS_FOREGROUND_COLOR_DARK}$VCS_COMMIT_ICON%0.$VCS_CHANGESET_HASH_LENGTH""i%f "


zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true

VCS_DEFAULT_FORMAT="$VCS_CHANGESET_PREFIX%F{$VCS_FOREGROUND_COLOR}%b%c%u%m%f"
zstyle ':vcs_info:git:*' formats "%F{$VCS_FOREGROUND_COLOR}$VCS_GIT_ICON%f$VCS_DEFAULT_FORMAT"

zstyle ':vcs_info:*' actionformats " %b %F{red}| %a%f"

zstyle ':vcs_info:*' stagedstr " %F{$VCS_FOREGROUND_COLOR}$VCS_STAGED_ICON%f"
zstyle ':vcs_info:*' unstagedstr " %F{$VCS_FOREGROUND_COLOR}$VCS_UNSTAGED_ICON%f"

zstyle ':vcs_info:git*+set-message:*' hooks vcs-detect-changes git-untracked git-aheadbehind git-stash git-remotebranch git-tagname

zstyle ':vcs_info:*' get-revision true

# The 'vcs' Segment and VCS_INFO hooks / helper functions
################################################################
function +vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' && \
            ${$(git ls-files --others --exclude-standard | sed q | wc -l)// /} != 0 ]]; then
        hook_com[unstaged]+=" %F{$VCS_FOREGROUND_COLOR}$VCS_UNTRACKED_ICON%f"
    fi
}

function +vi-git-aheadbehind() {
    local ahead behind branch_name
    local -a gitstatus

    branch_name=${$(git symbolic-ref --short HEAD 2>/dev/null)}

    # for git prior to 1.7
    # ahead=$(git rev-list origin/${branch_name}..HEAD | wc -l)
    ahead=$(git rev-list ${branch_name}@{upstream}..HEAD 2>/dev/null | wc -l)
    (( $ahead )) && gitstatus+=( " %F{$VCS_FOREGROUND_COLOR}$VCS_OUTGOING_CHANGES${ahead// /}%f" )

    # for git prior to 1.7
    # behind=$(git rev-list HEAD..origin/${branch_name} | wc -l)
    behind=$(git rev-list HEAD..${branch_name}@{upstream} 2>/dev/null | wc -l)
    (( $behind )) && gitstatus+=( " %F{$VCS_FOREGROUND_COLOR}$VCS_INCOMING_CHANGES${behind// /}%f" )

    hook_com[misc]+=${(j::)gitstatus}
}

function +vi-git-remotebranch() {
    local remote branch_name

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify HEAD@{upstream} --symbolic-full-name 2>/dev/null)/refs\/(remotes|heads)\/}
    branch_name=${$(git symbolic-ref --short HEAD 2>/dev/null)}

    hook_com[branch]="%F{$VCS_FOREGROUND_COLOR}$VCS_BRANCH_ICON${hook_com[branch]}%f"
    # Always show the remote
    #if [[ -n ${remote} ]] ; then
    # Only show the remote if it differs from the local
    if [[ -n ${remote} && ${remote#*/} != ${branch_name} ]] ; then
        hook_com[branch]+="%F{$VCS_FOREGROUND_COLOR}$VCS_REMOTE_BRANCH_ICON%f%F{$VCS_FOREGROUND_COLOR}${remote// /}%f"
    fi
}

function +vi-git-tagname() {
    local tag

    tag=$(git describe --tags --exact-match HEAD 2>/dev/null)
    [[ -n "${tag}" ]] && hook_com[branch]="%F{$VCS_FOREGROUND_COLOR}$VCS_TAG_ICON${tag}%f"
}

function +vi-git-stash() {
  local -a stashes

  if [[ -s $(git rev-parse --git-dir)/refs/stash ]] ; then
    stashes=$(git stash list 2>/dev/null | wc -l)
    hook_com[misc]+=" %F{$VCS_FOREGROUND_COLOR}$VCS_STASH_ICON${stashes// /}%f"
  fi
}

prompt_segment() {
  local bg fg
  [[ -n $2 ]] && bg="%K{$2}" || bg="%k"
  [[ -n $3 ]] && fg="%F{$3}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $2 != $CURRENT_BG ]]; then
    # Middle segment
    echo -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    # First segment
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$2
  [[ -n $4 ]] && echo -n "$4 "
}

prompt_vcs() {
  local vcs_prompt="${vcs_info_msg_0_}"

  if [[ -n "$vcs_prompt" ]]; then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment "$0" "yellow" "$DEFAULT_COLOR"
    else
        prompt_segment "$0" "070" "$DEFAULT_COLOR"
    fi

    echo -n "%f$vcs_prompt "
  fi
}

prompt_status() {
  local symbols
  symbols=()
  if [[ "$RETVAL" -ne 0 ]]; then
    symbols+="%{%F{red}%}$FAIL_ICON"
  else
    symbols+="%{%F{046}%}$OK_ICON"
  fi
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$BACKGROUND_JOBS_ICON"

  [[ -n "$symbols" ]] && prompt_segment "$0" "$DEFAULT_COLOR" "default" "$symbols"
}

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    if [[ $(print -P "%#") == '#' ]]; then
      # Shell runs as root
      prompt_segment "$0_ROOT" "$DEFAULT_COLOR" "yellow" "@$"
    else
      prompt_segment "$0_DEFAULT" "$DEFAULT_COLOR" "011" "@$USER"
    fi
  fi
}

prompt_dir() {
  local current_path='%~'
  current_path="%$((3))(c:.../:)%2c"
  prompt_segment "$0" "blue" "white" "$current_path"
}

prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n "$virtualenv_path" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    prompt_segment "$0" "cyan" "black" "$VIRTUAL_ENV_ICON  `basename $virtualenv_path`"
  fi
}

prompt_node_version() {
  local nvm_prompt=$(node -v 2>/dev/null)
  [[ -z "${nvm_prompt}" ]] && return
  NODE_ICON="\ue158"

  prompt_segment "$0" "green" "white" "${nvm_prompt:1}"
}


prompt_root() {
    if [[ $(print -P "%#") == '#' ]]; then
      # Shell runs as root
      prompt_segment "$0_DEFAULT" "$DEFAULT_COLOR" "011" "$ROOT_ICON"
    fi
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%} "
  CURRENT_BG=''
}

build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  prompt_dir
  prompt_virtualenv
  prompt_vcs
  prompt_node_version
  prompt_root
  prompt_end
}

developerdream_init() {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent subst)

  # Initialize colors
  autoload -U colors && colors

  # Initialize VCS
  autoload -Uz add-zsh-hook

  add-zsh-hook precmd vcs_info

  PROMPT="%{%f%b%k%}"'$(build_prompt)'
}

developerdream_init "$@"
