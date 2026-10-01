#!/bin/sh
#
# Bootstraps my environment into a new shell account
#
# Usage:
# sh -c "$(curl -fsSL "https://raw.githubusercontent.com/robdejonge/dotfiles/main/.local/bin/bootstrap.sh?$(date +%s)")"
#
# Source:
# https://github.com/robdejonge/dotfiles/

set -eu

# ---------------------------------------------------------------------------
# Configuration (change these if you fork this repo)
# ---------------------------------------------------------------------------
GHUSERNAME="robdejonge"
GHREPONAME="dotfiles"

REPO_HTTPS="https://github.com/${GHUSERNAME}/${GHREPONAME}.git"
REPO_SSH="git@github.com:${GHUSERNAME}/${GHREPONAME}.git"
BRANCH="main"
REPO_DIR="$HOME/.${GHREPONAME}"
BACKUP="$HOME/.original-${GHREPONAME}-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_CONFLICTS="$BACKUP/conflicts" 
BACKUP_LEGACY="$BACKUP/legacy"    
EXCLUDE="README.md"  

# Runtime state (1 to remove a partial $REPO_DIR if failed) 
CLEANUP_DIR=0         

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

NEXT_STEPS=""          
NL='
'

say()    { printf '> %s\n' "$*"; } 
begin()  { printf '> %s...' "$*"; }
finish() { printf '%s\n' "$*"; }  
info()   { printf '  %s\n' "$*"; }

# die "message" ["extra line" ...]
die() {
    printf '  ERROR: %s\n' "$1" >&2
    shift
    for line in "$@"; do
        printf '  %s\n' "$line" >&2
    done
    exit 1
}

# note "heading" ["item" ...] -- queue a suggestion for the final block
note() {
    heading=$1
    shift
    NEXT_STEPS="${NEXT_STEPS}> ${heading}${NL}"
    for item in "$@"; do
        NEXT_STEPS="${NEXT_STEPS}  - ${item}${NL}"
    done
    NEXT_STEPS="${NEXT_STEPS}${NL}"
}

# Runs on every exit. On failure, removes a half-finished install so the
# script can simply be run again.
cleanup() {
    status=$?
    trap - EXIT
    if [ "$status" -ne 0 ]; then
        echo >&2
        if [ "$CLEANUP_DIR" -eq 1 ]; then
            rm -rf "$REPO_DIR"
            printf '  Removed the partial install at %s; it is safe to re-run.\n' "$REPO_DIR" >&2
        fi
        if [ -d "$BACKUP" ]; then
            printf '  Files moved aside earlier are in %s\n' "$BACKUP" >&2
        fi
    fi
    exit "$status"
}

# The bare repo, with $HOME as its work tree
dotfiles() { git --git-dir="$REPO_DIR" --work-tree="$HOME" "$@"; }

# ---------------------------------------------------------------------------
# Install steps
# ---------------------------------------------------------------------------

# Hard dependencies: fail fast if any is missing
check_deps() {
    begin "Checking dependencies"
    missing=""
    for tool in git zsh; do
        command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
    done
    if [ -n "$missing" ]; then
        finish "failed"
        die "missing required tools:$missing" \
            "- Debian/Ubuntu: sudo apt-get install -y$missing" \
            "- FreeBSD:       sudo pkg install -y$missing" \
            "- OpenBSD:       doas pkg_add$missing" \
            "- macOS:         git: xcode-select --install ; zsh: preinstalled"
    fi
    finish "ok"
}

# Never overwrite an existing install
refuse_if_installed() {
    begin "Checking for existing install"
    if [ -e "$REPO_DIR" ] || [ -L "$REPO_DIR" ]; then
        finish "found"
        die "$REPO_DIR already exists; refusing to continue." \
            "To update it:  git --git-dir=$REPO_DIR --work-tree=$HOME pull" \
            "To reinstall:  rm -rf $REPO_DIR   (files already in \$HOME are left in place)"
    fi
    finish "not found, proceeding"
}

# Clone as a bare repo
clone_repo() {
    say "Cloning ${REPO_HTTPS}"
    CLEANUP_DIR=1
    git clone --quiet --bare --branch "$BRANCH" "$REPO_HTTPS" "$REPO_DIR"
    dotfiles config --local status.showUntrackedFiles no

    mkdir -p "$REPO_DIR/info"
    printf '/*\n!/%s\n' "$EXCLUDE" > "$REPO_DIR/info/sparse-checkout"
    dotfiles config --local core.sparseCheckout true
}

# Some git config 
configure_remote() {
    say "Configuring git for this repo"
    dotfiles config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    dotfiles fetch --quiet origin
    dotfiles config branch."$BRANCH".remote origin
    dotfiles config branch."$BRANCH".merge "refs/heads/$BRANCH"
    dotfiles remote set-url --push origin "$REPO_SSH"
}

# Move aside anything the checkout would overwrite
backup_conflicts() {
    begin "Checking for conflicts"
    tracked=$(dotfiles -c core.quotePath=false ls-tree -r --name-only HEAD)
    moved=0
    while IFS= read -r f; do
        if [ -z "$f" ]; then
            continue
        fi
        if [ -e "$HOME/$f" ] || [ -L "$HOME/$f" ]; then
            if [ "$moved" -eq 0 ]; then
                finish "conflict detected"
            fi
            mkdir -p "$BACKUP_CONFLICTS/$(dirname "$f")"
            mv "$HOME/$f" "$BACKUP_CONFLICTS/$f"
            info "- Moved existing $f to $BACKUP_CONFLICTS/$f"
            moved=$((moved + 1))
        fi
    done <<EOF
$tracked
EOF
    if [ "$moved" -eq 0 ]; then
        finish "none found"
    fi
}

