#!/bin/sh
# sudheer@dexiva.com 
# Simple shell script to dynamically generate/update m3u8 files and "publish" to
# different web servers
# Publishing is done with http PUT
# Note that you need to preapare the target web server to accept http PUT
# We are just using curl to "PUT" files, and not WebDav
# Read readme.txt file for details.


# Usage: This program doesn't have any command line parameters, all are
# hard coded inside the code.
# Copy this program to a suitable dir in a Linux machine  and run
# this program as super user

# How fast the manifest files need to be updated
MANIFEST_GEN_DELAY_TIME=6

# How many profiles we have?
NUM_OF_PROFILES=3

# How many TS Chunk entries in the manifest
TS_CHUNKS_COUNT=5
MEDIA_SEQ_NUM=1
CHUNK_PLAY_TIME=6

MANIFEST_STAGE_FILE=m3u8_stage.txt
LOG_FILE=/var/tmp/hlsPublishingSimul.log
TOP_LEVEL_MANIFEST=test_top.m3u8

# Our targe web server directories for putting m3u8 and ts chunks
# This should be a fully qualified URI directory.
TS_CHUNK_URI_DIR="http://54.169.139.27/"
M3U8_URI_DIR="http://52.77.254.34/"


# Do the clean up, before we start
rm -f $MANIFEST_STAGE_FILE
rm -f sample*.ts

# Create a top level Manifest which we can push to the target server
echo -e "#EXTM3U \n#EXT-X-VERSION:3 " > $TOP_LEVEL_MANIFEST
PROF_COUNT=1
BANDWIDTH_FACTOR="00000"
while [ $PROF_COUNT -le $NUM_OF_PROFILES ]; do
    BANDWIDTH=$PROF_COUNT$BANDWIDTH_FACTOR
    echo -e "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$BANDWIDTH" >> $TOP_LEVEL_MANIFEST
    echo -e "test_Prof_$PROF_COUNT.m3u8" >> $TOP_LEVEL_MANIFEST
    let PROF_COUNT=$PROF_COUNT+1
done
# Add a blank line to keep it clean
echo " " >> $TOP_LEVEL_MANIFEST
echo "`date`: created Top level Manifest $TOP_LEVEL_MANIFEST"  | tee -a $LOG_FILE
cat $TOP_LEVEL_MANIFEST | tee -a $LOG_FILE

# Create a sample.ts files - this will be our standard chunk file
# Easy way is to copy any binary file as sample.ts
# we copy /bin/echo binary for this which gives us size of 28Kb, if you
# need bigger size, use some other binary avialable or use an actual ts file

PROF_COUNT=1
while [ $PROF_COUNT -le $NUM_OF_PROFILES ]; do
    cat `which echo` >> sample_Prof_$PROF_COUNT.ts

    # You may want to make the file size bigger for higher profiles
    COUNT=0
    while [ $COUNT -lt $PROF_COUNT ]; do
        cat `which echo` >> sample_Prof_$PROF_COUNT.ts
        let COUNT=$COUNT+1
    done
    let PROF_COUNT=$PROF_COUNT+1
done

echo "`date`: Created the sample chunk files.." | tee -a $LOG_FILE

# Push the top level manifest to the m3u8 server
curl -T $TOP_LEVEL_MANIFEST $M3U8_URI_DIR

while [ 1 ]; do

    # We will be doing this process for all the profiles we have.
    PROF_COUNT=1
    while [ $PROF_COUNT -le $NUM_OF_PROFILES ]; do

        # Create the usual info required..
        echo "`date`: Profile $PROF_COUNT > Starting with Media Sequence \
            $MEDIA_SEQ_NUM" | tee -a $LOG_FILE
        echo -e "#EXTM3U\n#EXT-X-VERSION:3\
            \n#EXT-X-TARGETDURATION:$CHUNK_PLAY_TIME\n " > $MANIFEST_STAGE_FILE
        echo -e "#EXT-X-MEDIA-SEQUENCE:$MEDIA_SEQ_NUM\n\n" >> \
            $MANIFEST_STAGE_FILE

        CHUNKS_ADDED=0

        while [ $CHUNKS_ADDED -lt $TS_CHUNKS_COUNT ]; do
            let CHUNK_NUMBER=$MEDIA_SEQ_NUM+$CHUNKS_ADDED
            echo -e "#EXTINF:$CHUNK_PLAY_TIME$RANDOM_FACTOR,"  >> \
                    $MANIFEST_STAGE_FILE
            echo -e "tsChunk_Prof_$PROF_COUNT-$CHUNK_NUMBER.ts" >> \
                $MANIFEST_STAGE_FILE
            echo "`date`: Added tsChunk_Prof_$PROF_COUNT-$CHUNK_NUMBER.ts to \
                    manifest " | tee -a $LOG_FILE
            let CHUNKS_ADDED=$CHUNKS_ADDED+1

        done

        # Move the staging file to test.m3u8
        cp $MANIFEST_STAGE_FILE test_Prof_$PROF_COUNT.m3u8

        # Now  upload the manifest file to webserver using http PUT
        # curl -T  will be using PUT
        echo "Uploading  test_Prof_$PROF_COUNT.m3u8 to $M3U8_URI_DIR .." \
            | tee -a $LOG_FILE
        curl -T test_Prof_$PROF_COUNT.m3u8 $M3U8_URI_DIR
        echo "Upload Status : $?" | tee -a $LOG_FILE
        # Now we have created a temp file for our m3u8
        # Let's create all the chunk files required
        for file in `grep tsChunk $MANIFEST_STAGE_FILE` ; do
            echo "`date`: Created file ... $file" | tee -a $LOG_FILE
            # NOTE: if you don't do "unalias cp",the cp -f will still prompt for
            # confirmation..
            cp -f sample_Prof_$PROF_COUNT.ts $file

            # Upload the "chunk file" to web server using PUT (curl -T)
            echo "Uploading  $file to $TS_CHUNK_URI_DIR .." | tee -a $LOG_FILE
            curl -T $file $TS_CHUNK_URI_DIR
            echo " Upload Status: $?" | tee -a $LOG_FILE
			# Don't leave the file on this machine
			rm -f $file
        done
        let PROF_COUNT=$PROF_COUNT+1

    done

    # For the next manifest file, the sequence number will be increased
    let MEDIA_SEQ_NUM=$MEDIA_SEQ_NUM+$TS_CHUNKS_COUNT

    #Rest for a while before we do the next update
    sleep $MANIFEST_GEN_DELAY_TIME

    # Once in a while push the top level manifest to the web server
    let x=$RANDOM%5
    if [ $x -gt 1 ]; then
        curl -T $TOP_LEVEL_MANIFEST $M3U8_URI_DIR
    fi

done
