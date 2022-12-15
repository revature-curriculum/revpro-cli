#!/bin/bash

# echo "parsing test output of $1"

if [[ -f $1 ]]
then
    failures=$(grep -m1 -e 'Failures: ' $1 | awk -F 'Failures: ' '{print $2}' | awk -F ', ' '{print $1}')
    
    if  [ $failures -gt 0 ]
    then
        echo "failures > 0..."
        results=`grep -A5000 -m1 -e 'Results :' $1`
        # echo "grep -A5000"
        final_results=$(cat $results | sed -En '/\[ERROR\]/d')
        echo $final_results
    else
        echo "no failures..."
        results=`grep -A5000 -m1 -e 'Running ' $1`
        echo $results
    fi
fi