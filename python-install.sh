#!/usr/bin/env sh

# This script installs a specific version of Python 3.x.x.
# Copyright (c) 2023 Glizzy

# Licensed under the MIT License. You may obtain a copy of the License at
# https://opensource.org/licenses/MIT

# Usage:
# Run as root: sh python-install.sh 3.11.0
# Or via GitHub: wget -qO - https://raw.githubusercontent.com/Glizzykingdreko/python-install/main/python-install.sh | sh -s 3.10.0

set -euo pipefail

install_python_version() {
    version="$1"
    main_version=${version%.*}
    file="Python-${version}.tar.xz"
    url="https://www.python.org/ftp/python/${version}/${file}"

    old_version=$(command -v python > /dev/null && python -c 'import platform; print(platform.python_version())' || echo "0")

    if [ "$(printf '%s\n' "$version" "$old_version" | sort -V | head -n1)" = "$version" ]; then
        echo "Attempting to install an older Python version. Exiting..."
        exit 1
    fi

    echo "Current Python version: ${old_version}"

    echo "Updating system packages"
    apt update -qq && apt upgrade -y --allow-change-held-packages

    echo "Installing build dependencies"
    apt install -qq -y wget build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev

    echo "Downloading Python ${version}"
    wget -q "${url}"

    echo "Unpacking Python source"
    tar -xf "${file}"

    cd "Python-${version}"

    echo "Building Python from source"
    ./configure --enable-optimizations --prefix=/usr
    make -j "$(nproc)"

    echo "Installing Python ${version}"
    make altinstall -j "$(nproc)"

    echo "Cleaning up"
    cd ..
    rm -rf "Python-${version}"
    rm "${file}"

    echo "Installing pip"
    apt install -qq -y python3-pip

    echo "Updating pip"
    python"${main_version}" -m pip install --upgrade pip

    update-alternatives --install /usr/bin/python python /usr/bin/python"${main_version}" 1
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python"${main_version}" 1

    echo "Installed Python ${version}"
    echo "Check the version: python --version"
}

if [ -z "$1" ]; then
    echo "Please provide a Python version (e.g., 3.10.0)"
    echo "sh python-install.sh 3.10.0"
else
    install_python_version "$1"
fi