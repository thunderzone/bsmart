#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my ( $nr_videos, $nr_endpoints, $nr_requests, $nr_caches, $cache_capacity_mb, @discard ) = split /\s+/, <>;

die if @discard;
my @video_sizes = split /\s+/, <>;
die "Wrong video count" unless @video_sizes == $nr_videos;

my $video_id = 0;
my @videos = map { { id => $video_id++, size => $_ } } @video_sizes;

my @endpoints;
foreach my $endpoint_id ( 0 .. $nr_endpoints - 1 )
{
    my ( $latency_dc_to_endpoint, $nr_caches_for_endpoint, @discard ) = split /\s+/, <>;
    die if @discard;
    die if $latency_dc_to_endpoint > 4000;
    die if $latency_dc_to_endpoint < 2;
    die if $nr_caches_for_endpoint > $nr_caches;

    my @endpoint_to_cache_connections;
    foreach my $connection_id ( 0 .. $nr_caches_for_endpoint - 1 )
    {
        my ( $cache_server_id, $latency_cache_to_endpoint_ms, @discard ) = split /\s+/, <>;
        die if $cache_server_id >= $nr_caches;
        die if $latency_cache_to_endpoint_ms > $latency_dc_to_endpoint;
        die if $latency_cache_to_endpoint_ms > 500;

        push @endpoint_to_cache_connections, {
            cache_id => $cache_server_id,
            latency => $latency_cache_to_endpoint_ms,
        };
    }

    push @endpoints, {
        id => $endpoint_id,
        latency => $nr_caches_for_endpoint,
        nr_caches => $nr_caches_for_endpoint,
        caches => \@endpoint_to_cache_connections,
    };
}

my @requests;
foreach my $request_id ( 0 .. $nr_requests - 1 )
{
    my ( $req_video_id, $req_endpoint_id, $request_count, @discard ) = split /\s+/, <>;
    die if @discard;
    die unless defined $req_video_id;
    die if $req_video_id >= $nr_videos;
    die if $req_endpoint_id >= $nr_endpoints;
    die if $request_count > 10000;

    push @requests, {
        video_id => $req_video_id,
        endpoint_id => $req_endpoint_id,
        count => $request_count,
    };
}

die if <>;

my %output = (
    nr_videos => $nr_videos,
    nr_endpoints => $nr_endpoints,
    nr_requests => $nr_requests,
    nr_caches => $nr_caches,
    cache_capacity_mb => $cache_capacity_mb,
    videos => \@videos,
    endpoints => \@endpoints,
    requests => \@requests,
);

# print Dumper( \%output );
