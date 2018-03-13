i=0
for l in `ls`
do
echo "file $((i++)) : $l"
cp $l $i.aiff
done
