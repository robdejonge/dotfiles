#!/bin/sh
# Usage: sh -c "$(curl -fsSL https://raw.githubusercontent.com/robdejonge/dotfiles/main/.bin/bootstrap.sh)"
set -e

REPO_HTTPS="https://github.com/robdejonge/dotfiles.git"
REPO_SSH="git@github.com:robdejonge/dotfiles.git"
BRANCH="${DOTFILES_BRANCH:-main}"
DIR="$HOME/.repo"
BACKUP="$HOME/.repo-backup"

config() { git --git-dir="$DIR" --work-tree="$HOME" "$@"; }

cd "$HOME"

if [ -e "$DIR" ]; then
    echo "$DIR already exists; refusing to continue." >&2
    exit 1
fi

git clone --quiet --bare --branch "$BRANCH" "$REPO_HTTPS" "$DIR"
config config --local status.showUntrackedFiles no

# Move aside anything checkout would overwrite
if ! config checkout 2>/dev/null; then
    mkdir -p "$BACKUP"
    config checkout 2>&1 | grep -E '^[[:space:]]+' | awk '{print $1}' | while read -r f; do
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP/$f"
        echo "moved existing $f to $BACKUP/$f"
    done
    config checkout
fi

# README belongs on GitHub, not in $HOME
config update-index --assume-unchanged README.md
rm -f "$HOME/README.md"

# Tracking + push over SSH (no key needed for the clone itself)
config config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
config config branch."$BRANCH".remote origin
config config branch."$BRANCH".merge refs/heads/"$BRANCH"
config remote set-url --push origin "$REPO_SSH"

# Create XDG directories
. "$HOME/.config/zsh/environment"
sh "$HOME/.bin/repo-install.sh"

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


echo "Dotfiles installed from branch '$BRANCH'. Start a new login shell."

if [ -n "$(ls -A "$BACKUP" 2>/dev/null)" ]; then
    echo "Backed-up files are in $BACKUP - inspect, then remove that directory."
fi

