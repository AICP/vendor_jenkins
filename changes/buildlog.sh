export CHANGESPATH=$WORKSPACE/$REPO_BRANCH/archive/CHANGES.txt
export CHANGESFULLPATH=$WORKSPACE/$REPO_BRANCH/CHANGELOGS/$LUNCH.txt

export ts=$1
(echo "==================================="
echo "Since $(LANG=en_US date -u -d @$ts) to $(LANG=en_US date)" 
echo "==================================="
repo forall -c 'L=$(git log --color --oneline --since $ts --grep="[log]" -n 1); if [ "n$L" != "n" ]; then echo; echo "   * $REPO_PATH"; git log --color --format=%s --since $ts --grep="[log]"; fi'
echo) | out2html  > $CHANGESPATH

echo | cat $CHANGESPATH - $CHANGESFULLPATH > temp.changes
mv temp.changes $CHANGESFULLPATH
