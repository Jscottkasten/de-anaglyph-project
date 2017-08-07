#!/bin/bash

MEDIA=`basename $1 .AVI`
DIR=`dirname $1`
TEMP1=$DIR/Temp1-$MEDIA
TEMP2=$DIR/Temp2-$MEDIA
mkdir $TEMP1 $TEMP2

ffmpeg -i $DIR/$MEDIA.AVI $TEMP1/%05d.bmp
ffmpeg -i $DIR/$MEDIA.AVI $TEMP1/$MEDIA.wav

for file in $TEMP1/*.bmp; do
NAME=`basename $file .bmp`
./de-anaglyph.rb $TEMP1/$NAME.bmp $TEMP2/$NAME.bmp
echo $NAME
done

ffmpeg -i $TEMP1/$MEDIA.wav -r 30 -i $TEMP2/%05d.bmp -s 1280x720 -aspect 1.7777 -strict experimental $DIR/$MEDIA.mp4
rm -rf $TEMP1 $TEMP2
