#!/bin/bash

# Path Trash for users
TRASH_PATHS=("/home" "/root")
EXCLUDE_USERS=()

L_MODE=0
USER_FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lld)
            L_MODE=1
            shift
            ;;
        --user)
            USER_FILTER="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

data=()

for base in "${TRASH_PATHS[@]}"; do
    if [ "$base" = "/home" ]; then
        for userdir in "$base"/*; do
            [ -d "$userdir" ] || continue
            user=$(basename "$userdir")
            trash="$userdir/.local/share/Trash/files"
            [ -d "$trash" ] || continue
            size=$(du -sb "$trash" 2>/dev/null | cut -f1)
            [ -z "$size" ] && size=0
            key="${user// /_}"
            data+=("$key:$size")
        done
    else
        # root
        user="root"
        trash="/root/.local/share/Trash/files"
        if [ -d "$trash" ]; then
            size=$(du -sb "$trash" 2>/dev/null | cut -f1)
            [ -z "$size" ] && size=0
            key="${user// /_}"
            data+=("$key:$size")
        fi
    fi
done

if [ $L_MODE -eq 1 ]; then
    echo -n '{"data":['
    first=1
    for entry in "${data[@]}"; do
        key="${entry%%:*}"
        # applica filtro utenti se specificato
        if [[ -n "$USER_FILTER" && "$key" != "$USER_FILTER" ]]; then
            continue
        fi
        if [ $first -eq 1 ]; then
            first=0
        else
            echo -n ","
        fi
        echo -n "{\"{#USERNAME}\":\"$key\"}"
    done
    echo ']}'
else
    if [ -n "$USER_FILTER" ]; then
        for entry in "${data[@]}"; do
            key="${entry%%:*}"
            value="${entry##*:}"
            if [ "$key" = "$USER_FILTER" ]; then
                echo "$value"
                exit 0
            fi
        done
        echo 0
    else
        echo -n '{"data":['
        first=1
        for entry in "${data[@]}"; do
            key="${entry%%:*}"
            if [ $first -eq 1 ]; then
                first=0
            else
                echo -n ","
            fi
            echo -n "{\"{#USERNAME}\":\"$key\"}"
        done
        echo ']}'
    fi
fi
