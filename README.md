# dotfiles

Although many options exist, ranging from custom scripts to tools such as Stow, when looking for a solution I felt the bare Git repo was the most elegant of all available. The idea came from https://www.atlassian.com/git/tutorials/dotfiles, and a few instructions are outlined below. 

## Initial setup

I like using .repo as the directory in which the Git repo is stored. Again, this is a bare repo and so the work space (work tree) is my actual home directory. 

Step 1. Create the repository

    git init $HOME/.repo
Step 2. Add an alias to your current shell and where you store your aliases (.zshrc in the example below)  

    alias config='/usr/bin/git --git-dir=$HOME/.repo --work-tree=$HOME'
    echo "alias config='/usr/bin/git --git-dir=$HOME/.repo --work-tree=$HOME'" >>$HOME/.zshrc
Step 3. Make sure untracked files aren't shown, as there would be MANY. First time using the alias!

    config config --local status.showUntrackedFiles no
Step 4. Add the files you with to track

    config add .zshrc
    config add .vimrc
Step 5. When you've made changes, commit them to the repository

    config commit -m "Added .zshrc and .vimrc"
Step 6. Push your repository to your server of choice, if you want

    git remote add origin  <REMOTE_URL>
    git push -u origin main
    
## Using on a new machine

Step 1. Ignore the repositoy in any other reposities that might be there

    echo ".repo" >> .gitignore
    
Step 2. Clone the repository from your server of choice into the local location 

    git clone --bare git@github.com:robdejonge/dotfiles.git $HOME/.repo
    
Step 3. Add a setting to not show untracked files (I create no alias, as I assume aliases will soon be loaded!) 

    git --git-dir=$HOME/.repo --work-tree $HOME config --local status.showUntrackedFiles no
    
Step 4. Put all the files stored in the repo, in their actual locations

    git --git-dir=$HOME/.repo --work-tree $HOME checkout

Step 5. Set upstream to push changes

    git --git-dir=$HOME/.repo --work-tree $HOME push --set-upstream origin main
    
Step 6. Run the init script once and once only

    $HOME/.bin/repo-install.sh
    
Step 7. Close and open your shell window


If things aren't working, please refer to the original blog post from which all this was derives for additional information and steps to take. 

