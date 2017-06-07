system-docker(){
    docker -H unix:///var/run/docker-bootstrap.sock "$@"
}
docker-bootstrap(){
    docker -H unix:///var/run/docker-bootstrap.sock "$@"
}
docker-rm-stopped(){ 
    docker rm $(docker ps --filter status=exited -q) 
}
