#!/bin/sh
exec >> /var/live-vm-test.txt 2>&1
sock=/run/updated.sock
user=livetest
class=$(cat /etc/live-vm-test-class)
q() { curl -s --max-time "${3:-30}" --unix-socket $sock -X "$1" "http://localhost$2"; }
field() { sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"; }
finish() {
	echo "RESULT $1"
	sync
	sleep 90
	poweroff
	exit 0
}
waitfor() {
	n=0
	while ! pidof "$1" >/dev/null && [ $n -lt "$2" ]; do
		sleep 2
		n=$((n + 2))
	done
	pidof "$1" >/dev/null
}
if [ ! -f /var/lib/sinty/.oobe-done ]; then
	echo "provision $(date -u)"
	printf '123456\n' | OOBE_USERNAME=$user OOBE_FULLNAME="Live Test" atom-firstboot
	echo "firstboot $?"
	sync
	sleep 2
	poweroff
	exit 0
fi
echo "start $(date -u) $class $(tr ' ' '\n' < /proc/cmdline | grep -E '^atom.version=')"
for _ in $(seq 180); do [ -S $sock ] && break; sleep 1; done
waitfor singularity-desktop 900 || finish "FAIL no desktop session"
sleep 20
shell0=$(pidof singularity-desktop)
labwc0=$(pidof labwc)
for _ in $(seq 60); do
	st=$(q GET /check 120)
	case "$st" in *'"state":"available"'*) break ;; esac
	sleep 10
done
echo "check: $st"
case "$st" in *'"state":"available"'*) ;; *) finish "FAIL no update offered" ;; esac
to=$(echo "$st" | field latest)
q POST "/download?token=$(echo "$st" | field consent_token)" >/dev/null
for _ in $(seq 360); do
	st=$(q GET /status)
	case "$st" in *'"state":"ready"'* | *'"state":"error"'*) break ;; esac
	sleep 5
done
echo "staged: $st"
case "$st" in *"\"class\":\"$class\""*'"eligible":true'*) ;; *) finish "FAIL not offered as $class" ;; esac
apps0=$(ps -u $user -o pid=,comm= | grep -v -e singularity-des -e torchiod | sort)
echo "waiting for the user to apply"
n=0
while ! grep -qE "^(committed|rolledback)" /run/sinty/live/log 2>/dev/null && [ $n -lt 1200 ]; do
	sleep 2
	n=$((n + 2))
done
echo "hooks:"
cat /run/sinty/live/log 2>&1
grep -q "^committed" /run/sinty/live/log 2>/dev/null || finish "FAIL the update was not applied"
grep -q "ATOM_VERSION=$to" /run/atomloops/live/identity 2>/dev/null || finish "FAIL not running $to"
waitfor singularity-desktop 900 || finish "FAIL the desktop did not come back"
sleep 30
shell1=$(pidof singularity-desktop)
labwc1=$(pidof labwc)
echo "shell $shell0 -> $shell1, labwc $labwc0 -> $labwc1"
[ "$shell1" != "$shell0" ] || finish "FAIL the shell was not restarted"
case "$class" in
reload)
	[ "$labwc1" = "$labwc0" ] || finish "FAIL the compositor restarted on a reload"
	apps1=$(ps -u $user -o pid=,comm= | grep -v -e singularity-des -e torchiod | sort)
	missing=$(printf '%s\n' "$apps0" | while IFS= read -r line; do printf '%s\n' "$apps1" | grep -qxF "$line" || printf '%s\n' "$line"; done)
	[ -z "$missing" ] || finish "FAIL processes of the session did not survive: $(echo $missing)"
	;;
relogin)
	[ "$labwc1" != "$labwc0" ] || finish "FAIL the compositor was not restarted"
	;;
esac
sleep 20
[ "$(pidof singularity-desktop)" = "$shell1" ] || finish "FAIL the shell restarted again after the update"
echo "status: $(q GET /status)"
finish PASS
