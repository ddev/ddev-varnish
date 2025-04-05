// #ddev-generated
// Our Backend - Assuming that web server is listening on port 80
// Replace the host to fit your setup
//
// For additional example see:
// https://github.com/ezsystems/ezplatform/blob/master/doc/docker/entrypoint/varnish/parameters.vcl

backend ezplatform {
    .host = "web"; //
    .port = "80";
}

acl invalidators {
    "127.0.0.1";
    "0.0.0.0"/0;
}

acl debuggers {
    "127.0.0.1";
    "0.0.0.0"/0;
}