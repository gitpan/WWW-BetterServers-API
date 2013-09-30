#-*- mode: cperl -*-#
use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('WWW::BetterServers::API') };

#########################

my $api_id    = $ENV{API_ID};
my $secret    = $ENV{API_SECRET};
my $auth_type = $ENV{AUTH_TYPE};
my $api_host  = $ENV{API_HOST} || 'api.betterservers.com';

SKIP: {
    skip("API_ID, API_SECRET, AUTH_TYPE environment vars not set", 5)
      unless $api_id and $secret and $auth_type;

#    print STDERR "Using $api_id, $secret, $auth_type, $api_host\n";

    my $api = new WWW::BetterServers::API(api_id     => $api_id,
                                          api_secret => $secret,
                                          auth_type  => $auth_type,
                                          api_host   => $api_host);

    ## run (non-blocking) requests in parallel
    my $delay = Mojo::IOLoop->delay;

    {
        my $end = $delay->begin(0);
        $api->request(method   => "GET",
                      uri      => "/v1/accounts/$api_id/diskofferings",
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 200, "status good" );
                                        like( $tx->res->body, qr("storagetype"), "content good" );
                                        $end->() });
    }

    {
        my $end = $delay->begin(0);
        $api->request(method   => "GET",
                      uri      => "/v1/accounts/$api_id",
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 200, "status good" );
                                        ok( $tx->res->json('/api_id'), "api id found" );
                                        $end->() });
    }

    $delay->wait;

    ## blocking request
    my $res = $api->request(method  => "POST",
                            uri     => "/v1/accounts/$api_id/auth_token",
                            payload => { duration => 30 });

    ok( $res->json('/token'), "good token" );
}
