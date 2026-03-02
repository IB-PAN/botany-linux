#!/usr/bin/bash
set -euo pipefail

pdnf() {
    flock /tmp/dnf5.lock dnf5 -y "$@"
}

copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    repo_id_fragment="${copr_name//\//:}"
    repo_id_fragment="${repo_id_fragment//@/group_}"
    repo_id="copr:copr.fedorainfracloud.org:${repo_id_fragment}"

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    pdnf copr enable "$copr_name"
    pdnf copr disable "$copr_name"
    pdnf install --from-repo="$repo_id" "${packages[@]}"

    echo "Installed ${packages[*]} from $copr_name"
}

thirdparty_repo_install() {
    local repo_name="$1"
    local repo_frompath="$2"
    local release_package="$3"
    local extras_package="${4:-}"
    local disable_pattern="${5:-$repo_name}"

    echo "Installing $repo_name repo (isolated mode)"

    # Install the release package using temporary repo
    # shellcheck disable=SC2016
    pdnf install --nogpgcheck --repofrompath "$repo_frompath" "$release_package"

    # Install extras package if specified (may not exist in all versions)
    if [[ -n "$extras_package" ]]; then
        pdnf install "$extras_package" || true
    fi

    # Disable the repo(s) immediately
    pdnf config-manager setopt "${disable_pattern}".enabled=0

    echo "$repo_name repo installed and disabled (ready for isolated usage)"
}

run_parallel() {
    # https://stackoverflow.com/questions/66119741/time-stamping-every-line-of-stdout
    # needs packages: moreutils, parallel
    parallel --no-notice --jobs 0 --halt-on-error now,fail=1 --color-failed "set -o pipefail ; echo '::group::==={}===' && stdbuf -oL bash -c {} 2>&1 | ts -s -m '%.s' && echo -e '===END===\n::endgroup::'" ::: "$@"
}

pdnf_install_rpm() {
    URL="$1"
    #shift
    #OPTIONS=("$@")
    pushd /tmp
    echo "[pdnf_install_rpm] Downloading ${URL}..."
    RPM_FILENAME=$(curl --no-progress-meter --retry 3 -OJL "$URL" -w "%{filename_effective}")
    echo "[pdnf_install_rpm] Installing ${RPM_FILENAME}..."
    pdnf install --nogpgcheck "$RPM_FILENAME"
    echo "[pdnf_install_rpm] Done."
    rm -f "$RPM_FILENAME"
    popd
}

pdnf_install_rpm_checksig() {
    URL="$1"
    pushd /tmp
    echo "[pdnf_install_rpm_checksig] Downloading ${URL}..."
    RPM_FILENAME=$(curl --no-progress-meter --retry 3 -OJL "$URL" -w "%{filename_effective}")
    echo "[pdnf_install_rpm_checksig] Checking signature of ${RPM_FILENAME}..."
    rpm --checksig "$RPM_FILENAME"
    echo "[pdnf_install_rpm_checksig] Installing ${RPM_FILENAME}..."
    pdnf install "$RPM_FILENAME"
    echo "[pdnf_install_rpm_checksig] Done."
    rm -f "$RPM_FILENAME"
    popd
}
