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
    echo 'caught SIGTERM... forwarding to bosun main' 
    pkill --echo main #Can't use $CMDEXIT as that is the pid for go not bosun
    wait #wait for child process to exit (could use $CMDEXIT but better to wait for all jobs)
    CHILDEXIT=$?
    echo "background jobs finished with exit code $CHILDEXIT"
    exit $CHILDEXIT #Forward exit code to docker
}
trap _term SIGTERM #TODO: add other signals that are sent by docker kill command?

#echo "startup args: ${@}"
#TODO: change startup script based on arguments passed in: docker run bosun-git testing 1 2 3

#clone bosun-monitor repo
if [[ -f $BOSUNPATH/cmd/bosun/main.go ]]
then
    echo ''
    echo -e "Skipping git clone as $BOSUNPATH already has: \n$(git log --pretty=format:"%H authored %ar: %s" -1)"
else
    echo ''
    echo 'cloning bosun-monitor repository'
    echo "from $GITREPO $GITBRANCH"
    git clone --single-branch --branch $GITBRANCH --depth 1 $GITREPO $BOSUNPATH
    echo ''
    echo -e "finished cloning:\n$($(git log --pretty=format:\"%H authored %ar: %s\" -1))"
fi

#run bosun in background
echo ''
echo "running bosun in go $GOLANG_VERSION using: go run main.go -w -dev -q -c /data/bosun.toml &"
cd cmd/bosun
go run main.go -w -dev -q -c /data/bosun.toml &
CMDPID=$!

#wait for bosun to exit. Note docker signals are handled by traps above
echo -e "\nwaiting for bosun background process ID $CMDPID to exit"
wait $CMDPID
CMDEXIT=$?
echo "bosun finished with exit code $CMDEXIT"
exit $CMDEXIT #Forward exit code to docker