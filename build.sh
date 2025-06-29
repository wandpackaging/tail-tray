#!/bin/bash

set -euo pipefail

set -x

sudo apt-get update
sudo apt-get -y install binutils curl jq

git_tag="$(cd tail-tray && git describe --tags --match "v*")"

github_api_url="https://api.github.com/repos/SneWs/tail-tray/releases/tags/${git_tag}"

package_path="${GITHUB_WORKSPACE}/packages/"
mkdir -p "${package_path}"

mapfile -t deb_files < <(curl -1sLf "${github_api_url}" 2>/dev/null |
    jq -r '.assets[] | select(.name | endswith(".deb")) | [.name, .browser_download_url] | @sh')

for deb_file in "${deb_files[@]}"; do
    pkg_filename=$(echo "${deb_file}" | awk '{print $1}' | xargs)
    pkg_url=$(echo "${deb_file}" | awk '{print $2}' | xargs)

    curl -1sLf "${pkg_url}" -o "${GITHUB_WORKSPACE}/${pkg_filename}"

    case "${pkg_filename}" in
    *debian*)
        release="$(echo "${pkg_filename}" | grep -Eo "debian-([^0-9]+)" | cut -d '-' -f 2)"
        mkdir "${package_path}/debian_${release}"
        cp "${GITHUB_WORKSPACE}/${pkg_filename}" "${package_path}/debian_${release}/${pkg_filename}"
        ;;
    *ubuntu*)
        release="$(echo "${pkg_filename}" | grep -Eo "ubuntu-[0-9\.]+-([^0-9]+)" | cut -d '-' -f 3)"
        mkdir "${package_path}/ubuntu_${release}"
        cp "${GITHUB_WORKSPACE}/${pkg_filename}" "${package_path}/ubuntu_${release}/${pkg_filename}"
        ;;
    esac

    rm "${GITHUB_WORKSPACE}/${pkg_filename}"
done
