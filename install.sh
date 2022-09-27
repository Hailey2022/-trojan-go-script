#!/bin/bash

check_if_running_as_root() {
    if [[ "$UID" -ne '0' ]]; then
        echo "error: You must run this script as root!"
        exit 1
    fi
}

check_the_os_and_architecture() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
        'i386' | 'i686')
            ARCH='386'
            ;;
        'amd64' | 'x86_64')
            ARCH='amd64'
            ;;
        'armv5tel')
            ARCH='armv5'
            ;;
        'armv6l')
            ARCH='armv6'
            ;;
        'armv7' | 'armv7l')
            ARCH='armv7'
            ;;
        'armv8' | 'aarch64')
            ARCH='armv8'
            ;;
        'mips')
            ARCH='mips-hardfloat'
            ;;
        'mipsle')
            ARCH='mipsle-hardfloat'
            ;;
        'mips64')
            ARCH='mips64'
            ;;
        'mips64le')
            ARCH='mips64le'
            ;;
        *)
            echo "error: The architecture is not supported."
            exit 1
            ;;
        esac

        if [[ ! -f '/etc/os-release' ]]; then
            echo "error: Don't use outdated Linux distributions."
            exit 1
        fi

        if [[ -z "$(ls -l /sbin/init | grep systemd)" ]]; then
            echo "error: Only Linux distributions using systemd are supported."
            exit 1
        fi

        if [[ "$(command -v apt)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='apt install -y'
            PACKAGE_MANAGEMENT_REMOVE='apt remove -y'
        elif [[ "$(command -v yum)" ]]; then
            PACKAGE_MANAGEMENT_INSTALL='yum install -y'
            PACKAGE_MANAGEMENT_REMOVE='yum remove -y'
        # elif [[ "$(command -v pacman)" ]]; then
        #     PACKAGE_MANAGEMENT_INSTALL='pacman -S --noconfirm'
        #     PACKAGE_MANAGEMENT_REMOVE='pacman -R --noconfirm'
        # elif [[ "$(command -v zypper)" ]]; then
        #     PACKAGE_MANAGEMENT_INSTALL='zypper install'
        #     PACKAGE_MANAGEMENT_REMOVE='zypper remove'
        # elif [[ "$(command -v dnf)" ]]; then
        #     PACKAGE_MANAGEMENT_INSTALL='dnf install'
        #     PACKAGE_MANAGEMENT_REMOVE='dnf remove'
        else
            echo "error: The script does not support the package manager in this operating system."
            exit 1
        fi
    else
        echo "error: This operating system is not supported."
        exit 1
    fi
}

install_necessary_package() {
    $PACKAGE_MANAGEMENT_INSTALL curl unzip
}

install_trojan_go() {
    link="https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-${ARCH}.zip"
    mkdir -p "/etc/trojan-go"
    cd $(mktemp -d)
    curl -fsSL $link -o bin.zip
    unzip bin.zip && rm bin.zip
    mv trojan-go /usr/bin/trojan-go && chmod +x /usr/bin/trojan-go
    mv geoip.dat /etc/trojan-go/geoip.dat
    mv geosite.dat /etc/trojan-go/geosite.dat
    mv example/trojan-go.service /etc/systemd/system/trojan-go.service
    if [ ! -f "/etc/trojan-go/config.json" ]; then
        mv example/server.json /etc/trojan-go/config.json
    fi
    systemctl daemon-reload
    systemctl reset-failed
    echo "trojan-go is installed."
    echo "please edit /etc/trojan-go/config.json"
    echo "systemctl start trojan-go"
    echo "systemctl enable trojan-go"
}

main() {
    check_if_running_as_root
    check_the_os_and_architecture
    install_necessary_package
    install_trojan_go
}

main "$@"
