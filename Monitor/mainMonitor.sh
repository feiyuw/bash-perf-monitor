#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月03日 星期六 16时10分45秒
# File Name: /home/zhang/Develop/BashWork/perftools/PerfMonitor/Monitor/mainMonitor.sh
# Description: 
#   Main script of monitor modules
#========================================================================
#!/bin/bash
#============================== HEADER FILES ============================
. $(dirname $0)/../config

#============================== SET PARTS ===============================
# set test log name, automatically
setTestLogName()
{
    prefix=test
    suffix=$(date +%s)
    test_log_name=$prefix.$suffix
    echo "TEST_LOG_NAME=$test_log_name" >> $BASE_DIR/config
}

# set sampling density
setSamplingDensity()
{
    while :
    do
        echo -n "Set the sampling density (1-9999): "
        read sampling_density
        echo ""
        if echo "$sampling_density" | grep '^[0-9]\{1,4\}$' > /dev/null; then
            break
        else
            echo "The sampling density must be a number between 1 and 9999. Please try again."
            continue
        fi
    done

    echo "SAMPLING_DENSITY=$sampling_density" >> $BASE_DIR/config
}

#============================== MAIN FUNCTION ===========================
[ -f $BASE_DIR/Monitor/${MONITOR_TOOL}Monitor.sh ] || { echo "Monitor tool ${MONITOR_TOOL} is not supported in this version."; exit 1; }

setTestLogName || { echo "Runtime Error: setTestLogName"; exit $RUNTIME_ERROR; }

setSamplingDensity || { echo "Runtime Error: setSamplingDensity"; exit $RUNTIME_ERROR; }

# create test log
. $BASE_DIR/config
mkdir $BASE_DIR/Result/$TEST_LOG_NAME || { echo "Runtime Error: createTestLogFolder"; exit $RUNTIME_ERROR; }

# begin to monitor
echo "Collecting data, press Ctrl+C to exit"
$BASE_DIR/Monitor/${MONITOR_TOOL}Monitor.sh
