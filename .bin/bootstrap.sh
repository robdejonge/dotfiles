#!/bin/sh
# Usage: sh -c "$(curl -fsSL https://raw.githubusercontent.com/robdejonge/dotfiles/main/.bin/bootstrap.sh)"
# https://github.com/robdejonge/dotfiles/
set -e

REPO_HTTPS="https://github.com/robdejonge/dotfiles.git"
REPO_SSH="git@github.com:robdejonge/dotfiles.git"
BRANCH="${DOTFILES_BRANCH:-main}"
DIR="$HOME/.dotfiles"
BACKUP="$HOME/.original-dotfiles-backup"

# Hard dependencies: fail fast if either is missing
missing=""
pkgs=""
command -v git >/dev/null 2>&1 || { missing="$missing git"; pkgs="$pkgs git"; }
command -v zsh >/dev/null 2>&1 || { missing="$missing zsh"; pkgs="$pkgs zsh"; }

if [ -n "$missing" ]; then
    echo "ERROR: missing required tools:$missing" >&2
    echo "  Debian/Ubuntu: sudo apt-get install -y$pkgs" >&2
    echo "  FreeBSD:       sudo pkg install -y$pkgs" >&2
    echo "  macOS:         git: xcode-select --install ; zsh: preinstalled" >&2
    exit 1
fi

dotfiles() { git --git-dir="$DIR" --work-tree="$HOME" "$@"; }

cd "$HOME"

if [ -e "$DIR" ]; then
    echo "$DIR already exists; refusing to continue." >&2
    exit 1
fi

git clone --quiet --bare --branch "$BRANCH" "$REPO_HTTPS" "$DIR"
dotfiles config --local status.showUntrackedFiles no

# Move aside anything checkout would overwrite
if ! dotfiles checkout 2>/dev/null; then
    mkdir -p "$BACKUP"
    dotfiles checkout 2>&1 | grep -E '^[[:space:]]+' | awk '{print $1}' | while read -r f; do
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP/$f"
        echo "moved existing $f to $BACKUP/$f"
    done
    dotfiles checkout
fi

# README belongs on GitHub, not in $HOME
dotfiles update-index --assume-unchanged README.md
rm -f "$HOME/README.md"

# Tracking + push over SSH (no key needed for the clone itself)
dotfiles config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
dotfiles config branch."$BRANCH".remote origin
dotfiles config branch."$BRANCH".merge refs/heads/"$BRANCH"
dotfiles remote set-url --push origin "$REPO_SSH"

# Create runtime directories and files expected by the dotfiles
. "$HOME/.config/zsh/environment"
for d in \
    "$XDG_CACHE_HOME/zsh" \
    "$XDG_CACHE_HOME/vim/undodir" \
    "$XDG_CACHE_HOME/less" \
    "$XDG_DATA_HOME/mail"
do
    mkdir -p "$d"
done
touch "$XDG_CACHE_HOME/zsh/history" "$XDG_DATA_HOME/mail/mbox"

# Report legacy shell files that zsh with ZDOTDIR will never read
found=""
for f in .profile .bash_profile .bash_login .bash_logout .bashrc .zshrc .zprofile .zlogin .zlogout; do
    [ -f "$HOME/$f" ] && found="$found $f"
done

if [ -n "$found" ]; then
    echo
    echo "Pre-existing shell files not managed by the repo:"
    for f in $found; do
        printf '  %-16s %s\n' "$f" "$(wc -l < "$HOME/$f") lines"
    done
    echo "They will not be read by zsh with ZDOTDIR set. Check them for host-specific"
    echo "settings (PATH, proxies, tokens) before removing."
    if [ -t 0 ] && [ -z "$DOTFILES_NONINTERACTIVE" ]; then
        printf 'Move them to %s? [y/N] ' "$BACKUP"
        read -r answer
        case "$answer" in
            y|Y)
                mkdir -p "$BACKUP"
                for f in $found; do mv "$HOME/$f" "$BACKUP/$f"; done
                echo "Moved. Review with: less $BACKUP/*"
                ;;
            *) echo "Left in place." ;;
        esac
    fi
fi

echo


echo "-> Dotfiles installed from branch '$BRANCH'. "

if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo 
    echo "-> No SSH key found. To push changes from this machine:"
    echo "     ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C \"\$(hostname)\""
    echo "     cat ~/.ssh/id_ed25519.pub   # add at https://github.com/settings/keys"
fi

if [ -n "$(ls -A "$BACKUP" 2>/dev/null)" ]; then
    echo
    echo "-> Backed-up files are in $BACKUP - inspect, then remove that directory."
fi

# Helpful warning only: zsh is installed but not the default shell
case "$SHELL" in
    */zsh) : ;;
    *) echo 
       echo "-> Note: default shell is $SHELL, not zsh. To change:"
       echo "     chsh -s $(command -v zsh)" ;;
esac

echo 
echo "-> Start a new login shell to effect changes." 
