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

                            <!-- tags -->
                            
                            <span class="glyphicon glyphicon-tags" style="padding-right: 10px"></span><span style="vertical-align: 2px"><a href="https://docs.docker.com/search/?q=docker">docker</a>, <a href="https://docs.docker.com/search/?q=example">example</a>, <a href="https://docs.docker.com/search/?q=package%20installation">package installation</a>, <a href="https://docs.docker.com/search/?q=networking">networking</a>, <a href="https://docs.docker.com/search/?q=debian">debian</a>, <a href="https://docs.docker.com/search/?q=ubuntu">ubuntu</a></span>
                            
                            
                            <div id="ratings-div" style="color: rgb(185, 194, 204); text-align: center; margin-top: 150px; visibility: visible;">
                                <div id="pd_rating_holder_8453675"></div>
                                <script type="text/javascript">
                                    PDRTJS_settings_8453675 = {
                                        "id": "8453675",
                                        "unique_id": "engine/examples/apt-cacher-ng.md",
                                        "title": "Dockerize an apt-cacher-ng service",
                                        "permalink": "https://github.com/docker/docker.github.io/blob/master/engine/examples/apt-cacher-ng.md"
                                    };
                                    (function (d, c, j) {
                                        if (!document.getElementById(j)) {
                                            var pd = d.createElement(c),
                                                s;
                                            pd.id = j;
                                            pd.src = ('https:' == document.location.protocol) ? 'https://polldaddy.com/js/rating/rating.js' : 'http://i0.poll.fm/js/rating/rating.js';
                                            s = document.getElementsByTagName(c)[0];
                                            s.parentNode.insertBefore(pd, s);
                                        }
                                    }(document, 'script', 'pd-rating-js'));
                                </script>
                            </div>
                            
                        </section>
                    </main>
                    <nav class="col-nav">
                        <div id="sidebar-nav" class="sidebar hidden-sm hidden-xs">
                            <div id="navbar" class="nav-sidebar">
    <ul class="nav jsTOCHorizontal hidden-md hidden-lg"><li id="home"><a href="https://docs.docker.com/">Home</a></li>
<li id="guides"><a href="https://docs.docker.com/develop/">Guides</a></li>
<li id="manuals"><a href="https://docs.docker.com/engine/">Product manuals</a></li>
<li id="reference"><a href="https://docs.docker.com/reference/">Reference</a></li>
<li id="samples" class="active"><a href="https://docs.docker.com/samples/">Samples</a></li>
</ul>
    <div class="divider hidden-md hidden-lg"></div>
    <ul class="nav" id="jsTOCLeftNav"><li><a href="https://docs.docker.com/samples/#tutorial-labs">Tutorial labs</a></li><li><a onclick="navClicked(2)" data-target="#item2" data-toggle="collapse" data-parent="#stacked-menu" aria-expanded="true">Sample applications<span class="caret arrow"></span></a><ul class="nav collapse in" id="#item2" aria-expanded="true"><li><a href="https://docs.docker.com/samples/">Samples home</a></li><li><a href="https://docs.docker.com/engine/examples/apt-cacher-ng/" class="active currentPage">apt-cacher-ng</a></li><li><a href="https://docs.docker.com/engine/examples/dotnetcore/">ASP.NET Core application</a></li><li><a href="https://docs.docker.com/compose/aspnet-mssql-compose/">ASP.NET Core + SQL Server on Linux</a></li><li><a href="https://docs.docker.com/engine/examples/couchdb_data_volumes/">CouchDB</a></li><li><a href="https://docs.docker.com/compose/django/">Django and PostgreSQL</a></li><li><a href="https://docs.docker.com/engine/examples/postgresql_service/">PostgreSQL</a></li><li><a href="https://docs.docker.com/compose/rails/">Rails and PostgreSQL</a></li><li><a href="https://docs.docker.com/engine/examples/running_riak_service/">Riak</a></li><li><a href="https://docs.docker.com/engine/examples/running_ssh_service/">SSHd</a></li></ul></li><li><a href="https://docs.docker.com/samples/#library-references">Library references</a></li></ul>
