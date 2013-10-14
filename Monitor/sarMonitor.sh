#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月13日 星期二 15时50分36秒
# File Name: sarMonitor.sh
# Description: 
#========================================================================
#!/bin/bash
. $(dirname $0)/../config

#============================= GET PARTS ================================
getExit()
{
    echo "Getting data from the server, please wait..."

    # build raw data
    expect $BASE_DIR/autoSsh.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD "export LC_ALL=iso; sar -u -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/cpu.raw.data; sar -r -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/memory.raw.data; sar -n DEV -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/network.raw.data; sar -v -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/kernel.raw.data; sar -b -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/io.raw.data; sar -B -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/page.raw.data; sar -q -f /tmp/${TEST_LOG_NAME}.raw.data >> /tmp/process.raw.data; rm -f /tmp/${TEST_LOG_NAME}.raw.data" >> /dev/null

    # copy the log file to client machine
    expect $BASE_DIR/autoScp.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD /tmp/*.raw.data $BASE_DIR/Result/$TEST_LOG_NAME/ >> /dev/null

    # build result data
    for file in $BASE_DIR/Result/$TEST_LOG_NAME/*.raw.data
    do
        if echo "$file" | grep "network" >> /dev/null; then
            sed '1,3d; /[Aa][Vv][Ee][Rr][Aa][Gg][Ee]/d' $file | sort -k 2 >> ${file/raw/result}
        else 
            sed '1,3d; /[Aa][Vv][Ee][Rr][Aa][Gg][Ee]/d' $file | sort -k 1 >> ${file/raw/result}
        fi
    done

    # build stat data
    for file in $BASE_DIR/Result/$TEST_LOG_NAME/*.raw.data
    do
        if [ `wc -l $file | awk '{print $1}'` -eq 1 ]; then
            #echo "Monitor interrupted, no data collected!"
            #rm -r $BASE_DIR/Result/$TEST_LOG_NAME
            exit 1
        fi
        sed -n '3p; /[Aa][Vv][Ee][Rr][Aa][Gg][Ee]/p' $file >> ${file/raw/stat}
    done

    # network result data (with different interfaces)
    interface_num=`sed -n '/[Aa][Vv][Ee][Rr][Aa][Gg][Ee]/p' $BASE_DIR/Result/$TEST_LOG_NAME/network.stat.data | wc -l` 
    data_num_per_interface=$(( `wc -l $BASE_DIR/Result/$TEST_LOG_NAME/network.result.data | awk '{print $1}'` / $interface_num ))
    for (( counter=0; counter<$interface_num; counter++ ))
    do
        interface_name=`awk '{print $2}' $BASE_DIR/Result/$TEST_LOG_NAME/network.result.data | sort -u | sed -n $(( 1 + $counter ))'p'`
        sed -n $(( 1 + $counter * $data_num_per_interface ))','$(( $data_num_per_interface + $counter * $data_num_per_interface ))'p' $BASE_DIR/Result/$TEST_LOG_NAME/network.result.data | sort -k 1 >> $BASE_DIR/Result/$TEST_LOG_NAME/network.$interface_name.result.data
    done
}

#============================ MAIN FUNCTION =============================
trap "getExit" $EXIT_SIGNAL
expect $BASE_DIR/autoSsh.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD "rm -f /tmp/*.raw.data && sar -o /tmp/${TEST_LOG_NAME}.raw.data -urvbqB -n DEV $SAMPLING_DENSITY 0" >> /dev/null
