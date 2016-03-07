cd "$( dirname "${BASH_SOURCE[0]}" )"

cp ../_bin/latest/influxd .

docker build -t kubernetesonarm/influxdb .