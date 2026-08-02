#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
pam_file="$repo_dir/rootfs-overlay/etc/pam.d/greetd"
post_build="$repo_dir/scripts/post-build.sh"

auth_line="$(grep -n -F 'auth       required   pam_sinty.so' "$pam_file" | cut -d: -f1)"
root_account_line="$(grep -n -F 'account    sufficient pam_succeed_if.so user = root' "$pam_file" | cut -d: -f1)"
sinty_account_line="$(grep -n -F 'account    required   pam_sinty.so' "$pam_file" | cut -d: -f1)"
unix_account_line="$(grep -n -F 'account    required   pam_unix.so' "$pam_file" | cut -d: -f1)"

[ "$auth_line" -lt "$root_account_line" ]
[ "$root_account_line" -lt "$sinty_account_line" ]
[ "$sinty_account_line" -lt "$unix_account_line" ]
[ "$(grep -c -F 'pam_succeed_if.so user = root' "$pam_file")" -eq 1 ]

grep -Fq 'if [ "${ATOM_BUILD:-}" = "rc" ]; then' "$post_build"
grep -Fq "sed -i 's/^root:[^:]*:/root:!:/' \"\$TARGET_DIR/etc/shadow\"" "$post_build"

echo "release login policy: ok"