# The only step that writes tracked files into $HOME
checkout_repo() {
    say "Checking out '${BRANCH}' branch"
    dotfiles checkout --quiet
    CLEANUP_DIR=0    
}

# Create runtime directories and files, executed by zsh as it will 
# read and have access to environment variables set within
init_runtime_dirs() {
    say "Creating runtime directories and files"
    zsh -c '
        : "${XDG_CACHE_HOME:=$HOME/.cache}"
        : "${XDG_DATA_HOME:=$HOME/.local/share}"
        mkdir -p "$XDG_CACHE_HOME/zsh" \
                 "$XDG_CACHE_HOME/vi/undodir" \
                 "$XDG_CACHE_HOME/less" \
                 "$XDG_DATA_HOME/mail"
        touch "$XDG_CACHE_HOME/zsh/history" "$XDG_DATA_HOME/mail/mbox"
    '
}

# Create local override files for machine-specific zsh settings
init_local_files() {
    say "Creating machine-specific zsh files, if missing"
    zsh -c '
        : "${ZDOTDIR:=$HOME}"
        for f in "$ZDOTDIR/zshenv.local" "$ZDOTDIR/zshrc.local"; do
            if [ ! -e "$f" ] && [ ! -L "$f" ]; then
                printf "# Machine-specific settings. Not tracked by git.\n" > "$f"
                printf "  - Created %s\n" "$f"
            fi
        done
    '
}

os_tasks() {
    say "Running OS-specific tasks, if any"
    case "$(uname -s)" in
        OpenBSD)
            if [ -f "$HOME/.config/vi/exrc" ]; then
                ln -sfn "$HOME/.config/vi/exrc" "$HOME/.exrc"
            fi
            ;;
    esac
}

# Report and move legacy shell files
report_legacy_shell_files() {
    begin "Looking for existing shell configuration files"
    found=""
    for f in .profile .bash_profile .bash_login .bash_logout .bashrc \
             .zshrc .zprofile .zlogin .zlogout; do
        if [ -f "$HOME/$f" ]; then
            found="$found $f"
        fi
    done

    if [ -z "$found" ]; then
        finish "not found"
        return 0
    fi

    finish "found:"
    for f in $found; do
        printf '  - %-16s %s lines\n' "$f" "$(wc -l < "$HOME/$f" | tr -d ' ')"
    done
    echo
    info "These files are not managed by this repo and will not be read by zsh"
    info "with ZDOTDIR set. Check them for host-specific settings (PATH, proxies,"
    info "tokens) before removing them."

    if [ -t 0 ]; then
        echo
        printf '  Move them to %s? [y/N] ' "$BACKUP_LEGACY"
        read -r answer || answer=""
        case "$answer" in
            y|Y)
                printf '  Moving...'
                mkdir -p "$BACKUP_LEGACY"
                for f in $found; do
                    mv "$HOME/$f" "$BACKUP_LEGACY/$f"
                done
                echo "done"
                info "Review them in $BACKUP_LEGACY/"
                ;;
            *)
                info "Left in place."
                ;;
        esac
    else
        info "Not prompting (non-interactive); left in place."
    fi
}

# Some handy suggestions after the environment was installed
has_local_ssh_key() {
    for k in "$HOME"/.ssh/id_*.pub; do
        if [ -f "$k" ]; then
            return 0
        fi
    done
    return 1
}

suggest_client_key() {
    note "For easy access to this machine, run this from your other machine:" \
        "ssh-copy-id $(id -un)@$(hostname)"
}

suggest_local_key() {
    if has_local_ssh_key; then
    note "Local SSH key found. To push changes from this machine: " \
        "Add it at https://github.com/${GHUSERNAME}/${GHREPONAME}/settings/keys/new and tick \"Allow write access\""
        return 0
    fi
    note "No local SSH key found. To push changes from this machine:" \
        "ssh-keygen -q -t ed25519 -f ~/.ssh/id_ed25519 -C \"\$(hostname)\"" \
        "cat ~/.ssh/id_ed25519.pub" \
        "Add it at https://github.com/${GHUSERNAME}/${GHREPONAME}/settings/keys/new and tick \"Allow write access\""
}

suggest_default_shell() {
    case "${SHELL:-}" in
        */zsh) ;;
        *)
            note "The default shell is ${SHELL:-unknown}, not zsh. To change it:" \
                "chsh -s \"\$(command -v zsh)\""
            ;;
    esac
}

print_next_steps() {
    if [ -n "$NEXT_STEPS" ]; then
        echo
        echo "Next steps"
        echo "----------"
        printf '%s' "$NEXT_STEPS"
    fi
    echo "Done. "
    echo 
    echo "Start a new login shell to apply the changes."
    echo
}

# ---------------------------------------------------------------------------

main() {
    # clean up no matter how we crash, if we crash
    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # actual script starts
    say "Dotfiles setup started"
    cd "$HOME" || die "cannot cd to $HOME"

    check_deps
    refuse_if_installed
    clone_repo
    configure_remote
    backup_conflicts
    checkout_repo
    init_runtime_dirs
    os_tasks
    report_legacy_shell_files

    suggest_client_key
    suggest_local_key
    suggest_default_shell

    say "Dotfiles setup complete"
    print_next_steps
}

main "$@"
