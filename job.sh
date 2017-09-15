if [ -z "$HOME" ]
then
  echo HOME not in environment, guessing...
  export HOME=$(awk -F: -v v="$USER" '{if ($1==v) print $6}' /etc/passwd)
fi

cd $WORKSPACE/$REPO_BRANCH

if [ ! -d jenkins ]
then
  git clone https://github.com/AICP/vendor_jenkins.git -b o8.0 jenkins
fi

cd jenkins
## Get rid of possible local changes
git reset --hard
git pull -s resolve

./build.sh
