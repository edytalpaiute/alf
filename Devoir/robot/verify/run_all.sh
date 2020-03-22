#!/bin/bash

main="$1"
mkdir -p output
rm -rf output/*

POINTS=0

dir=`dirname "$1"`

errorslist=$dir/errors.out
rm -f $errorslist

cd "$dir"
if [ -d node_modules ];
then
	echo 'Please delete the node_modules folder from your homework archive'
elif [ ! -f package.json ];
then
	echo 'The package.json file is missing'
	echo 'Please add a package.json file to you homework archive.'
elif ! npm install;
then
	echo 'npm install fail, please verify that the package.json file information'
else

	passed=0
	failed=0
	total=0

	echo '{ "node":true, "esnext":true }' > .jshintrc
	if [ ! -f `basename "$1"` ];
	then
		echo "Your main.js file is missing"
	elif ! jshint *.js;
	then
		echo "Please review your code, you have jshint errors"
	else
		cd -

		for folder in robot/*
		do
			if [ -d $folder ];
			then
				if [ -f "$folder"/run.txt ];
				then
					echo `head -n 1 "$folder"/run.txt`
					P=`head -n 2 "$folder"/run.txt | tail -n 1`
				else
					echo `basename $folder`
					P=10
				fi
				if [ $failed == 0 ] || ! (echo $folder | grep bonus &> /dev/null);
				then
					for file in "$folder"/*.s
					do
						inputfile=`pwd`/"$file"
						outputfile=output/`basename "$file"`.out
						originalfile="$file.out"
						errorsfile=output/`basename "$file"`.err
						title=`head -n 1 "$file" | grep '#' | cut -d '#' -f 2`
						if [ `echo -n "$title" | wc -c` -eq 0 ];
						then
							title=`basename $file`
						fi
						strtitle="Verifying $title"
						printf '%s' "$strtitle"
						pad=$(printf '%0.1s' "."{1..60})
						padlength=65
						timeout 10 node "$1" "$inputfile" > "$outputfile"
						err=$?
						if [ $err == 124 ];
						then
							str="timeout (0p)"
							failed=$(($failed+1))
							# echo "--------------" >> $errorslist 
							# echo $strtitle >> $errorslist
							# head -10 "$errorsfile" >> $errorslist
						else
							if diff --side-by-side --suppress-common-lines "$originalfile" "$outputfile" &> "$errorsfile"
							then
								str="ok (""$P""p)"
								passed=$(($passed+1))
								POINTS=$(($POINTS+$P))
							else
								str="error (0p)"
								failed=$(($failed+1))
								echo "--------------" >> $errorslist 
								echo $strtitle >> $errorslist
								head -10 "$errorsfile" >> $errorslist
							fi
						fi
						total=$(($total+1))
						printf '%*.*s' 0 $((padlength - ${#strtitle} - ${#str} )) "$pad"
						printf '%s\n' "$str"
					done
				else
					echo "Not verifying bonus, you have $failed failed tests"
				fi
			fi
		done	
	fi

	echo 'Tests: ' $passed '/' $total
	echo 'Points: '$POINTS
	echo 'Mark without penalties: '`echo $(($POINTS/2)) | sed 's/.$/.&/'`

	if [ "$passed" != "$total" ];
	then
		echo -e "Original file						      | Your file" 1>&2
		cat $errorslist 1>&2
	fi
fi

