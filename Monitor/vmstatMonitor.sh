#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月04日 星期日 13时43分59秒
# File Name: /home/zhang/Develop/BashWork/perftools/PerfMonitor/vmstatMonitor.sh
# Description: 
#   monitor module of vmstat tool
#========================================================================
#!/bin/bash
. $(dirname $0)/../config

#============================= GET PARTS ================================
getExit()
{
    echo "Calculating results, please wait ..."
    # result data
    sed '/[a-z]/d;' $BASE_DIR/Result/$TEST_LOG_NAME/raw.data | sed '1d;' | awk '{print '$SAMPLING_DENSITY'*NR"\t  "$0}' >> $BASE_DIR/Result/$TEST_LOG_NAME/result.data

    # result statistic
    head -n 5 $BASE_DIR/Result/$TEST_LOG_NAME/raw.data | tail -n 3 | tr -d '\015' >> $BASE_DIR/Result/$TEST_LOG_NAME/result.stat
    column_num=$(expr `sed -n '5p' $BASE_DIR/Result/$TEST_LOG_NAME/raw.data | wc -w` + 1)
    counter=2
    result=" "
    while [ $counter -le $column_num ]
    do
	result=$result`awk '{sum+=$'$counter'}END{printf("%0.1f ", sum/NR)}' $BASE_DIR/Result/$TEST_LOG_NAME/result.data`
	(( counter++ ))
    done
    echo "$result" >> $BASE_DIR/Result/$TEST_LOG_NAME/result.stat

}

#============================ MAIN FUNCTION =============================
trap "getExit" $EXIT_SIGNAL
expect $BASE_DIR/autoSsh.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD "date -R && vmstat $SAMPLING_DENSITY" >> $BASE_DIR/Result/$TEST_LOG_NAME/raw.data
