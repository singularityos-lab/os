#!/bin/sh
exec >> /var/log/live-vm-test.txt 2>&1
sock=/run/updated.sock
q() { curl -s --max-time "${3:-30}" --unix-socket $sock -X "$1" "http://localhost$2"; }
field() { sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"; }
finish() {
	echo "RESULT $1"
	sync
	sleep 2
	poweroff
	exit 0
}
echo "start $(date -u) $(tr ' ' '\n' < /proc/cmdline | grep -E '^(sing.roothash|atom.version)=' | tr '\n' ' ')"
for _ in $(seq 180); do [ -S $sock ] && break; sleep 1; done
for _ in $(seq 60); do
	st=$(q GET /check 120)
	case "$st" in *'"state":"available"'*) break ;; esac
	sleep 10
done
echo "check: $st"
case "$st" in *'"state":"available"'*) ;; *) finish "FAIL no update offered" ;; esac
to=$(echo "$st" | field latest)
echo "download: $(q POST "/download?token=$(echo "$st" | field consent_token)")"
for _ in $(seq 360); do
	st=$(q GET /status)
	case "$st" in *'"state":"ready"'* | *'"state":"error"'*) break ;; esac
	sleep 5
done
echo "staged: $st"
case "$st" in *'"eligible":true'*) ;; *) finish "FAIL not offered live" ;; esac
res=$(q POST /apply-live 300)
echo "apply-live: $res"
sleep 3
echo "hooks:"
cat /run/sinty/live/log 2>&1
echo "identity: $(cat /run/atomloops/live/identity 2>&1)"
after=$(q GET /status)
echo "status: $after"
echo "mapper: $(ls /dev/mapper | tr '\n' ' ')"
case "$res" in *'"rolled_back":true'* | *'"error"'*) finish "FAIL apply-live: $res" ;; esac
grep -q "ATOM_VERSION=$to" /run/atomloops/live/identity 2>/dev/null || finish "FAIL not running $to"
grep -q "^committed" /run/sinty/live/log 2>/dev/null || finish "FAIL hooks did not commit"
case "$after" in *"\"current\":\"$to\""*) ;; *) finish "FAIL update service still reports the old release" ;; esac
finish PASS
