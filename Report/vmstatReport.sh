#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月07日 星期三 22时17分47秒
# File Name: /home/zhang/Develop/BashWork/perftools/PerfMonitor/Report/vmstatReport.sh
# Description: 
#========================================================================
#!/bin/bash
#============================== HEADER FILES ============================
. $(dirname $0)/../config

#=============================== SET PARTS ==============================
#生成png格式的图表的方法，传入一个参数
setGraph()
{
    # check the number of parameter
    [ $# -ne 1 ] && { echo "Function setGraph parameter error"; exit $RUNTIME_ERROR; }

    # set variables
    TITLE=""
    OUTPUT=""
    PLOT=""
    YRANGE="[0:]"
    case "$SERVER_PLATFORM" in
        *[Ll][Ii][Nn][Uu][Xx]* )
        VMSTAT_PROCS=("r" "b")
        VMSTAT_MEMORY=("swpd" "free" "buff" "cache")
        VMSTAT_SWAP=("si" "so")
        VMSTAT_IO=("bi" "bo")
        VMSTAT_SYSTEM=("in" "cs")
        VMSTAT_CPU=("us" "sy" "id" "wa")
        ;;
        * )
        echo "Platform $SERVER_PLATFORM is not supported in this version"
        exit 1
        ;;
    esac

    # create graph
    case "$1" in
       "procs" )
       TITLE="procs"
       YRANGE="[-1:]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:2 title '${VMSTAT_PROCS[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:3 title '${VMSTAT_PROCS[1]}'"
       ;;

       "memory" )
       TITLE="memory"
       YRANGE="[-50000:]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:4 title '${VMSTAT_MEMORY[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:5 title '${VMSTAT_MEMORY[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:6 title '${VMSTAT_MEMORY[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:7 title '${VMSTAT_MEMORY[3]}'"
       ;;

       "swap" )
       TITLE="swap"
       YRANGE="[-1:5]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:8 title '${VMSTAT_SWAP[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:9 title '${VMSTAT_SWAP[1]}'"
       ;;

       "io" )
       TITLE="io"
       YRANGE="[-10:]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:10 title '${VMSTAT_IO[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:11 title '${VMSTAT_IO[1]}'"
       ;;

       "system" )
       TITLE="system"
       YRANGE="[-100:]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:12 title '${VMSTAT_SYSTEM[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:13 title '${VMSTAT_SYSTEM[1]}'"
       ;;
       
       "cpu" )
       TITLE="cpu"
       YRANGE="[-10:100]"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:14 title '${VMSTAT_CPU[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:15 title '${VMSTAT_CPU[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:16 title '${VMSTAT_CPU[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:17 title '${VMSTAT_CPU[3]}'"
       ;;

       * )
       echo "Error! Parameter must one of the values below: "
       echo "1) procs, 2) memory, 3) swap, 4) io, 5) system, 6) cpu"
       exit 1
       ;;

    esac

    OUTPUT="$BASE_DIR/Result/$TEST_LOG_NAME/vmstat_${TITLE}.png"
    if [ `wc -l $BASE_DIR/Result/$TEST_LOG_NAME/result.data | awk '{print $1}'` -lt 30 ]; then
        STYLE="linespoints"
    else
        STYLE="lines"
    fi
    gnuplot <<EOF
        set terminal png small size 480,360
        set key below horizontal box
        set style data $STYLE 
        set title "-- $TITLE --"
        set yrange $YRANGE
        set grid
        set output "$OUTPUT"
        $PLOT
EOF
}

#============================== MAIN FUNCTION ===========================
# check if result.data is a blank file
[ -s $BASE_DIR/Result/$TEST_LOG_NAME/result.data ] || { echo "No data collected, the report won't be generated."; exit 1; }

# build graph
setGraph "procs"
setGraph "memory"
setGraph "swap"
setGraph "io"
setGraph "system"
setGraph "cpu"

# build report
[ -f $BASE_DIR/Templates/${REPORT_TYPE}.htm ] || { echo "Templates ${REPORT_TYPE} is not supported in this version"; exit 1; }

# Server Info
duration=`tail -n 1 $BASE_DIR/Result/$TEST_LOG_NAME/result.data | awk '{print $1}'`
test_start="`head -n 1 $BASE_DIR/Result/$TEST_LOG_NAME/result.stat`"

# Stat data
stat="<table>"
stat="$stat""<tr>"`sed -n '2p' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{print "<td colspan=2>"$1"<\/td><td colspan=4>"$2"<\/td><td colspan=2>"$3"<\/td><td colspan=2>"$4"<\/td><td colspan=2>"$5"<\/td><td colspan=4>"$6"<\/td>"}'`"<\/tr>" # First line
stat="$stat""<tr>"`sed -n '3p' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{for(i=1; i<=NF; i++) print "<td>"$i"<\/td>"}'`"<\/tr>" # Second line
stat="$stat""<tr>"`sed -n '$p' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{for(i=1; i<=NF; i++) print "<td>"$i"<\/td>"}'`"<\/tr>" # Third line
stat="$stat""<\/table>"
stat=`echo "$stat" | tr -d "\n"`

# Graph image
graph=`for img in $BASE_DIR/Result/$TEST_LOG_NAME/*.png; do echo -n "<img src=$(basename $img)><\/img> "; done;`

# raw data
raw_data="<a href=result.data>View Raw Data<\/a>"

# Build the html report
sed 's/<!-- TITLE -->/Vmstat Statistic/g;
     s/<!-- SERVER_ADDR -->/'"${SERVER_ADDR}"'/g;
     s/<!-- SERVER_PLATFORM -->/'"${SERVER_PLATFORM}"'/g;
     s/<!-- TEST_START -->/'"${test_start}"'/g;
     s/<!-- TEST_DURATION -->/'"${duration}"'/g;
     s/<!-- STAT -->/'"${stat}"'/g;
     s/<!-- GRAPH -->/'"${graph}"'/g;
     s/<!-- RAW_DATA -->/'"${raw_data}"'/g;' $BASE_DIR/Templates/${REPORT_TYPE}.htm > $BASE_DIR/Result/$TEST_LOG_NAME/index.htm

