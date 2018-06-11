#!/bin/bash

# This script consolidates the history (commits) of a git repository by
# squashing commits older than the specified age into a new starting commit
# and then restoring subsequent commits from that point forward.

DRY_RUN=false
QUIET_FLAG=
MAX_AGE='1 month'
FREQUENCY='1 week'
REPO_DIR=_publish

while getopts 'dqa:f:D:' option; do
  case $option in
    d) DRY_RUN=true ;;
    q) QUIET_FLAG="--quiet" ;;
    a) MAX_AGE="$OPTARG" ;;
    f) FREQUENCY="$OPTARG" ;;
    D) REPO_DIR="$OPTARG" ;;
  esac
done

cd $REPO_DIR

# NOTE using the GitHub API would allow us to start with a shallow repository
# UNTIL_PARAM_VAL="$MAX_AGE $FREQUENCY"
# UNTIL_PARAM_VAL=${UNTIL_PARAM_VAL// /%20}
# if [ "0" == `curl -s https://api.github.com/repos/mulesoft/mulesoft-docs-build-output/commits?until=$UNTIL_PARAM_VAL -H "Accept: application/vnd.github.json" | grep -c sha` ]; then
#   echo 'No commits to consolidate.'
#   exit 0
# elif [ -f .git/shallow ]; then
#   git fetch --unshallow
# fi

# use schmitt trigger so script only runs every so often
if [ -z `git log -n1 --format=%H --until "$MAX_AGE $FREQUENCY"` ]; then
  echo 'No commits to consolidate.'
  exit 0
fi

GRAFT_COMMIT=`git log -n1 --format=%H --until "$MAX_AGE"`

echo "Consolidating history of publish repository until $GRAFT_COMMIT..."

echo $GRAFT_COMMIT > .git/info/grafts

if [ -z "$QUIET_FLAG" ]; then
  git filter-branch -f --msg-filter "
    if [ \$GIT_COMMIT == $GRAFT_COMMIT ]; then
      echo 'consolidate history'
    else
      cat
    fi"
else
  git filter-branch -f --msg-filter "
    if [ \$GIT_COMMIT == $GRAFT_COMMIT ]; then
      echo 'consolidate history'
    else
      cat
    fi" > /dev/null
fi
rm -f .git/info/grafts

git reflog expire --expire=now --all
git gc $QUIET_FLAG --prune=now
# TODO could check for BUILD_ID environment variable instead
if [ "$DRY_RUN" == "false" ]; then
  git push $QUIET_FLAG --force origin master
  # NOTE if the push fails, remove the clone as it's now stale
  if [ $? -ne 0 ]; then
    cd ..
    rm -rf $REPO_DIR
  fi
fi

echo 'Consolidation complete.'

exit 0
