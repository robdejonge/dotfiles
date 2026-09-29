#!/bin/sh
#
# Usage: 
# sh -c "$(curl -fsSL "https://raw.githubusercontent.com/robdejonge/dotfiles/main/.local/bin/bootstrap.sh?$(date +%s)")"
#
# Source:
# https://github.com/robdejonge/dotfiles/

# Change these if you fork this repo 
GHUSERNAME="robdejonge"
GHREPONAME="dotfiles"

REPO_HTTPS="https://github.com/${GHUSERNAME}/${GHREPONAME}.git"
REPO_SSH="git@github.com:${GHUSERNAME}/${GHREPONAME}.git"
BRANCH="${DOTFILES_BRANCH:-main}"
DIR="$HOME/.${GHREPONAME}"
BACKUP="$HOME/.original-${GHREPONAME}-backup-$(date +%Y%m%d-%H%M%S)"

echo "> Starting dotfiles setup...."


# Hard dependencies: fail fast if either is missing
echo -n "> Checking dependencies..."
missing=""
pkgs=""
command -v git >/dev/null 2>&1 || { missing="$missing git"; pkgs="$pkgs git"; }
command -v zsh >/dev/null 2>&1 || { missing="$missing zsh"; pkgs="$pkgs zsh"; }

if [ -n "$missing" ]; then
    echo "failed"
    echo "  ERROR: missing required tools:$missing" >&2
    echo "  - Debian/Ubuntu: sudo apt-get install -y$pkgs" >&2
    echo "  - FreeBSD:       sudo pkg install -y$pkgs" >&2
    echo "  - macOS:         git: xcode-select --install ; zsh: preinstalled" >&2
    exit 1
fi

echo "ok"

# Do not overwrite an existing install
echo -n "> Checking for existing install..."

dotfiles() { git --git-dir="$DIR" --work-tree="$HOME" "$@"; }

cd "$HOME"

if [ -e "$DIR" ]; then
    echo "found" 
    echo "  ERROR: $DIR already exists; refusing to continue." >&2
    exit 1
fi

echo "not found, proceeding" 

# Downloading repo
echo "> Cloning ${REPO_HTTPS}"
git clone --quiet --bare --branch "$BRANCH" "$REPO_HTTPS" "$DIR"
dotfiles config --local status.showUntrackedFiles no

# Move aside anything checkout would overwrite
echo -n "> Checking for conflicts..."
if ! dotfiles checkout 2>/dev/null; then
    echo "conflict detected"
    mkdir -p "$BACKUP"
    dotfiles checkout 2>&1 | grep -E '^[[:space:]]+' | awk '{print $1}' | while read -r f; do
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP/$f"
        echo "  - Moved existing $f to $BACKUP/$f"
    done
    dotfiles checkout
else 
    echo "none found"
fi

# README belongs on GitHub, not in $HOME
echo "> Deleting README locally, not on repo" 
dotfiles update-index --assume-unchanged README.md
rm -f "$HOME/README.md"

# Tracking + push over SSH (no key needed for the clone itself)
echo "> Configuring git for this repo" 
dotfiles config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
dotfiles fetch origin
dotfiles config branch."$BRANCH".remote origin
dotfiles config branch."$BRANCH".merge refs/heads/"$BRANCH"
dotfiles remote set-url --push origin "$REPO_SSH"

# Create runtime directories and files expected by the dotfiles
echo "> Loading environment"

if [ -r "$HOME/.config/zsh/environment" ]; then
    . "$HOME/.config/zsh/environment"
fi

echo "> Creating runtime directories and files" 
for d in \
    "$XDG_CACHE_HOME/zsh" \
    "$XDG_CACHE_HOME/vi/undodir" \
    "$XDG_CACHE_HOME/less" \
    "$XDG_DATA_HOME/mail"
do
    mkdir -p "$d"
done

touch "$XDG_CACHE_HOME/zsh/history" "$XDG_DATA_HOME/mail/mbox"

echo "> Running OS-specific tasks, if any"

case "$(uname -s)" in
  OpenBSD)
    if [ -f "$HOME/.config/vi/exrc" ]; then
      ln -sfn "$HOME/.config/vi/exrc" "$HOME/.exrc"
    fi
    ;;
esac

echo "> Dotfiles setup complete"
echo "-"


# Report legacy shell files that zsh with ZDOTDIR will never read
echo " "
echo -n "> Looking for existing shell configuration files..." 

found=""
for f in .profile .bash_profile .bash_login .bash_logout .bashrc .zshrc .zprofile .zlogin .zlogout; do
    [ -f "$HOME/$f" ] && found="$found $f"
done

if [ -n "$found" ]; then
    echo "found: "
    for f in $found; do
        printf '  - %-16s %s\n' "$f" "$(wc -l < "$HOME/$f") lines"
    done
    echo ""
    echo "  These files are not part of and not managed by this repo. They will not be"
    echo "  read by zsh with ZDOTDIT set. Check them for host-specific settings such"
    echo "  as path, proxies, tokens, before removing." 
    if [ -t 0 ] && [ -z "$DOTFILES_NONINTERACTIVE" ]; then
        echo ""
        printf '  Move them to %s? [y/N] ' "$BACKUP"
        read -r answer
        case "$answer" in
            y|Y)
                echo -n "  Moving..."
                mkdir -p "$BACKUP"
                for f in $found; do mv "$HOME/$f" "$BACKUP/$f"; done
                echo "done"
                echo "  Review in $BACKUP/"
                ;;
            *) echo "  Left in place." ;;

        esac
    fi
else 
    echo "not found" 
fi

# Suggest a client ssh, for easy access
echo " "
echo "> Consider installing a client SSH key for easy access to this shell:"
echo "  - ssh-copy-id $(id -un)@$(hostname)"

# If none exists, suggest a local ssh key for easy uploads to GitHub
echo " "
echo -n "> Confirming a local SSH key exists..."
if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo "not found"
    echo "  If you plan to push changes from this machine, do the following:"
    echo "  - ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C \"\$(hostname)\""
    echo "  - cat ~/.ssh/id_ed25519.pub"
    echo "  - Add at https://github.com/${GHUSERNAME}/${GHREPONAME}/settings/keys/new"
else 
    echo "ok"
fi

# Helpful warning only: zsh is installed but not the default shell
case "$SHELL" in
    */zsh) : ;;
    *) echo 
    echo "> Please note the default shell is $SHELL, not zsh. To change:"
    echo "  - chsh -s $(command -v zsh)" ;;
esac

echo " " 
echo "Done. Start a new login shell to effect changes."
echo
