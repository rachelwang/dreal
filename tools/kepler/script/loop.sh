#!/bin/bash

########################################

# TODO
TODO=./TODO

# QUEUE
SMT_QUEUE=./SMT_QUEUE
CHECK_QUEUE=./CHECK_QUEUE

# MAX (NUM of Processors to Use)
MAX=25

RUN_SINGLE=~/work/dreal2/tools/kepler/script/run_single.sh
PCHECKER=~/work/dreal2/tools/kepler/proof_checker/main.native
SPLIT=~/work/dreal2/tools/kepler/script/split.py

########################################

touch $TODO

while [ -f $TODO ]
do
    # INITIALIZE QUEUES
    rm -rf $SMT_QUEUE $CHECK_QUEUE
    touch $SMT_QUEUE $CHECK_QUEUE

    # TODO will be re-created if we need more things TO DO
    rm $TODO

    # Find SMT2 files and add to SMT QUEUE
    # 1) Do not have the result, yet
    for SMT2 in `find ./ -name "*.smt2"`
    do
        BASE=${SMT2//.smt2/}
        if [ ! -f $BASE.result ]
        then
            echo $BASE >> $SMT_QUEUE
            echo `date`: "Adding ${BASE}.smt2 to the SMT Queue"
        fi
    done

    # RUN in Parallel: dReal2 to generate results (.result, .time, .trace)
    if [ -s $SMT_QUEUE ]
    then
        echo `date`: "RUN DREAL2:"
        cat $SMT_QUEUE | parallel --max-procs=$MAX "$RUN_SINGLE {}.smt2"
    fi

    # RUN: split.py
    if [ -s $SMT_QUEUE ]
    then
	echo `date`: "RUN SPLIT:"
        cat $SMT_QUEUE | parallel --max-procs=$MAX "$SPLIT {}.trace"
    fi

    # Find trace files and add to CHECK QUEUE
    for TRACE in `find ./ -name "*.trace"`
    do
        BASE=${TRACE//.trace/}
        if [ ! -f $BASE.checked ]
        then
		echo $BASE >> $CHECK_QUEUE
		echo "Adding ${BASE}.trace to the CHECK Queue"
	fi
    done

    # RUN in Parallel: proof_checker to generate result (possibly sub_problems)

    if [ -s $CHECK_QUEUE ]
    then
        echo `date`: "RUN Check"
        cat $CHECK_QUEUE | parallel --max-procs=$MAX "$PCHECKER {}.trace"
        cat $CHECK_QUEUE | parallel --max-procs=$MAX "touch {}.checked"
        touch $TODO # We may need to have more things TO DO
    fi
done