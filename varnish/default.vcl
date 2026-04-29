# Simple default VCL.
#ddev-generated
# For a more advanced example see https://github.com/mattiasgeniar/varnish-6.0-configuration-templates

vcl 4.1;

backend default {
  .host = "web";
  .port = "80";
}

sub vcl_recv {
  # Pipe novarnish.* requests directly to the backend, bypassing cache and Varnish headers.
  if (req.http.Host ~ "^novarnish\.") {
    return (pipe);
  }
}
