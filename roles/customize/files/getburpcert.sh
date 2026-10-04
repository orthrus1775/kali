#!/bin/bash
JAR="/usr/share/burpsuite/burpsuite.jar"
CERT="/tmp/cacert.der"

if [[ ! -f "$JAR" ]]; then
  echo "Burp jar not found: $JAR" >&2
  exit 1
fi

JAVA="$(command -v java || true)"
if [[ -z "$JAVA" ]]; then
  JAVA="$(ls -1 /usr/lib/jvm/*/bin/java 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$JAVA" || ! -x "$JAVA" ]]; then
  echo "No java binary found on PATH or under /usr/lib/jvm" >&2
  exit 1
fi

"$JAVA" -Djava.awt.headless=true -jar "$JAR" < <(echo y) &
sleep 20

counter=0
while [[ $counter -lt 5 ]]; do
  if [[ -s "$CERT" ]]; then
    exit 0
  fi
  curl -fsS http://localhost:8080/cert -o "$CERT" && exit 0
  counter=$((counter + 1))
  sleep 10
done

exit 1
