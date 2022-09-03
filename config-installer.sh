#!/bin/bash
# Created by Mico 2022

LOCATION_CONFIGS="$HOME/.config"
LOCATION_DOTFILES="$LOCATION_CONFIGS/.mico"
LOCATION_BACKUP="$LOCATION_DOTFILES/backup"

LOCATION_NVIM="$LOCATION_CONFIGS/nvim"
STRING_NVIM="nvim"

LOCATION_ZSHRC="$HOME/.zshrc"
STRING_ZSHRC="zshrc"

LOCATION_ALACRITTY="$LOCATION_CONFIGS/alacritty"
STRING_ALACRITTY="alacritty"

LOCATION_POLYBAR="$LOCATION_CONFIGS/polybar"
STRING_POLYBAR="polybar"

LOCATION_I3="$LOCATION_CONFIGS/i3"
STRING_I3="i3"

clear

# Select configs
options=("$STRING_NVIM" "$STRING_ZSHRC" "$STRING_ALACRITTY" "$STRING_I3" "$STRING_POLYBAR" "Quit")

# https://stackoverflow.com/questions/11912167/shell-script-multiple-select
menuitems() {
    clear
    echo "Configs:"
    for i in ${!options[@]}; do
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
}

prompt="Enter an option (enter again to uncheck, enter empty when done): "
while menuitems && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] && (( num > 0 && num <= ${#options[@]} )) || {
        msg="Invalid option: $num"; continue
    }
    if [ $num == ${#options[@]} ];then
      exit
    fi
    ((num--)); msg="${options[num]} was ${choices[num]:+un-}selected"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="x"
done

for i in ${!options[@]}; do
    [[ "${choices[i]}" ]] && CONFIGS="${CONFIGS}${options[i]} "
done
clear

# Backup
POSITIVE="Yes, backup"
NEGATIVE="No, don't backup"
echo -e "\033[33mThis process will overwrite your old configuration if any is found.\033[0m"
echo -e "\033[33mWould you like to backup your old configuration?\033[0m"
echo "Files will be backed up in ./backup/"

echo -e "\nConfiguration selected:\n\033[34m$CONFIGS\033[0m\\n"

echo -e "Backup old config files?:"
select BACKUP in "$POSITIVE" "$NEGATIVE"; do
    case $BACKUP in
        "$POSITIVE" ) break;;
        "$NEGATIVE" ) break;;
    esac
done
clear

# Create backups if user wants to backup
if [[ "$BACKUP" == "$POSITIVE" ]]
then
    THIS_BACKUP="$LOCATION_BACKUP/$(date +%Y-%m-%d-%s)"
    mkdir -p $THIS_BACKUP
    echo -e "Backing up selected configurations"

    if [[ "$CONFIGS" == *"$STRING_NVIM"* ]]
    then
        echo -e "\033[32mBacking up nvim\033[0m"
        mkdir "$THIS_BACKUP/nvim"
        cp -r "$LOCATION_NVIM" "$THIS_BACKUP/nvim"
    fi
    if [[ "$CONFIGS" == *"$STRING_ZSHRC"* ]]
    then
        echo -e "\033[32mBacking up zshrc\033[0m"
        mkdir "$THIS_BACKUP/.zshrc"
        cp "$LOCATION_ZSHRC" "$THIS_BACKUP/zshrc"
    fi
    if [[ "$CONFIGS" == *"$STRING_ALACRITTY"* ]]
    then
        echo -e "\033[32mBacking up alacritty\033[0m"
        mkdir "$THIS_BACKUP/alacritty"
        cp -r "$LOCATION_ALACRITTY" "$THIS_BACKUP/alacritty"
    fi
    if [[ "$CONFIGS" == *"$STRING_I3"* ]]
    then
        echo -e "\033[32mBacking up i3\033[0m"
        mkdir "$THIS_BACKUP/i3"
        cp -r "$LOCATION_I3" "$THIS_BACKUP/i3"
    fi
    if [[ "$CONFIGS" == *"$STRING_POLYBAR"* ]]
    then
        echo -e "\033[32mBacking up polybar\033[0m"
        mkdir "$THIS_BACKUP/polybar"
        cp -r "$LOCATION_POLYBAR" "$THIS_BACKUP/polybar"
    fi
fi

# Incinerate old configs and copy new
echo -e "Removing and copying new configurations"
if [[ "$CONFIGS" == *"$STRING_NVIM"* ]]
then
    echo -e "\033[33mRemoving nvim\033[0m"
    rm -rf "$LOCATION_NVIM"
    echo -e "\033[32mCopying new nvim\033[0m"
    cp -r "$LOCATION_DOTFILES/nvim" "$LOCATION_CONFIGS"
fi
if [[ "$CONFIGS" == *"$STRING_ZSHRC"* ]]
then
    echo -e "\033[33mRemoving zshrc\033[0m"
    rm "$LOCATION_ZSHRC"
    echo -e "\033[32mCopying new zshrc\033[0m"
    cp "$LOCATION_DOTFILES/.zshrc" "$HOME"
fi
if [[ "$CONFIGS" == *"$STRING_ALACRITTY"* ]]
then
    echo -e "\033[33mRemoving alacritty\033[0m"
    rm -rf "$LOCATION_ALACRITTY"
    echo -e "\033[32mCopying new alacritty\033[0m"
    cp -r "$LOCATION_DOTFILES/alacritty" "$LOCATION_CONFIGS"
fi
if [[ "$CONFIGS" == *"$STRING_I3"* ]]
then
    echo -e "\033[33mRemoving i3\033[0m"
    rm -rf "$LOCATION_I3"
    echo -e "\033[32mCopying new i3\033[0m"
    cp -r "$LOCATION_DOTFILES/i3" "$LOCATION_CONFIGS"
fi
if [[ "$CONFIGS" == *"$STRING_POLYBAR"* ]]
then
    echo -e "\033[33mRemoving polybar\033[0m"
    rm -rf "$LOCATION_POLYBAR"
    echo -e "\033[32mCopying new polybar\033[0m"
    cp -r "$LOCATION_DOTFILES/polybar" "$LOCATION_CONFIGS"
fi
