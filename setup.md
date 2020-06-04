#saved from https://docs.docker.com/engine/examples/apt-cacher-ng/
<span class="reading-time-label">Estimated reading time:
</span> 3 minutes
</span>

<blockquote>
  <p><strong>Note</strong>:</p>
  <ul>
    <li><strong>If you don’t like sudo</strong> then see
<a href="https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user"><em>Giving non-root access</em></a>.</li>
    <li><strong>If you’re using macOS or docker via TCP</strong> then you shouldn’t use sudo.</li>
  </ul>
</blockquote>

<p>When you have multiple Docker servers, or build unrelated Docker
containers which can’t make use of the Docker build cache, it can be
useful to have a caching proxy for your packages. This container makes
the second download of any package almost instant.</p>

<p>Use the following Dockerfile:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>#
# Build: docker build -t apt-cacher .
# Run: docker run -d -p 3142:3142 --name apt-cacher-run apt-cacher
#
# and then you can run containers with:
#   docker run -t -i --rm -e http_proxy http://dockerhost:3142/ debian bash
#
# Here, `dockerhost` is the IP address or FQDN of a host running the Docker daemon
# which acts as an APT proxy server.
FROM        ubuntu

VOLUME      ["/var/cache/apt-cacher-ng"]
RUN     apt-get update &amp;&amp; apt-get install -y apt-cacher-ng

EXPOSE      3142
CMD     chmod 777 /var/cache/apt-cacher-ng &amp;&amp; /etc/init.d/apt-cacher-ng start &amp;&amp; tail -f /var/log/apt-cacher-ng/*
</code></pre></div></div>

<p>To build the image using:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker build -t eg_apt_cacher_ng .
</code></pre></div></div>

<p>Then run it, mapping the exposed port to one on the host</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker run -d -p 3142:3142 --name test_apt_cacher_ng eg_apt_cacher_ng
</code></pre></div></div>

<p>To see the logfiles that are <code class="highlighter-rouge">tailed</code> in the default command, you can
use:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker logs -f test_apt_cacher_ng
</code></pre></div></div>

<p>To get your Debian-based containers to use the proxy, you have
following options. Replace <code class="highlighter-rouge">dockerhost</code> with the
IP address or FQDN of the host running the <code class="highlighter-rouge">test_apt_cacher_ng</code>
container.</p>

<ol>
  <li>Add an apt Proxy setting
<code class="highlighter-rouge">echo 'Acquire::http { Proxy "http://dockerhost:3142"; };' &gt;&gt; /etc/apt/conf.d/01proxy</code></li>
  <li>Set an environment variable:
<code class="highlighter-rouge">http_proxy=http://dockerhost:3142/</code></li>
  <li>Change your <code class="highlighter-rouge">sources.list</code> entries to start with
<code class="highlighter-rouge">http://dockerhost:3142/</code></li>
  <li>Link Debian-based containers to the APT proxy container using <code class="highlighter-rouge">--link</code></li>
  <li>Create a custom network of an APT proxy container with Debian-based containers.</li>
</ol>

<p><strong>Option 1</strong> injects the settings safely into your apt configuration in
a local version of a common base:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>FROM ubuntu
RUN  echo 'Acquire::http { Proxy "http://dockerhost:3142"; };' &gt;&gt; /etc/apt/apt.conf.d/01proxy
RUN apt-get update &amp;&amp; apt-get install -y vim git

# docker build -t my_ubuntu .
</code></pre></div></div>

<p><strong>Option 2</strong> is good for testing, but breaks other HTTP clients
which obey <code class="highlighter-rouge">http_proxy</code>, such as <code class="highlighter-rouge">curl</code>, <code class="highlighter-rouge">wget</code> and others:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker run --rm -t -i -e http_proxy=http://dockerhost:3142/ debian bash
</code></pre></div></div>

<p><strong>Option 3</strong> is the least portable, but you might need to do it and you can do it
from your <code class="highlighter-rouge">Dockerfile</code> too.</p>

<p><strong>Option 4</strong> links Debian-containers to the proxy server using following command:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker run -i -t --link test_apt_cacher_ng:apt_proxy -e http_proxy=http://apt_proxy:3142/ debian bash
</code></pre></div></div>

<p><strong>Option 5</strong> creates a custom network of APT proxy server and Debian-based containers:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker network create mynetwork
$ docker run -d -p 3142:3142 --network=mynetwork --name test_apt_cacher_ng eg_apt_cacher_ng
$ docker run --rm -it --network=mynetwork -e http_proxy=http://test_apt_cacher_ng:3142/ debian bash
</code></pre></div></div>

<p>Apt-cacher-ng has some tools that allow you to manage the repository,
and they can be used by leveraging the <code class="highlighter-rouge">VOLUME</code>
instruction, and the image we built to run the service:</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker run --rm -t -i --volumes-from test_apt_cacher_ng eg_apt_cacher_ng bash

root@f38c87f2a42d:/# /usr/lib/apt-cacher-ng/distkill.pl
Scanning /var/cache/apt-cacher-ng, please wait...
Found distributions:
bla, taggedcount: 0
     1. precise-security (36 index files)
     2. wheezy (25 index files)
     3. precise-updates (36 index files)
     4. precise (36 index files)
     5. wheezy-updates (18 index files)

Found architectures:
     6. amd64 (36 index files)
     7. i386 (24 index files)

WARNING: The removal action may wipe out whole directories containing
         index files. Select d to see detailed list.

(Number nn: tag distribution or architecture nn; 0: exit; d: show details; r: remove tagged; q: quit): q
</code></pre></div></div>

<p>Finally, clean up after your test by stopping and removing the
container, and then removing the image.</p>

<div class="highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ docker container stop test_apt_cacher_ng
$ docker container rm test_apt_cacher_ng
$ docker image rm eg_apt_cacher_ng
</code></pre></div></div>
