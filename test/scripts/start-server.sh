#!/bin/bash

set -v

echo $CWD
. test/scripts/version.sh
ARCHIVE="${KEYCLOAK}.tar.gz"
URL="http://downloads.jboss.org/keycloak/${VERSION}/${ARCHIVE}"

# Download keycloak server if we don't already have it
if [ ! -e $KEYCLOAK ]
then
  wget $URL
  tar xvzf $ARCHIVE
fi

# Start the server
${KEYCLOAK}/bin/standalone.sh > keycloak.log 2>&1 &

# Save the PID so we can kill it scriptually later
PID=$!
echo "Server PID $PID"
echo $PID | cat > keycloak.pid

# Give the server some time to start up. Look for a well-known
# bit of text in the log file. Try at most 50 times before giving up.
C=50
while [ $C -gt 0 ]
do
  grep "Undertow HTTP listener default listening" keycloak.log
  FOUND=$?
  if [ $FOUND -eq 0 ]; then
    echo "Server started."
    C=0
  else
    echo -n "${C}."
    C=$(( $C - 1 ))
  fi
  sleep 1
done

# Try to add an initial admin user, so we can test against
# the server and not get automatically redirected.
${KEYCLOAK}/bin/add-user.sh -r master -u admin -p admin