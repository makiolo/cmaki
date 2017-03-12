#!/bin/bash

MV="git mv"

if [[ $3 == "run" ]];
then
	# do sed implace
	run=" -i"
else
	run=""
fi

command="ag -w --cpp $1 -l --ignore cmaki --ignore cmaki_generator --ignore depends --ignore gcc --ignore clang --ignore bin"
if [[ $3 == "run" ]];
then
	echo run: "$command | xargs sed "s/\<$1\>/$2/g" $run"
fi
$command | xargs sed "s/\<$1\>/$2/g" $run

command_search_files=$command | egrep '$1.cpp$|$1.h$'

# candidates files
if [[ $3 == "run" ]];
then
	count=$($command_search_files | xargs grep -h -e "^#include" | grep -h $2 | wc -l)
else
	count=$($command_search_files | xargs grep -h -e "^#include" | grep -h $1 | wc -l)
fi
if [[ $count -gt 0 ]];
then
	echo "se renonbrara los siguientes ficheros (utilizando $MV):"
	for file in $($command_search_files);
	do
		destiny=$(echo $file | sed "s/\<$1\>/$2/g")
		if [[ $3 == "run" ]];
		then
			echo run: $MV $file $destiny
			$MV $file $destiny
		else
			echo dry-run: $MV $file $destiny
		fi
	done
else
	echo "No es necesario renombrar ficheros"
fi

