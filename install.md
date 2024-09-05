# Install

What to install on Mac to get set up for development.

- homebrew:
  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/andrewdamario/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ```
    - [How To Install Older Versions of Homebrew Packages](https://nelson.cloud/how-to-install-older-versions-of-homebrew-packages/)
      - note: the PACKAGE_NAME.rb has to be the name of the desired package exactly
- open shift: `brew install openshift-cli`
- podman: `brew install podman`
  - init podman: `podman machine init --cpus=3 --memory=4048`
  - remove podman machine (reset): `podman machine rm`
- java: `brew install openjdk`
  - create symlink: `sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk`
- minikube: `brew install minikube`
- openshift local: https://console.redhat.com/openshift/create/local
- ZenHub Enterprises Firefox / Chrome extension: https://zenhub.ibm.com/
- VScode `code` terminal command: Cmd+Shift+P > Run "Shell Command: Install 'code' command in PATH"
- clipboard: `brew install maccy`
- terminal:
  - `brew install oh-my-posh`
  - `brew install zsh-autosuggestions`
    - `echo "source \$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc`
  - `brew install zsh-fast-syntax-highlighting`
    - `echo "source \$HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" >> ~/.zshrc`
  - install powerline font: `brew tap homebrew/cask-fonts && brew install --cask font-hack-nerd-font`
    - set terminal font to "NAME Nerd Font" in VScode, where NAME is the font name you chose (in my case "Hack")
  - set your working code directory with wherever you have cloned this repo: `echo "export WORKING_DIR=~/code" >> ~/.zshrc`
  - set myrc config: `echo "source $WORKING_DIR/andrew-notes/rc/myrc.sh" >> ~/.zshrc`
  - if you want (not as necessary):
    - `brew install zsh-autocomplete`
      - `echo "source \$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" >> ~/.zshrc`
  - set myrc config: `echo "source $WORKING_DIR/andrew-notes/term/myrc.sh" >> ~/.zshrc`

# Settings

- firefox:
  - uncheck "Query OCSP responder servers to confirm the current validity of certificates"

### Other Setups
(not needed with myrc.sh)
- Oh My Posh:
  - `oh-my-posh init zsh > ~/.zshrc`
  - set `POSH_THEME` in `~/.zshrc` to the out of `echo $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json`
- Oh My zsh: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
  - (not needed with oh my posh theme) `omz theme set agnoster`
  - add
    ```
    export ZSH="$HOME/.oh-my-zsh"
    source $ZSH/oh-my-zsh.sh
    ```
    to ~/.zshrc
