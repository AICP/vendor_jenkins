export CHANGESPATH=$WORKSPACE/archive/CHANGES.txt
export CHANGESFULLPATH=$WORKSPACE/CHANGELOGS/$LUNCH.txt

export ts=$1
(echo "==================================="
echo "Since $(LANG=en_US date -u -d @$ts) to $(LANG=en_US date)" 
echo "==================================="
repo forall -c 'L=$(git log --oneline --since $ts --grep="[log]" -n 1); if [ "n$L" != "n" ]; then echo; echo "   * $REPO_PATH"; git log --format=%s --since $ts --grep="[log]"; fi'
echo) > $CHANGESPATH

echo | cat $CHANGESPATH - $CHANGESFULLPATH > temp.changes
mv temp.changes $CHANGESFULLPATH