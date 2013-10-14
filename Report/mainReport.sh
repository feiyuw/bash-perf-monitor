#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月03日 星期六 16时17分57秒
# File Name: mainReport.sh
# Description: 
#   Main script of report modules
#========================================================================
#!/bin/bash
#============================== HEADER FILES ============================
. $(dirname $0)/../config

#============================= MAIN FUNCTION ============================
[ -f $BASE_DIR/Templates/${REPORT_TYPE}.htm ] || { echo "Report type ${REPORT_TYPE} is not supported in this version."; exit 1; }
[ -f $BASE_DIR/Report/${MONITOR_TOOL}Report.sh ] || { echo "Report type ${REPORT_TYPE} is not supported in this version."; exit 1; }

# build the report
$BASE_DIR/Report/${MONITOR_TOOL}Report.sh
