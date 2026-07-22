vcl 4.1;

import digest;

backend default {
  .host = "web";
  .port = "80";
}

sub vcl_recv {
  if (req.http.Host ~ "^novarnish\.") {
    return (pipe);
  }
}

sub vcl_deliver {
  set resp.http.X-Vmod-Test = digest.hash_sha256("ddev-varnish");
}
