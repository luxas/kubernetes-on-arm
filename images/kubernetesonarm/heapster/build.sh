cd "$( dirname "${BASH_SOURCE[0]}" )"

cp ../_bin/latest/heapster .

docker build -t kubernetesonarm/heapster .