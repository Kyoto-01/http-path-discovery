#!/bin/bash

URL=$1		# URL to scan
WORD_COUNT=$2 	# Initial index of wordlist

TERM_COLOR_GREEN="\033[92;42m"
TERM_COLOR_RESET="\033[0m"

WORDLIST_DIR="wordlists/"		# Path to the directory that contains wordlist files
WORDLIST_TMP_FILE="words.txt"
DIRS_FILE="dirs.txt"			# File to save successfully scanned directories
FILES_FILE="files.txt"			# File to save successfully scanned files
WORD_COUNT_FILE="word_count.txt"	# File to save index of last tested word 

if [ -n "$WORD_COUNT" ];then
	echo "${WORD_COUNT}" > ${WORD_COUNT_FILE}
fi

wordCount=$(cat ${WORD_COUNT_FILE}) 	# Index of last tested word

# Records the index of last tested word
function trap_ctrlc() {
	echo "${wordCount}" > $WORD_COUNT_FILE
	rm -f ${WORDLIST_TMP_FILE}
    	exit 2
}

# Read the wordlist files to $words
function get_words() {
	for file in $(ls ${WORDLIST_DIR});do
		echo "$(cat ${WORDLIST_DIR}${file})" >> ${WORDLIST_TMP_FILE}
	done
}

# scan the target URL with saved words
function scan() {
	remainingWords=$(( $(wc -l ${WORDLIST_TMP_FILE} | cut -d ' ' -f 1) - ${wordCount} ))
	
	words=$(cat ${WORDLIST_TMP_FILE} | tail -n ${remainingWords})
	
	for word in $( echo "${words}" );do
		# Test the word like a directory
		statusDir=$(curl -s -o /dev/null -w "%{http_code}" ${URL}/${word}/)
		
		# Test the word like a file
		statusFile=$(curl -s -o /dev/null -w "%{http_code}" ${URL}/${word})

		# set terminal foreground to green
		tput setaf 2

		if [ "$statusDir" = "200" -o "$statusDir" = "401" ];then
			echo -e "${word}\t${statusDir}" | tee -a ${DIRS_FILE}
		fi

		if [ "$statusFile" = "200" -o "$statusFile" = "401" ];then
			echo -e "${word}\t${statusFile}" | tee -a ${FILES_FILE}
		fi

		# reset color of terminal foreground
		tput sgr0

		wordCount=$(( ${wordCount} + 1 ))

		echo "${wordCount} URL(s) scanned: /${word}"
	done
}

trap "trap_ctrlc" 2

echo "Scanning $URL"

get_words

scan

rm -f ${WORDLIST_TMP_FILE}
