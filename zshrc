# ==========================================
# 1. Environment & Lang Settings
# ==========================================
autoload -Uz colors && colors

export LANG='ja_JP.UTF-8'
export LC_ALL='ja_JP.UTF-8'
export LC_TIME='en_US.UTF-8'
export LC_MESSAGES='ja_JP.UTF-8'

# ターミナルカラー設定
export TERM=xterm-256color

# 重複するパスを自動的に削除する設定 (Zsh特有)
typeset -U path PATH

# ==========================================
# 2. Path Configuration (M1 Mac Optimized)
# ==========================================

# --- Homebrew (M1/Apple Silicon) ---
# 他のツールの依存関係解決のため最優先で読み込む
if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- System Paths ---
# $HOME/bin と /usr/local/bin を追加
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# ==========================================
# 3. zsh-completions & Compinit
# ==========================================
# 補完機能を初期化する前に zsh-completions のパスを通す必要があります

if type brew &>/dev/null; then
    _HOMEBREW_PREFIX=$(brew --prefix)
    # zsh-completions がインストールされていれば fpath に追加
    if [ -d "$_HOMEBREW_PREFIX/share/zsh-completions" ]; then
        fpath=("$_HOMEBREW_PREFIX/share/zsh-completions" $fpath)
    fi
    unset _HOMEBREW_PREFIX
fi

# 補完機能の初期化
# -u: 権限チェック警告 (Insecure directories) を抑制して読み込む
autoload -U compinit promptinit
compinit -u
promptinit

# ==========================================
# 4. Zsh History & Options
# ==========================================
zmodload zsh/complist

HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=100000

# ヒストリ設定
setopt extended_history       # 開始・終了時刻を記録
setopt share_history          # ヒストリを共有
setopt hist_verify            # 呼び出し時に一旦編集可能にする
setopt hist_ignore_dups       # 直前と同じコマンドは記録しない
setopt hist_ignore_all_dups   # 過去の重複も削除 (履歴をクリーンに保つ)

# 補完・操作設定
setopt correct                # コマンドのスペル訂正
setopt auto_menu              # TABで補完候補を順に切り替え
setopt auto_list              # 補完候補を一覧表示
setopt list_packed            # 補完候補を詰めて表示
setopt list_types             # ファイル種別をマーク表示
setopt noautoremoveslash      # 末尾のスラッシュを勝手に消さない
setopt auto_param_keys        # カッコの対応などを自動補完
setopt magic_equal_subst      # --prefix=... の後も補完
unsetopt promptcr             # 末尾に改行がない出力でも表示
setopt nobeep                 # ビープ音を鳴らさない
setopt extended_glob          # #, ~, ^ を正規表現として扱う
setopt numeric_glob_sort      # 数字順にソート (1, 2, 10 の順)
setopt print_eight_bit        # 日本語ファイル名などを正しく表示

zstyle ':completion:*' menu select

# 大文字・小文字を区別しない補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# コマンドにsudoを付けても補完を効かせる
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# ==========================================
# 5. Colors (ls & completion)
# ==========================================
# Mac標準のls用カラー (BSD Style)
export LSCOLORS=ExFxCxdxBxegedabagacad
# GNU ls用カラー (Linux Style)
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
# Zshの補完リストでも色を使う
export ZLS_COLORS=$LS_COLORS

# 補完候補のカラー設定
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion:*' history-size $HISTSIZE
zstyle ':completion:*' save-history $SAVEHIST

# ==========================================
# 6. Prompt & Git Integration
# ==========================================

# プロンプト変数内での変数展開を許可
setopt prompt_subst

# Gitステータス取得関数
function check_git_status {
  local name st color

  # .gitディレクトリ内での実行をスキップ
  if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
    return 0
  fi

  # git branch名取得 (エラー抑制)
  name=$(git symbolic-ref HEAD 2> /dev/null | sed 's!refs/heads/!!')
  if [[ -z $name ]]; then
    return 0
  fi

  # git status取得
  st=$(git status --short 2> /dev/null)
  case "$st" in
    "") color=${fg[green]} ;;           # Clean
    *"\?\? "* ) color=${fg[yellow]} ;;  # Untracked
    *"\ M "* ) color=${fg[red]} ;;      # Modified
    * ) color=${fg[cyan]} ;;            # Added
  esac

  echo "[%{$color%}$name%{$reset_color%}]"
}

# プロンプト定義: ユーザー名@ホスト名 ディレクトリ [git branch]
PROMPT="%{${fg[green]}%}%n@%m %{${fg[yellow]}%}%3~%{${reset_color}%} "
RPROMPT='`check_git_status`'

# 継続行などのプロンプト
PROMPT2="%{${fg[green]}%}%_%%%{${reset_color}%} "
SPROMPT="%{${fg[green]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "

# SSH接続時のみホスト名を目立たせる処理
if [ -n "${REMOTEHOST}${SSH_CONNECTION}" ]; then
    PROMPT="%{${fg[white]}%}${HOST%%.*} ${PROMPT}"
fi

# ==========================================
# 7. External Tools (Pyenv, Conda, Cargo)
# ==========================================

# --- Pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# --- Conda ---
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# --- Rust / Cargo ---
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# --- Local User Envs ---
# ユーザーローカルのPATHは優先度を上げるため最後に追加（先頭に来るように）
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# ==========================================
# 8. Aliases
# ==========================================
# zip自身を含まないように -x オプションを追加
# zipファイル自身、DS_Store、および .git フォルダを除外
alias makezip='zip -r "${PWD##*/}.zip" . -x "*.zip" -x "*.DS_Store" -x "*.git*"'

# Macのlsで色を表示するためのエイリアス
alias ls='ls -G'
alias ll='ls -lG'
alias la='ls -laG'


# ==========================================
# 9. PowerShell-like Highlighting & Autosuggestions
# ==========================================
# 注意: brew install zsh-syntax-highlighting zsh-autosuggestions が必要です

# M1 Mac (Homebrew) path
HB_PREFIX="/opt/homebrew"

# 1. Syntax Highlighting (入力中のコマンドを色付け)
if [ -f "$HB_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$HB_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    
    # オプション: PowerShell風の色味に近づける設定
    # コマンド: 黄色, 文字列: シアン, エラー: 赤
    # ZSH_HIGHLIGHT_STYLES[command]='fg=yellow,bold'
    # ZSH_HIGHLIGHT_STYLES[alias]='fg=yellow,bold'
    # ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow'
    # ZSH_HIGHLIGHT_STYLES[string]='fg=cyan'
fi

# 2. Autosuggestions (履歴から薄い文字で予測を表示)
# 右矢印キー(→) または Ctrl+E で確定できます
if [ -f "$HB_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HB_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    # 予測文字の色を薄いグレーに設定
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
fi
