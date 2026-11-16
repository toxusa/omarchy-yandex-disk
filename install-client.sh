#!/usr/bin/env bash

finish() {
    local result="$1"
    printf '\n'
    read -r -p "Press Enter to close..."
    exit "$result"
}

printf 'Yandex Disk client installation\n\n'
printf 'This installs yandex-disk from the AUR using yay.\n'
printf 'Account setup and daemon startup are not performed.\n\n'

if (( EUID == 0 )); then
    printf 'Error: run this installer as a regular user, not root.\n' >&2
    finish 1
fi

if command -v yandex-disk >/dev/null 2>&1; then
    printf 'The yandex-disk client is already installed.\n'
    finish 0
fi

if ! command -v yay >/dev/null 2>&1; then
    printf 'Error: yay was not found. Install the client manually.\n' >&2
    finish 1
fi

read -r -p "Install yandex-disk from the AUR? [y/N] " answer
case "$answer" in
    y|Y) ;;
    *)
        printf '\nInstallation cancelled.\n'
        finish 0
        ;;
esac

yay -S --needed aur/yandex-disk
result=$?

if (( result != 0 )); then
    printf '\nInstallation failed or was cancelled (exit code %s).\n' "$result" >&2
    finish "$result"
fi

if ! command -v yandex-disk >/dev/null 2>&1; then
    printf '\nError: installation finished, but yandex-disk was not found.\n' >&2
    finish 1
fi

printf '\nYandex Disk client installed.\n'
printf 'Configure your account separately before starting synchronization.\n'
finish 0
