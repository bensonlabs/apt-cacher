# When you have multiple Docker servers, or build unrelated Docker containers
# which can’t make use of the Docker build cache, it can be useful to have a caching proxy for your packages. 
# This container makes the second download of any package almost instant.
# Use the following Dockerfile:

# Build: docker build -t apt-cacher .
# Run: docker run -d -p 3142:3142 --name apt-cacher-run apt-cacher
#
# and then you can run containers with:
#   docker run -t -i --rm -e http_proxy http://dockerhost:3142/ debian bash
#
# Here, `dockerhost` is the IP address or FQDN of a host running the Docker daemon
# which acts as an APT proxy server.
FROM        ubuntu

VOLUME      ["/volume1/docker/apt-cacher-ng"]
RUN     apt-get update && apt-get install -y apt-cacher-ng

EXPOSE      3142
CMD     chmod 777 /volume1/docker/apt-cacher-ng && /etc/init.d/apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*

#https://docs.docker.com/engine/examples/apt-cacher-ng/
