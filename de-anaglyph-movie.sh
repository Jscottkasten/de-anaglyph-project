#!/bin/bash

###################################################################################
# Copyright (C) 2015, 2016, 2017 by UVS Innovations Corporation.                  #
# All rights reserved.                                                            #
#                                                                                 #
# Redistribution and use in source and binary forms, with or without              #
# modification, are permitted provided that the following conditions are met:     #
#                                                                                 #
# 1. Redistributions of source code must retain the above copyright notice, this  #
#    list of conditions and the following disclaimer.                             #
# 2. Redistributions in binary form must reproduce the above copyright notice,    #
#    this list of conditions and the following disclaimer in the documentation    #
#    and/or other materials provided with the distribution.                       #
#                                                                                 #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND #
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED   #
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          #
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR #
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES  #
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    #
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND     #
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT      #
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS   #
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                    #
#                                                                                 #
###################################################################################

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
