export CHANGESPATH=$WORKSPACE/archive/CHANGES.txt
export CHANGESFULLPATH=$WORKSPACE/CHANGELOGS/$LUNCH.txt

export ts=$1
(echo "==================================="
echo "Since $(LANG=en_US date -u -d @$ts) to $(LANG=en_US date)" 
echo "==================================="
repo forall -c 'L=$(git lg --since $ts ); if [ "n$L" != "n" ]; then echo; echo "   * $REPO_PATH"; git lg --since $ts ; fi' echo) | out2html  > $CHANGESPATH
echo | cat $CHANGESPATH - $CHANGESFULLPATH > temp.changes
mv temp.changes $CHANGESFULLPATH
