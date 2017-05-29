# Docker Images
- [bosun-from-git](bosun-from-git/dockerfile) for compiling and running [bosun](http://bosun.org) from a git repo 
- [tsdbrelay-from-git](tsdbrelay-from-git/dockerfile) same for [tsdbrelay](https://godoc.org/bosun.org/cmd/tsdbrelay)

# Monitoring Stack in Docker
```
#Remove existing containers and spin up a new monitoring stack in docker
docker rm opentsdb -f; docker run -d --name opentsdb --network=monitoring --restart=always -p 4242:4242 -p 8080:8070 -p 16010:16010 stackexchange/bosun:0.6.0-pre
docker rm bosun -f; docker run -d --name bosun --network=monitoring -p 8070:8070 -p 9565:9565 -v /home/gbray/go/src:/go/src bosun-from-git
docker rm tsdbrelay -f;docker run -d --name tsdbrelay --network=monitoring -p 5252:5252 -v /home/gbray/go/src:/go/src tsdbrelay-from-git

#Point scollector at it (linux or windows, host override or custom toml file)
/go/src/bosun.org/cmd/scollector/scollector -h mydockerserver:5252
C:\code\go\src\bosun.org\cmd\scollector\scollector.exe -conf C:\Users\gbray\Documents\scollector.docker.toml
```

# Issues
- The bosun.* and tsdbrelay.* metrics use docker id for host tags. Prevents collisions, but may want to find a way to override in config files.
- Only works with public git repos. Need to find a way to support key based authentication.
- Defaults require containers to be named specifically. Linked containers use to have ability to map names like you can with ports, need to see if there is a similar feature for networks.
