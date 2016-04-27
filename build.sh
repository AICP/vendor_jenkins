#!/bin/bash

function check_result {
  if [ "0" -ne "$?" ]
  then
    (repo forall -c "git reset --hard") >/dev/null
    echo $1
    exit 1
  fi
}

if [ -z "$HOME" ]
then
  echo HOME not in environment, guessing...
  export HOME=$(awk -F: -v v="$USER" '{if ($1==v) print $6}' /etc/passwd)
fi

if [ -z "$WORKSPACE" ]
then
  echo WORKSPACE not specified
  exit 1
fi

if [ -z "$CLEAN" ]
then
  echo CLEAN not specified
  exit 1
fi

if [ -z "$REPO_BRANCH" ]
then
  echo REPO_BRANCH not specified
  exit 1
fi

if [ -z "$LUNCH" ]
then
  echo LUNCH not specified
  exit 1
fi

if [ -z "$RELEASE_TYPE" ]
then
  echo RELEASE_TYPE not specified
  #exit 1
fi

if [ -z "$SYNC" ]
then
  echo SYNC not specified
  exit 1
fi

if [ -z "$CONNECTIONS" ]
then
  CONNECTIONS=4
fi

if [ -z "$SYNC_PROTO" ]
then
  SYNC_PROTO=http
fi

# remove non-core repos
rm -fr kernel/
rm -fr device/lge/
rm -fr device/samsung/
rm -fr vendor/lge/
rm -fr vendor/samsung/

# remove manifests
rm -f .repo/local_manifests/aicp*.xml


# colorization fix in Jenkins
export CL_RED="\"\033[31m\""
export CL_GRN="\"\033[32m\""
export CL_YLW="\"\033[33m\""
export CL_BLU="\"\033[34m\""
export CL_MAG="\"\033[35m\""
export CL_CYN="\"\033[36m\""
export CL_RST="\"\033[0m\""

export TERM=xterm

cd $WORKSPACE/$REPO_BRANCH

rm -rf archive
mkdir -p archive

if [ ! -d "CHANGELOGS" ]; then
  mkdir CHANGELOGS
fi
export BUILD_NO=$BUILD_NUMBER
unset BUILD_NUMBER

export USE_CCACHE=1
export CCACHE_NLEVELS=4
export BUILD_WITH_COLORS=1

# make sure ccache is in PATH
export PATH="$PATH:$PWD/prebuilts/misc/linux-x86/ccache"
export CCACHE_DIR=/Development/cache

if [ -f ~/.profile ]
then
  . ~/.profile
fi

  LAST_SYNC=0
if [ -f .sync ]
  then
  LAST_SYNC=$(date -r .sync +%s)
fi
  TIME_SINCE_LAST_SYNC=$(expr $(date +%s) - $LAST_SYNC)
  #convert this to hours
  TIME_SINCE_LAST_SYNC=$(expr $TIME_SINCE_LAST_SYNC / 60 / 60)
if [ $TIME_SINCE_LAST_SYNC -gt "20" -o $SYNC = "true" ]
  then
  echo "Syncing..."
  repo sync -d -c -j $CONNECTIONS -f --force-sync > /dev/null
  check_result "repo sync failed."
  echo "Sync complete."
  touch .sync
else
  echo "Skipping Sync: $TIME_SINCE_LAST_SYNC hours since last sync."
fi

#
LAST_CLEAN=0
if [ -f .clean ]
  then
  LAST_CLEAN=$(date -r .clean +%s)
fi
  TIME_SINCE_LAST_CLEAN=$(expr $(date +%s) - $LAST_CLEAN)
  # convert this to hours
  TIME_SINCE_LAST_CLEAN=$(expr $TIME_SINCE_LAST_CLEAN / 60 / 60)
if [ $TIME_SINCE_LAST_CLEAN -gt "20" -o $CLEAN = "true" ]
  then
  echo "Cleaning!"
  touch .clean
  make clobber
else
  echo "Skipping clean: $TIME_SINCE_LAST_CLEAN hours since last clean."
fi
#

if [ -f .last_branch ]
then
  LAST_BRANCH=$(cat .last_branch)
else
  echo "Last build branch is unknown, assume clean build"
  LAST_BRANCH=$REPO_BRANCH
fi

if [ "$LAST_BRANCH" != "$REPO_BRANCH" ]
then
  echo "Branch has changed since the last build happened here. Forcing cleanup."
  CLEAN=true
fi

. build/envsetup.sh

breakfast $LUNCH
lunch $LUNCH
check_result "lunch failed."

UNAME=$(uname)

if [ "$RELEASE_TYPE" = "AICP_NIGHTLY" ]
then
  export AICP_NIGHTLY=true
  echo "Creating NIGHTLY Changelog."
  if [ ! -f .lsync_$LUNCH-NIGHTLY ]; then
      #First Timer Give 15 days Logs
  touch -t `date --date='15 days ago' '+%Y%m%d0000'` .lsync_$LUNCH-NIGHTLY
  fi
  LAST_SYNC=$(date -r .lsync_$LUNCH-NIGHTLY +%s)
  WORKSPACE=$WORKSPACE LUNCH=$LUNCH bash $WORKSPACE/$REPO_BRANCH/jenkins/changes/buildlog.sh $LAST_SYNC 2>&1
  touch .lsync_$LUNCH-NIGHTLY
  echo "NIGHTLY Changelog created."

elif [ "$RELEASE_TYPE" = "AICP_RELEASE" ]
then
  export "AICP_RELEASE"=true
  echo "Creating RELEASE Changelog."
  if [ ! -f .lsync_$LUNCH-RELEASE ]; then
      #First Timer Give 30 days Logs
  touch -t `date --date='30 days ago' '+%Y%m%d0000'` .lsync_$LUNCH-RELEASE
  fi
  LAST_SYNC=$(date -r .lsync_$LUNCH-RELEASE +%s)
  WORKSPACE=$WORKSPACE LUNCH=$LUNCH bash $WORKSPACE/$REPO_BRANCH/jenkins/changes/buildlog.sh $LAST_SYNC 2>&1
  touch .lsync_$LUNCH-RELEASE
  echo "RELEASE Changelog created."
fi

if [ ! -z "$OK_EXTRAVERSION" ]
then
  export BUILDTYPE_EXPERIMENTAL=true
fi

if [ ! "$(ccache -s|grep -E 'max cache size'|awk '{print $4}')" = "500.0" ]
then
  ccache -M 500G
fi

if [ $CLEAN = true ]
then
  echo "Cleaning!"
  touch .clean
  make clobber
else
  rm out/target/product/*/aicp_*.zip
  rm -Rf out/target/product/*/system
fi

if [ $REMOVETARGETDIR = true ]
then
  echo "Removing out/target"
  rm -rf out/target
fi

echo "$REPO_BRANCH" > .last_branch

breakfast $LUNCH
check_result "Build failed."
if [ $INSTALLCLEAN = true ]
then
  echo "Running make installclean"
  make installclean
fi
time mka -j9 bacon
check_result "Build failed."
