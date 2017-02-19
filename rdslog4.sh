host=10.101.167.102
ports="3305 3306 3307 3308"
script=$(basename $0)
command=$1

if [ "$command" = "start" ]
then
    for port in $ports
    do
        nohup ./sysbench/sysbench --test=./sysbench/tests/db/rdslogs4.lua  --mysql-host=$host --mysql-port=$port --mysql-user=xiangluo --mysql-password=123456 --mysql-db=xiangluo --num-threads=8 --max-requests=0 --max-time=3600  --oltp-table-size=10000 --oltp-tables-count=1 --report-interval=10 --mysql-table_engine=tokudb --oltp_bulk_insert_batch_size=300 run >log/${host}_${port}.log 2>&1 &

    done
elif [ "$command" = "stop" ]
then
    for pid in $(pgrep -f rdslogs4.lua)
    do
        kill $pid
    done
else
    echo "Usage: $script <start|stop>"
fi

