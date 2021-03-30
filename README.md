# dotfiles

Although many options exist, ranging from custom scripts to tools such as Stow, when looking for a solution I felt the bare Git repo was the most elegant of all available. The idea came from https://www.atlassian.com/git/tutorials/dotfiles, and a few instructions are outlined below. 
    
## Using on a new machine

Step 1. Ignore the repository in any other reposities that might be there

    echo ".repo" >> .gitignore
    
Step 2. Clone the repository from your server of choice into the local location 

    git clone --bare git@github.com:robdejonge/dotfiles.git $HOME/.repo
    
Step 3. Add a setting to not show untracked files (I create no alias, as I assume aliases will soon be loaded!) 

    git --git-dir=$HOME/.repo --work-tree $HOME config --local status.showUntrackedFiles no
    
Step 4. Put all the files stored in the repo, in their actual locations

    git --git-dir=$HOME/.repo --work-tree $HOME checkout

Step 5. Set upstream to push changes

    git --git-dir=$HOME/.repo --work-tree $HOME push --set-upstream origin main

Step 6. Get rid of the README file in your home directory, it's only useful on GitHub 

    git --git-dir=$HOME/.repo --work-tree $HOME update-index --assume-unchanged $HOME/README.md
    rm $HOME/README.md
    
Step 7. Run the init script once and once only

    $HOME/.bin/repo-install.sh
    
Step 8. Close and open your shell window


If things aren't working, please refer to the original blog post from which all this was derives for additional information and steps to take. 

## Guiding principles used for this repository

- Uses the XDG Base Directory Specification, explicitly defining the default values to announce this
- User-specific configuration files (.config) are only added to the repository if I edited them; why save defaults?
