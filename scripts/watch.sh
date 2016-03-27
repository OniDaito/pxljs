#!/bin/sh

check() {
    chsum1=""
    chsum3=""

    while [[ true ]]
    do
        chsum2=`find src/ -type f -exec md5 {} \;`
        if [[ $chsum1 != $chsum2 ]] ; then           
            eval $1
            chsum1=`find src/ -type f -exec md5 {} \;`
        fi

        chsum2=`find examples/ -type f -exec md5 {} \;`
        if [[ $chsum3 != $chsum2 ]] ; then           
            eval $1
            chsum3=`find examples/ -type f -exec md5 {} \;`
        fi
        

        sleep 2
    done
}

check $*
