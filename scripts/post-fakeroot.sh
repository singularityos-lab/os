#!/bin/sh
set -eu
TARGET="${1:?usage: post-fakeroot.sh <target-dir>}"

for d in usr/bin usr/sbin; do
	find "$TARGET/$d" -maxdepth 1 -type l | while read -r l; do
		case "$(readlink "$l")" in
		busybox | */busybox) rm -f "$l" ;;
		esac
	done
done
rm -f "$TARGET/usr/bin/busybox" "$TARGET/linuxrc"
for l in dbclient dropbearconvert dropbearkey scp; do
	[ -L "$TARGET/usr/bin/$l" ] && [ "$(readlink "$TARGET/usr/bin/$l")" = ../sbin/dropbear ] && [ ! -e "$TARGET/usr/sbin/dropbear" ] && rm -f "$TARGET/usr/bin/$l"
done

ln -sf sinty-sh "$TARGET/usr/bin/sh"
for c in kill uptime hostname more; do
	ln -sf coreutils "$TARGET/usr/bin/$c"
done
for c in poweroff reboot halt; do
	ln -sf /usr/lib/sinit/sinit "$TARGET/usr/sbin/$c"
done
printf '/usr/bin/ush\n/usr/bin/dsh\n/bin/sh\n/usr/bin/sh\n/bin/bash\n/usr/bin/bash\n' > "$TARGET/etc/shells"

fail=0
for need in sh test [ cat ls grep sed awk find xargs tar gzip ps kill mount umount; do
	if [ ! -x "$TARGET/usr/bin/$need" ] && [ ! -x "$TARGET/usr/sbin/$need" ]; then
		echo "post-fakeroot: missing $need" >&2
		fail=1
	fi
done
for d in usr/bin usr/sbin; do
	for l in "$TARGET/$d"/*; do
		if [ -L "$l" ] && [ ! -e "$l" ]; then
			case "$(readlink "$l")" in
			/*) [ -e "$TARGET$(readlink "$l")" ] && continue ;;
			esac
			echo "post-fakeroot: dangling $l" >&2
		fi
	done
done
exit $fail
