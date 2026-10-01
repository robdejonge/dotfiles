# dotfiles

Although many options exist, ranging from custom scripts to tools such as Stow, when looking for a solution I felt the bare Git repo was the most elegant of all available. The idea came from https://www.atlassian.com/git/tutorials/dotfiles, and a few instructions are outlined below. 

### Outline

- Uses the XDG Base Directory Specification
- The same repo is used across macOS, Debian, FreeBSD and OpenBSD

### Installation 

To download this repo and install in a new shell, run

    sh -c "$(curl -fsSL "https://raw.githubusercontent.com/robdejonge/dotfiles/main/.local/bin/bootstrap.sh?$(date +%s)")"

Or if `curl` is not installed, try

    sh -c "$(wget -qO- "https://raw.githubusercontent.com/robdejonge/dotfiles/main/.local/bin/bootstrap.sh?$(date +%s)")"

To re-install this repo using the bootstrap script, you must delete `~/.dotfiles` first or it won't run

The bootstrap script 

- POSIX compliant, runs in `/bin/sh`
- Requires git and zsh to be installed on the local system 
- Will back up any files it might overwrite
- Will offer to back up legacy shell files
- Provides a few basic suggestions at the end
    
### After installation

When a new shell opens, this checks if local changes should be uploaded or remote changes downloaded. This is throttled and actually happens only once every 24 hours. It can also be run manually, but this is also beholden to the throttling. 

    dotfiles-check
    
To review staged changes made locally 

    dotfiles-status

To push changes to the remote 

    dotfiles-push "Commit message"
    
To pull changes from the remote

    dotfiles-pull 

Other git actions 

    dotfiles <additional options and parameters>
    
If things aren't working, please refer to the original blog post from which all this was derives for additional information and steps to take. 