</div>

                        </div>
                    </nav>
                    <div class="col-toc">
                        <div class="sidebar hidden-xs hidden-sm">
                            <div class="toc-nav">
                                <div class="feedback-links">
                                    <ul>
                                        
                                        <li style="visibility: visible;"><a href="https://github.com/docker/docker.github.io/edit/master/engine/examples/apt-cacher-ng.md"><i class="fa fa-pencil-square-o" aria-hidden="true"></i> Edit this
                                                page</a></li>
                                        <li><a href="https://github.com/docker/docker.github.io/issues/new?body=File:%20[engine/examples/apt-cacher-ng.md](https://docs.docker.com/engine/examples/apt-cacher-ng/)" class="nomunge"><i class="fa fa-check" aria-hidden="true"></i> Request
                                                docs changes</a></li>
                                        <!-- toggle mode -->
                                        <li>
                                            <div class="toggle-mode">
                                                <div class="icon">
                                                    <i class="fa fa-sun-o" aria-hidden="true"></i>
                                                </div>
                                                <div class="toggle-switch">
                                                    <label class="switch">
                                                        <input type="checkbox" id="switch-style">
                                                        <div class="slider round"></div>
                                                    </label>
                                                </div>
                                                <div class="icon">
                                                    <i class="fa fa-moon-o" aria-hidden="true"></i>
                                                </div>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                                
                                
                                
                                
                                <div id="side-toc-title">On this page:</div>
                                


                                
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    
    <footer class="footer">
          
    <div class="container">
        <div class="top_footer">
            <div class="row">
                <div class="col-xs-12 col-sm-3 col-md-3">
                    <ul class="footer_links">
                        <li><b><a href="https://www.docker.com/why-docker">Why Docker</a></b></li>
                        <li><a href="https://www.docker.com/what-container">What is a Container</a></li>
                    </ul>
                </div>
                <div class="col-xs-12 col-sm-3 col-md-3">
                    <ul class="footer_links">
                        <li><b><a href="https://www.docker.com/products/overview">Products</a></b></li>
                        <li><a href="https://www.docker.com/products/docker-desktop">Docker Desktop</a></li>
                        <li><a href="https://www.docker.com/products/docker-hub">Docker Hub</a></li>
                        <li><b><a href="https://www.docker.com/products/docker-desktop">Features</a></b></li>
                        <li><a href="https://www.docker.com/products/container-runtime">Container Runtime</a></li>
                        <li><a href="https://www.docker.com/products/developer-tools">Developer Tools</a></li>
                        <li><a href="https://www.docker.com/products/kubernetes">Kubernetes</a></li>
                    </ul>
                </div>
                <div class="col-xs-12 col-sm-3 col-md-3">
                    <ul class="footer_links">
                        <li><b><a href="https://www.docker.com/products/docker-desktop">Developers</a></b></li>
                        <li><a href="https://www.docker.com/use-cases">Use Cases</a></li>
                        <li><a href="https://www.docker.com/play-with-docker">Play with Docker</a></li>
                        <li><a href="https://www.docker.com/docker-community">Community</a></li>
                        <li><a href="https://www.docker.com/open-source">Open Source</a></li>
                        <li><a href="https://www.docker.com/community/docker-captains">Docker Captains</a></li>
                    </ul>
                </div>
                <div class="col-xs-12 col-sm-3 col-md-3">
                    <ul class="footer_links">
                        <li><b><a href="https://www.docker.com/company" target="_blank">Company</a></b></li>
                        <li><a href="https://www.docker.com/company">About Us</a></li>
                        <li><a href="https://www.docker.com/blog/" target="_blank">Blog</a></li>
                        <li><a href="https://www.docker.com/customers">Customers</a></li>
                        <li><a href="https://www.docker.com/partners">Partners</a></li>
                        <li><a href="https://www.docker.com/company/newsroom">Newsroom</a></li>
                        <li><a href="https://www.docker.com/careers">Careers</a></li>
                        <li><a href="https://www.docker.com/company/contact">Contact Us</a></li>
                    </ul>
                </div>
            </div>
            <div class="footer-nav">
                <nav class="footer_sub_nav">
                    <ul class="menu">
                        <li><a href="http://status.docker.com/">Status</a></li>
                        <li><a href="https://www.docker.com/docker-security">Security</a></li>
                        <li><a href="https://www.docker.com/legal">Legal</a></li>
                        <li><a href="https://www.docker.com/company/contact">Contact</a></li>
                    </ul>
                </nav>
            </div>
        </div>
        <div class="bottom_footer">
            <div class="footer-copyright col-xs-12 col-md-8">
                <p class="copyright">
                    Copyright © 2013-2020 Docker Inc. All rights reserved. </p>
            </div>
            <div class="footer_social_nav">
                <ul class="nav-social">
                    <li class="fa fa-twitter"><a href="http://twitter.com/docker">Twitter</a></li>
                    <li class="fa fa-youtube"><a href="http://www.youtube.com/user/dockerrun">Youtube</a></li>
                    <li class="fa fa-github"><a href="https://github.com/docker">GitHub</a></li>
                    <li class="fa fa-linkedin"><a href="https://www.linkedin.com/company/docker">Linkedin</a></li>
                    <li class="fa fa-facebook"><a href="https://www.facebook.com/docker.run">Facebook</a></li>
                    <li class="fa fa-slideshare"><a href="https://www.slideshare.net/docker">Slideshare</a></li>
                    <li class="fa fa-reddit"><a href="https://www.reddit.com/r/docker">Reddit</a></li>
                </ul>
            </div>
        </div>
    </div>

    </footer>
    <link rel="stylesheet" href="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/github.css">
    
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/anchorlinks.js.download"></script>
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/menu.js.download"></script>
    <script src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/jquery.js.download"></script>
    <script src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/bootstrap.min.js.download"></script>
    <!-- Always include the archive.js, but it doesn't do much unless we are an archive -->
    <script>
        // Default to assuming this is an archive and hiding some stuff
        // See js/archive.js and js/docs.js for logic relating to this
        var isArchive = true;
        var dockerVersion = 'v19.03';
        // In archives, we need to know the page root and we get it from JEKYLL_ENV in the jekyll build command
        var jekyllEnv = 'development';
        // If unset (in non-archive branches), defaults to "development". In that case, reset it to empty
        if (jekyllEnv === 'development') {
            jekyllEnv = '';
        }
        var pageURL = jekyllEnv + '/engine/examples/apt-cacher-ng/';
    </script>
    <script src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/archive.js.download"></script>
    <script src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/stickyfill.min.js.download"></script>
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/metadata.js.download"></script>
    <script src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/glossary.js.download"></script>
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/docs.js.download"></script>
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/toc.js.download"></script>
    <script defer="" src="./Dockerize an apt-cacher-ng service _ Docker Documentation_files/search.js.download"></script>




</body></html>
