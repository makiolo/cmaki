#!/bin/bash

MV="git mv"

if [[ $3 == "run" ]];
then
	# do sed implace
	run=" -i"
else
	run=""
fi

if [[ $3 == "run" ]];
then
	echo run: "ag -w --cpp $1 -l --ignore cmaki --ignore depends --ignore build --ignore artifacts | xargs sed "s/\<$1\>/$2/g" $run"
fi
ag -w --cpp $1 -l --ignore cmaki --ignore depends --ignore build --ignore artifacts | xargs sed "s/\<$1\>/$2/g" $run

# candidates files
if [[ $3 == "run" ]];
then
	count=$(find . -type f -name "*$1.cpp" -o -name "*$1.h" | xargs grep -h -e "^#include" | grep -h $2 | wc -l)
else
	count=$(find . -type f -name "*$1.cpp" -o -name "*$1.h" | xargs grep -h -e "^#include" | grep -h $1 | wc -l)
fi
if [[ $count -gt 0 ]];
then
	echo "se renonbrara los siguientes ficheros (utilizando $MV):"
	for file in $(find . -type f -name "*$1.cpp" -o -name "*$1.h");
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

