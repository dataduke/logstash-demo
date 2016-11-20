#!/bin/bash


unset GIT_COMMIT_ID
unset EXPECTED_BRANCH
unset TARGET_BRANCH
unset GIT_REMOTE_URL


### Functions ###

usage() {
  cat << USAGE_END
  Usage: $0 options

Utility script for merging a branch to another branch, pushing the
result to a remote and doing checks along the way.

It's main purpose is to assist in propagating repo changes when using
CI environments, e.g., CircleCI.

OPTIONS:
   -c   The commit id you want to merge into the target branch. In case
        it exists there already, we do nothing.
        Example: <A Git commit id.>
   -e   The branch you expect to be tested in your CI/CD environment. If
        set we exit with an error in case the current branch if the Git
        repo *differs*.
        Example: dev
   -t   The target branch you want to merge to.
        Example: master
   -r   The remote you want to push to after a successful merge. We
        don't push anything, if this is not set. The target branch you define
        will be used as remote target branch as well.
   -h   Show this message.
   -?   Show this message.
USAGE_END
}


### Flow ###

# Command-line arguments.
while getopts "c: e: t: r: h ?" option ; do
  case $option in
    c ) GIT_COMMIT_ID="${OPTARG}"
        ;;
    e ) EXPECTED_BRANCH="${OPTARG}"
        ;;
    t ) TARGET_BRANCH="${OPTARG}"
        ;;
    r ) GIT_REMOTE_URL="${OPTARG}"
        ;;
    h ) usage
        exit 0;;
    ? ) usage
        exit 0;;
    esac
done

# Basic checks.
GIT=
which git > /dev/null 2>&1
if [[ $? -ne 0 ]] ; then
  echo 'Cannot find executable git.'
  exit 1
else
  GIT=$(which git)
fi

if [[ -z "${GIT_COMMIT_ID}" ]] ; then
  echo 'No commit id given.'
  exit 1
fi

# Right now we support CircleCI only.
#
# Test, if we're running in CircleCI environment.
if [[ -z "${CIRCLECI}" || "${CIRCLECI}" != 'true' ]] ; then
  echo 'Not running in CircelCI environment. We only support CircleCI currently.'
  exit 1
fi

# If the branch being tested is not 'dev', we exit immediately.
if [[ -z "${CIRCLE_BRANCH}" || "${CIRCLE_BRANCH}" != "${EXPECTED_BRANCH}" ]] ; then
  echo "Merge to ${TARGET_BRANCH} is allowed only, if running on ${EXPECTED_BRANCH}."
  exit 1
fi

# Merge to target branch and push to remote in case it has been requested.
echo "Switching to target branch ${TARGET_BRANCH}..."
${GIT} checkout "${TARGET_BRANCH}" || exit 1
# We only need to merge and push, if the local target branch is not on the
# commit we are about to merge.
echo "Checking, if we can skip the merge (and push), b/c local target branch already has the commit..."
${GIT} log -n1 --pretty=oneline | awk '{ print $1 }' | grep -q "${GIT_COMMIT_ID}"
if [[ "$?" -eq 1 ]] ; then
  echo "Merging commit ${GIT_COMMIT_ID} onto ${TARGET_BRANCH}..."
  ${GIT} merge "${GIT_COMMIT_ID}" || exit 1
  if [[ -n "${GIT_REMOTE_URL}" ]] ; then
    echo 'Pushing local branch to remote ${GIT_REMOTE_URL}...'
    ${GIT} push "${GIT_REMOTE_URL}" "${TARGET_BRANCH}:${TARGET_BRANCH}" || exit 1
  fi
fi
