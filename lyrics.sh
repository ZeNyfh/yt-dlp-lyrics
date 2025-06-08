#!/bin/bash

# check for yt-dlp
YTDLP="yt-dlp"
if ! test -f "$YTDLP"; then
	REALPATH=$(realpath "$(basename "$0")")
	echo "Error: You don't have yt-dlp installed, add the executable in the same directory as: \""$REALPATH"\"."
	exit 1
fi

# time calc
timeStart=$(date +%s%N | cut -b1-13)
# check for args
if [ "$#" -gt 2 ]; then
    echo "Usage: ./lyrics url [language]"
    exit 1
fi

URL="$1"
FILE="downloaded_audio.wav"

# download using yt-dlp
echo "Downloading audio from $URL..."
yt-dlp -x --audio-format wav --audio-quality 0 --output "$FILE" "$URL"

# check if the download was successful
if [ ! -f "$FILE" ]; then
    echo "Error: Failed to download audio."
    exit 1
fi
clear

# add padding so whisper likes the file more, slightly annoying
echo "Adding padding to file..."
ffmpeg -i "$FILE" -af "adelay=2000|2000" padded_audio.wav
echo "Deleting source file..."
rm "$FILE"
FILE="padded_audio.wav"
clear

# transcribe using whisper
echo "Transcribing audio using Whisper..."
LANG=""
if [ "$2" != "" ]; then
    whisper "$FILE" --model turbo --language "$2" --task transcribe --word_timestamps True --output_format txt --temperature 0.1 --beam_size 5 --condition_on_previous_text False
else
    whisper "$FILE" --model turbo --task transcribe --word_timestamps True --output_format txt --temperature 0.1 --beam_size 5 --condition_on_previous_text False
fi
clear

# check if transcription was successful
TRANSCRIBED_FILE="${FILE%.*}.txt"
if [ ! -f "$TRANSCRIBED_FILE" ]; then
    echo "Error: Transcription failed."
    exit 1
fi

# remove the file, its not needed anymore
echo "Removing downloaded file..."
rm "$FILE"


if [ -f "$TRANSCRIBED_FILE" ]; then
    clear    
    echo "$TRANSCRIBED_FILE"
else
    echo "Error: Transcription file not found."
    exit 1
fi

# clean up
rm "$TRANSCRIBED_FILE"
echo "Done!"
timeEnd=$(date +%s%N | cut -b1-13)
time=$(expr "$timeEnd" - "$timeStart")
echo "Took $(expr "$time" / 1000) seconds."

