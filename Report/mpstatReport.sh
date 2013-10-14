#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月09日 星期五 17时31分39秒
# File Name: mpstatReport.sh
# Description: 
#   Monitor module of mpstat tool
#========================================================================
#!/bin/bash
. $(dirname $0)/../config

#=============================== SET PARTS ==============================
#生成png格式的图表的方法, 无参数
setGraph()
{
    # check server platform
    case "$SERVER_PLATFORM" in
        *[Ll][Ii][Nn][Uu][Xx]* )
        :
        ;;
        * )
        echo "Platform $SERVER_PLATFORM is not supported in this version"
        exit 1
        ;;
    esac

    # set variables
    TITLE=""
    OUTPUT=""
    PLOT=""
    YRANGE="[-1:]"

    # create graph
    class_num=`awk 'END {print NF}' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat`
    for (( i=3; i<=$class_num; i++ ))
    do
        TITLE="`head -n 1 $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{print $'$i'}' | sed 's/%//;s/\\\\\\//_per_/g;'`"
        PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/result.data' using 1:$i title '$TITLE'"
        OUTPUT="$BASE_DIR/Result/$TEST_LOG_NAME/mpstat_${TITLE}.png"
        if [ `wc -l $BASE_DIR/Result/$TEST_LOG_NAME/result.data | awk '{print $1}'` -lt 30 ]; then
            STYLE="linespoints"
        else
            STYLE="lines"
        fi
        gnuplot <<EOF
            set terminal png small size 480,360
            set key top box
            set style data $STYLE
            set title "-- $TITLE --"
            set yrange $YRANGE
            set grid
            set timefmt "%H:%M:%S"
            set format x "%H h\n%M:%S"
            set xdata time
            set output "$OUTPUT"
            $PLOT
EOF
    done
}

#============================== MAIN FUNCTION ===========================
# check if result.data is a blank file
[ -s $BASE_DIR/Result/$TEST_LOG_NAME/result.data ] || { echo "No data collected, the report won't be generated."; exit 1; }

# build graph
setGraph

# build report
[ -f $BASE_DIR/Templates/${REPORT_TYPE}.htm ] || { echo "Templates ${REPORT_TYPE} is not supported in this version"; exit 1; }

# Server Info
record_num=`wc -l $BASE_DIR/Result/$TEST_LOG_NAME/result.data | awk '{print $1}'`
duration=$(( $record_num * $SAMPLING_DENSITY ))
test_start=`head -n 1 $BASE_DIR/Result/$TEST_LOG_NAME/result.data | awk '{print $1}'`

# Stat data
stat="<table>"
stat="$stat""<tr>"`sed -n '1p' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{for(i=1; i<=NF; i++) print "<td>"$i"<\/td>"}'`"<\/tr>" # First line
stat="$stat""<tr>"`sed -n '$p' $BASE_DIR/Result/$TEST_LOG_NAME/result.stat | awk '{for(i=1; i<=NF; i++) print "<td>"$i"<\/td>"}'`"<\/tr>" # Second line
stat="$stat""<\/table>"
stat=`echo "$stat" | tr -d "\n"` # remove \n

# Graph image
graph=`for img in $BASE_DIR/Result/$TEST_LOG_NAME/*.png; do echo -n "<img src=$(basename $img)><\/img> "; done;`

# raw data
raw_data="<a href=result.data>View Raw Data<\/a>"

# Build the html report
sed 's/<!-- TITLE -->/Mpstat Statistic/g;
     s/<!-- SERVER_ADDR -->/'"${SERVER_ADDR}"'/g;
     s/<!-- SERVER_PLATFORM -->/'"${SERVER_PLATFORM}"'/g;
     s/<!-- TEST_START -->/'"${test_start}"'/g;
     s/<!-- TEST_DURATION -->/'"${duration}"'/g;
     s/<!-- STAT -->/'"${stat}"'/g;
     s/<!-- GRAPH -->/'"${graph}"'/g;
     s/<!-- RAW_DATA -->/'"${raw_data}"'/g;' $BASE_DIR/Templates/${REPORT_TYPE}.htm > $BASE_DIR/Result/$TEST_LOG_NAME/index.htm

