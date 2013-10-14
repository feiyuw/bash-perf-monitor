#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月09日 星期五 17时31分24秒
# File Name: mpstatMonitor.sh
# Description: 
#   Report module of mpstat tool
#========================================================================
#!/bin/bash
. $(dirname $0)/../config

#============================= GET PARTS ================================
getExit()
{
    echo "Calculating results, please wait ..."
    sed -n '/all/p' $BASE_DIR/Result/$TEST_LOG_NAME/raw.data >> $BASE_DIR/Result/$TEST_LOG_NAME/result.data
    sed -n '5p' $BASE_DIR/Result/$TEST_LOG_NAME/raw.data | sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/Class   /g;s/\//\\\//g;' | tr -d '\015' >> $BASE_DIR/Result/$TEST_LOG_NAME/result.stat
    result="Average:     all    "
    column_num=`awk 'END{print NF}' $BASE_DIR/Result/$TEST_LOG_NAME/result.data`
    for (( counter=3; counter<=$column_num; counter++ ))
    do
        result="$result"`awk '{sum+=$'$counter'} END{printf("%0.2f    ", sum/NR)}' $BASE_DIR/Result/$TEST_LOG_NAME/result.data`
    done
    echo "$result" >> $BASE_DIR/Result/$TEST_LOG_NAME/result.stat
}

#============================ MAIN FUNCTION =============================
trap "getExit" $EXIT_SIGNAL
expect $BASE_DIR/autoSsh.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD "export LC_ALL=iso && mpstat $SAMPLING_DENSITY" >> $BASE_DIR/Result/$TEST_LOG_NAME/raw.data
