#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月03日 星期六 15时16分43秒
# File Name: mainShell.sh
# Description: 
#   Main shell script of the application, build the config file and 
#   start the monitor and report
#========================================================================
#!/bin/bash
#=============================== HEADER FILE ============================
#. $(dirname $0)/config

#================================== SET PARTS ===========================
# set server info, including: address, username and password
setServerInfo()
{
    # IP Address
    while :
    do
        echo -n "Set the ip address of server you want to monitor: "
        read server_addr
        if echo "$server_addr" | grep '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' > /dev/null
        then 
            break
        else
            echo "Wrong IP address, please try again" && continue
        fi
    done

    # Username
    echo -n "Set the login name: "
    read server_user
    # if not set, set the system login user name
    if [ -z "$server_user" ]; then
        server_user=$USER
    fi

    # Password
    echo -n "Set the password: "
    read server_pwd

    # modify the config file
    echo "SERVER_ADDR=$server_addr
          SERVER_USER=$server_user
          SERVER_PWD=$server_pwd" >> $BASE_DIR/config

}

# set the monitor tool: vmstat, mpstat, iostat, sar?
setMonitorTool()
{
    while :
    do
        echo "Select monitor tools from below: "
        for (( cursor=0; cursor<${#MONITOR_TOOLS[@]}; cursor++ ))
        do
            echo "  `expr $cursor + 1` ) ${MONITOR_TOOLS[$cursor]})"
        done
        echo -n "Set your choice here (1, 2, 3, ...): "
        read -n 1 choice
        echo ""
        case "$choice" in
            [1-${#MONITOR_TOOLS[@]}] )
            break
            ;;
            * )
            echo "You can only set the choise from the list above, please try again!"
            continue
            ;;
        esac
    done
    monitor_tool=${MONITOR_TOOLS[$((--choice))]}

    echo "MONITOR_TOOL=$monitor_tool" >> $BASE_DIR/config
    
}

# set report type, select which template to use
setReportType()
{
    while :
    do
        echo "Select report type from below: "
        for (( cursor=0; cursor<${#REPORT_TYPES[@]}; cursor++ ))
        do
            echo "  `expr $cursor + 1` ) ${REPORT_TYPES[$cursor]})"
        done
        echo -n "Set your choice here (1, 2, 3, ...): "
        read -n 1 choice
        echo ""
        case "$choice" in
            [1-${#REPORT_TYPES[@]}] )
            break
            ;;
            * )
            echo "You can only set the choise from the list above, please try again!"
            continue
            ;;
        esac
    done
    report_type=${REPORT_TYPES[$((--choice))]}

    echo "REPORT_TYPE=$report_type" >> $BASE_DIR/config

}

# set config above
setConfig()
{
    cp $base_dir/Samples/config $base_dir/
    echo "BASE_DIR=$base_dir" >> $base_dir/config
    . $base_dir/config
    setServerInfo || { echo "Runtime Error: setServerInfo"; exit $RUNTIME_ERROR; }

    . $base_dir/config
    setMonitorTool || { echo "Runtime Error: setMonitorTool"; exit $RUNTIME_ERROR; }

    . $base_dir/config
    getServerType || { echo "Runtime Error: getServerType"; exit $RUNTIME_ERROR; }

    . $base_dir/config
    setReportType || { echo "Runtime Error: setReportType"; exit $RUNTIME_ERROR; }
}

#=============================== GET PARTS ==============================
# get the server type: Linux, AIX?
getServerType()
{
    echo "Testing SSH connection ..."
    server_platform=`expect $BASE_DIR/autoSsh.exp $SERVER_ADDR $SERVER_USER $SERVER_PWD "uname; which ${MONITOR_TOOL}"`
    if echo "$server_platform" | grep 'refused' > /dev/null; then
        echo "SSH connection failed, please check the service!"
        exit 1
    elif echo "$server_platform" | grep 'denied' > /dev/null; then
        echo "SSH connection failed, wrong user name or passsword!"
        exit 1
    elif echo "$server_platform" | sed -n '4p' | grep "which" > /dev/null; then
        echo "${MONITOR_TOOL} is not installed in the server, please use another tool!"
        exit 1
    else
        echo "SSH connection test success"
    fi
    case "$server_platform" in
        *[Ll][Ii][Nn][Uu][Xx]* )
        server_platform=Linux
        ;;
        * )
        echo "Only Linux platform are supported in this version."
        exit 1
        ;;
    esac
    echo "SERVER_PLATFORM=$server_platform" >> $BASE_DIR/config
    echo "Got server type: $server_platform"
}

#=========================== MAIN FUNCTION ==============================
# set default config file
base_dir=$(dirname $0)
if [ -f $base_dir/config ]; then
    . $base_dir/config
else
    cp $base_dir/Samples/config $base_dir/
    echo "BASE_DIR=$base_dir" >> $base_dir/config
fi
if [[ $DEFAULT -eq 1 ]]; then
    while :
    do
        echo -n "Do you want to use the last setting? (Y/N): "
        read -n 1 usedefault
        echo
        case "$usedefault" in
            [Yy] )
            break
            ;;
            [Nn] )
            setConfig
            echo "DEFAULT=1" >> $base_dir/config
            break
            ;;
            * )
            echo "You can only type Y/y or N/n, please try again"
            continue
            ;;
        esac
    done
else
    setConfig
    echo "DEFAULT=1" >> $base_dir/config
fi

# remove TEST_LOG_NAME and SAMPLING_DENSITY if exist in config file
sed '/TEST_LOG_NAME/d; /SAMPLING_DENSITY/d' $BASE_DIR/config >> $BASE_DIR/config$$
mv $BASE_DIR/config$$ $BASE_DIR/config

# monitor
$BASE_DIR/Monitor/mainMonitor.sh

# report
$BASE_DIR/Report/mainReport.sh
