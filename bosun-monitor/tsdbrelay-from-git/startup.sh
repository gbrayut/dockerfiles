#!/bin/bash
set -e #exit on errors
#set -x #print commands being executed

#_exit {
  #echo 'exit trap (start cleanup)'
  #by default docker stop has a 10 second timeout, so make it quick!
#}
#trap _exit EXIT

#setup signal trap for docker stop/kill
_term() { 
    echo ''
    echo 'caught SIGTERM... forwarding to tsdbrelay' 
    pkill --echo tsdbrelay
    wait #wait for child process to exit (could use $CMDEXIT but better to wait for all jobs)
    CHILDEXIT=$?
    echo "background jobs finished with exit code $CHILDEXIT"
    exit $CHILDEXIT #Forward exit code to docker
}
trap _term SIGTERM #TODO: add other signals that are sent by docker kill command?

#echo "startup args: ${@}"
#TODO: change startup script based on arguments passed in: docker run bosun-git testing 1 2 3

gitshortlog(){
    git log --pretty=format:"%H authored %ar: %s" -1
}

#clone bosun-monitor repo
if [[ -f $BOSUNPATH/cmd/bosun/main.go ]]
then
    echo ''
    echo "Skipping git clone as $BOSUNPATH already has:"
    gitshortlog
else
    echo ''
    echo 'cloning bosun-monitor repository'
    echo "from $GITREPO $GITBRANCH"
    git clone --single-branch --branch $GITBRANCH --depth 1 $GITREPO $BOSUNPATH
    echo ''
    echo 'finished cloning:'
    gitshortlog
fi

#build tsdbrelay
echo ''
echo "building tsdbrelay in go $GOLANG_VERSION using $BOSUNPATH/build.tsdbrelay.sh"
./build.tsdbrelay.sh

#run tsdbrelay in background
echo ''
echo "running tsdbrelay using: ./cmd/tsdbrelay/tsdbrelay ${TSDBRELAY_OPTS} &"
./cmd/tsdbrelay/tsdbrelay ${TSDBRELAY_OPTS} &
CMDPID=$!

#wait for tsdbrelay to exit. Note docker signals are handled by traps above
echo -e "\nwaiting for tsdbrelay background process ID $CMDPID to exit"
wait $CMDPID
CMDEXIT=$?
echo "tsdbrelay finished with exit code $CMDEXIT"
exit $CMDEXIT #Forward exit code to docker

#TODO: see if switching to exec tsdbrelay directly has any benefits. Initial testing showed exit code 2 instead of 0