#                _
#     ____  ___| |__  _ __ ___
#    |_  / / __| '_ \| '__/ __|
#     / /_ \__ \ | | | | | (__
#    /___(_)___/_| |_|_|  \___|
#
# -----------------------------------------------------
# zsh loader (mirrors the previous ML4W bashrc loader)
# -----------------------------------------------------

# DON'T CHANGE THIS FILE

# You can define your custom configuration by adding
# files in ~/.config/zshrc
# or by creating a folder ~/.config/zshrc/custom
# with copies of files from ~/.config/zshrc
# You can also create a .zshrc_custom file in your home directory
# -----------------------------------------------------

# -----------------------------------------------------
# Load modular configuration
# -----------------------------------------------------

for f in ~/.config/zshrc/*; do
    if [ ! -d $f ] ;then
        c=`echo $f | sed -e "s=.config/zshrc=.config/zshrc/custom="`
        [[ -f $c ]] && source $c || source $f
    fi
done

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

if [ -f ~/.zshrc_custom ] ;then
    source ~/.zshrc_custom
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/gabriel/.anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/gabriel/.anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/gabriel/.anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/gabriel/.anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/gabriel/.lmstudio/bin"
# End of LM Studio CLI section

