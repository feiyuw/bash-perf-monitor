#========================================================================
# Author: Charlse.Zhang
# Email: feiyuw@gmail.com
# Created Time: 2007年11月13日 星期二 15时50分50秒
# File Name: sarReport.sh
# Description: 
#========================================================================
#!/bin/bash
. $(dirname $0)/../config

#=============================== SET PARTS ==============================
# build the graph using gnuplot, need four parameters.
setGnuplot()
{
    [ $# -ne 5 ] && { echo "Function setGnuplot parameter error"; exit $RUNTIME_ERROR; }
    TITLE=$1
    PLOT=$2
    YRANGE=$3
    OUTPUT=$4
    STYLE=$5

    gnuplot <<EOF
        set terminal png small size 480,360
        set key below horizontal box
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
}
#生成png格式的图表的方法，传入一个参数
setGraph()
{
    # check the number of parameter
    [ $# -ne 1 ] && { echo "Function setGraph parameter error"; exit $RUNTIME_ERROR; }

    # set variables
    TITLE=""
    PLOT=""
    YRANGE="[-1:]"
    OUTPUT="$BASE_DIR/Result/$TEST_LOG_NAME/sar_$1.png"
    case "$SERVER_PLATFORM" in
        *[Ll][Ii][Nn][Uu][Xx]* )
        SAR_CPU=("%user" "%nice" "%system" "%iowait" "%idle")
        SAR_MEMORY=("kbmemfree" "kbmemused" "%memused" "kbbuffers" "kbcached" "kbswpfree" "kbswpused" "%swpused" "kbswpcad")
        SAR_NETWORK=("rxpck/s" "txpck/s" "rxbyt/s" "txbyt/s" "rxcmp/s" "txcmp/s" "rxmcst/s")
        SAR_IO=("tps" "rtps" "wtps" "bread/s" "bwrtn/s")
        SAR_KERNEL=("dentunusd" "file-sz" "inode-sz" "super-sz" "%super-sz" "dquot-sz" "%dquot-sz" "rtsig-sz" "%rtsig-sz")
        SAR_PROCESS=("runq-sz" "plist-sz" "ldavg-1" "ldavg-5" "ldavg-15")
        SAR_PAGE=("pgpgin/s" "pgpgout/s" "fault/s" "majflt/s")
        ;;
        * )
        echo "Platform $SERVER_PLATFORM is not supported in this version"
        exit 1
        ;;
    esac
    if [ `wc -l $BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data | awk '{print $1}'` -lt 30 ]; then
        STYLE="linespoints"
    else
        STYLE="lines"
    fi

    # create graph
    case "$1" in
       "cpu" )
       TITLE="cpu"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data' using 1:3 title '${SAR_CPU[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data' using 1:4 title '${SAR_CPU[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data' using 1:5 title '${SAR_CPU[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data' using 1:6 title '${SAR_CPU[3]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data' using 1:7 title '${SAR_CPU[4]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;

       "memory" )
       TITLE="memory"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:2 title '${SAR_MEMORY[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:3 title '${SAR_MEMORY[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:4 title '${SAR_MEMORY[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:5 title '${SAR_MEMORY[3]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:6 title '${SAR_MEMORY[4]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:7 title '${SAR_MEMORY[5]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:8 title '${SAR_MEMORY[6]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:9 title '${SAR_MEMORY[7]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data' using 1:10 title '${SAR_MEMORY[8]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;

       # more than one interfaces, need more than one graph
       "network" )
       for file in $BASE_DIR/Result/$TEST_LOG_NAME/network.*.result.data
       do
           TITLE=`basename $file | awk -F . '{print $2}'`
           OUTPUT="$BASE_DIR/Result/$TEST_LOG_NAME/sar_$1_$TITLE.png"
           PLOT="plot '$file' using 1:3 title '${SAR_NETWORK[0]}', \
           '$file' using 1:4 title '${SAR_NETWORK[1]}', \
           '$file' using 1:5 title '${SAR_NETWORK[2]}', \
           '$file' using 1:6 title '${SAR_NETWORK[3]}', \
           '$file' using 1:7 title '${SAR_NETWORK[4]}', \
           '$file' using 1:8 title '${SAR_NETWORK[5]}', \
           '$file' using 1:9 title '${SAR_NETWORK[6]}'"
           setGnuplot "network - $TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       done
       ;;

       "io" )
       TITLE="io"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/io.result.data' using 1:2 title '${SAR_IO[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/io.result.data' using 1:3 title '${SAR_IO[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/io.result.data' using 1:4 title '${SAR_IO[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/io.result.data' using 1:5 title '${SAR_IO[3]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/io.result.data' using 1:6 title '${SAR_IO[4]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;

       "kernel" )
       TITLE="kernel"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:2 title '${SAR_KERNEL[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:3 title '${SAR_KERNEL[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:4 title '${SAR_KERNEL[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:5 title '${SAR_KERNEL[3]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:6 title '${SAR_KERNEL[4]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:7 title '${SAR_KERNEL[5]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:8 title '${SAR_KERNEL[6]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:9 title '${SAR_KERNEL[7]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data' using 1:10 title '${SAR_KERNEL[8]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;
       
       "process" )
       TITLE="process"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/process.result.data' using 1:2 title '${SAR_PROCESS[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/process.result.data' using 1:3 title '${SAR_PROCESS[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/process.result.data' using 1:4 title '${SAR_PROCESS[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/process.result.data' using 1:5 title '${SAR_PROCESS[3]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/process.result.data' using 1:6 title '${SAR_PROCESS[4]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;

       "page" )
       TITLE="page"
       PLOT="plot '$BASE_DIR/Result/$TEST_LOG_NAME/page.result.data' using 1:2 title '${SAR_PAGE[0]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/page.result.data' using 1:3 title '${SAR_PAGE[1]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/page.result.data' using 1:4 title '${SAR_PAGE[2]}', \
       '$BASE_DIR/Result/$TEST_LOG_NAME/page.result.data' using 1:5 title '${SAR_PAGE[3]}'"
       setGnuplot "$TITLE" "$PLOT" "$YRANGE" "$OUTPUT" "$STYLE"
       ;;

       * )
       echo "Error! Parameter must one of the values below: "
       echo "1) cpu, 2) memory, 3) network, 4) io, 5) process, 6) page, 7) kernel"
       exit 1
       ;;

    esac

}

#============================== MAIN FUNCTION ===========================
# check if result.data is a blank file
[ -s $BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/memory.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/kernel.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/process.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/page.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/network.result.data -a -s $BASE_DIR/Result/$TEST_LOG_NAME/io.result.data ] ||
{ echo "No data collected, the report won't be generated."; exit 1; }

# build graph
setGraph "cpu"
setGraph "memory"
setGraph "network"
setGraph "io"
setGraph "kernel"
setGraph "process"
setGraph "page"

# build report
[ -f $BASE_DIR/Templates/${REPORT_TYPE}.htm ] || { echo "Templates ${REPORT_TYPE} is not supported in this version"; exit 1; }

# Server Info
record_num=`wc -l $BASE_DIR/Result/$TEST_LOG_NAME/cpu.result.data | awk '{print $1}'`
duration=$(( $record_num * $SAMPLING_DENSITY ))
test_start=`head -n 1 $BASE_DIR/Result/$TEST_LOG_NAME/cpu.stat.data | awk '{print $1}'`

# Stat data
stat=""
for file in $BASE_DIR/Result/$TEST_LOG_NAME/*.stat.data
do
    stat="$stat""<table><tr><td colspan="$( awk 'END {print NF}' $file )">"$( basename $file | awk -F . '{print $1}' )"</td></tr>"
    for (( line=1; line<=$( wc -l $file | awk '{print $1}' ); line++ ))
    do
        stat="$stat""<tr>"`sed -n $line'p' $file | awk '{for(i=1; i<=NF; i++) print "<td>"$i"</td>"}'`"</tr>" 
    done
    stat="$stat""</table><br />"
done
stat=`echo "$stat" | tr -d "\n" | sed 's/\//\\\\\\//g; s/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]//g;'` # remove \n

# Graph image
graph=`for img in $BASE_DIR/Result/$TEST_LOG_NAME/*.png; do echo -n "<img src=$(basename $img)><\/img> "; done;`

# raw data
raw_data=`for data in $BASE_DIR/Result/$TEST_LOG_NAME/*.result.data; do echo -n "<a href=$(basename $data)>View Raw Data ( "$(basename $data | awk -F . '{if($1=="network") {print $1" - "$2} else {print $1}}')" )<\/a><br \/>"; done;`
#"<a href=result.data>View Raw Data<\/a>"

# Build the html report
sed 's/<!-- TITLE -->/Sar Statistic/g;
     s/<!-- SERVER_ADDR -->/'"${SERVER_ADDR}"'/g;
     s/<!-- SERVER_PLATFORM -->/'"${SERVER_PLATFORM}"'/g;
     s/<!-- TEST_START -->/'"${test_start}"'/g;
     s/<!-- TEST_DURATION -->/'"${duration}"'/g;
     s/<!-- STAT -->/'"${stat}"'/g;
     s/<!-- GRAPH -->/'"${graph}"'/g;
     s/<!-- RAW_DATA -->/'"${raw_data}"'/g;' $BASE_DIR/Templates/${REPORT_TYPE}.htm > $BASE_DIR/Result/$TEST_LOG_NAME/index.htm

