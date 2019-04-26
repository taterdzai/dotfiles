#!/usr/bin/bash
set -o pipefail;

main_menu(){
    menu_options=(
        "Packages"	"Install packs of packages"
        "Config"	"Set system settings"
        "Wallpapers"	"Download and extract wallpapers from imgur"
    );

    menu_choise="none";
    while [[ -n "$menu_choise" ]]; do

        menu_choice=$(dialog --menu "Setup machine" 15 50 40 "${menu_options[@]}" 2>&1 >/dev/tty);

        case $menu_choice in
            Packages)
                packages;
            ;;
            Config)
                config;
            ;;
            Wallpapers)
                wallpapers;
            ;;
            *)
                return 1;
            ;;
        esac;
    done;
}

packages(){
    mapfile -t package_groups < <(csv_checklist ~/.setup-files/packages.csv "Install packages");

    for (( i=0; i<${#package_groups[@]}; i++ )); do
        echo lol
    done;
}

config(){
    mapfile -t config_args < <(csv_checklist ~/.setup-files/config.csv "Configure system");

    for (( i=0; i<${#config_args[@]}; i++ )); do
        dsudo "cp ${config_args[i]}";
    done;

    if [[ -n "${config_args[@]}" ]]; then
        dialog --pause "Configuration complete" 8 50 3;
    fi

    return 0;
}

wallpapers(){
    temp_dir=$(mktemp -d);
    trap "rm -rf $temp_dir" INT TERM HUP EXIT;

    if { {
        echo "Trying to download archive with images";
        try=0;
        tries=10;
        sleep_time=5s;
        while [[ $try -lt $tries ]]; do
           if {
               wget -q --show-progress --progress=bar:force:noscroll \
                    -O "$temp_dir/wallpapers.zip" "https://imgur.com/a/mrb6YtD/zip" \
                    --referer "https://imgur.com/a/mrb6YtD" \
                    -U "Mozilla/5.0 (X11; Linux x86_64; rv:66.0) Gecko/20100101 Firefox/66.0" \
                    2>&1 >/dev/null |
                    stdbuf -o0 awk 'BEGIN { RS = "\r" } \
                         { mtch = match($0, "[0-9]+\.[0-9]+.B/s"); \
                           if (mtch != 0) { \
                               subs=substr($0, mtch); \
                               gsub("\n", "", subs); \
                               printf("Download speed: %s\n", subs); \
                           } \
                         }' 2>/dev/null;
            } then
                break;
            else
                echo "Attempt #$((++try))/$tries failed. Sleep for $sleep_time";
                sleep $sleep_time;
            fi;
        done;
        if [[ $try -eq $tries ]]; then
            exit 1;
        fi;
    } | dialog --progressbox 3 50 2>&1 >/dev/tty; } then
        mkdir -p ~/.wallpaper;
        rm -rf ~/.wallpaper/*;
        unzip -qq $temp_dir/wallpapers.zip -d ~/.wallpaper;
        dialog --pause "Download complete" 8 50 3;
        return 0;
    else
        dialog --pause "Download failed" 8 50 3;
        return 1;
    fi
}

dsudo(){
    if sudo -nl &>/dev/null; then
        sudo -E sh -c "eval $@";
    else
        dialog --clear --insecure --passwordbox "$USER's password:" 10 50 2>&1 >/dev/tty |
        sudo -E -p "" -S sh -c "eval $@";
    fi
}

csv_checklist(){
    mapfile -t options < <(cut -d ',' --output-delimiter $'\n' -f 1-3 <$1);
    dialog --separate-output --checklist "$2" 20 90 40 "${options[@]}" 2>&1 >/dev/tty |
    while read choice; do
         sed -n "/$choice/ p" <$1 | cut -d ',' --output-delimiter ' ' -f 4-;
    done;
}

csv_package_group(){
    cut -d ',' --output-delimiter ' ' -f 1- <$1 | {
        while read package manager description; do
            case $manager in
                pacman)
                    echo "pacman: $package; $description"
                ;;
                aur)
                    echo "yay: $package; $description"
                ;;
            esac;
        done;
    }
}

main_menu
clear
