#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;

#my $filename = shift;
#$filename //= './kittens.in';
#open(my $fh, '<', $filename);
#
#my $cache_size = 1000;
#
#my $cache_servers = [
#    {
#        id => 0,
#        size => 10000,
#    },
#    {
#        id => 1,
#        size => 1000,
#    },
#];
#my $videos = [
#    {
#        id => 0,
#        size => 1000,
#    },
#    {
#        id => 1,
#        size => 500,
#    },
#];
#my $endpoints = [
#    {
#        id => 0,
#        latency => 1000,
#        caches => [
#            {
#                cache_id => 0,
#                latency => 500,
#            },
#            {
#                cache_id => 1,
#                latency => 700,
#            },
#        ],
#    },
#    {
#        id => 1,
#        latency => 700,
#        caches => [
#            {
#                cache_id => 0,
#                latency => 500,
#            },
#        ],
#    }
#];
#my $requests = [
#    {
#        endpoint_id => 0,
#        video_id => 0,
#        count => 500,
#    },
#    {
#        endpoint_id => 0,
#        video_id => 1,
#        count => 2000,
#    },
#    {
#        endpoint_id => 1,
#        video_id => 0,
#        count => 100,
#    }
#];

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

my $endpoints = \@endpoints;
my $cache_servers = [map {+{id => $_}} (0..$nr_caches-1)];
my $requests = \@requests;
my $videos = \@videos;
my $cache_size = $cache_capacity_mb;

#my %output = (
#    nr_videos => $nr_videos,
#    nr_endpoints => $nr_endpoints,
#    nr_requests => $nr_requests,
#    nr_caches => $nr_caches,
#    cache_capacity_mb => $cache_capacity_mb,
#    videos => \@videos,
#    endpoints => \@endpoints,
#    requests => \@requests,
#);

# process the time saved
my $enpoint_to_cache_latency_save = {};
for my $endpoint (@$endpoints) {
    my $default_latency = $endpoint->{latency};
    for my $cache (@{$endpoint->{caches}}) {
        $enpoint_to_cache_latency_save->{$cache->{cache_id}} = $default_latency - $cache->{latency};
    }
}

my $endpoint_to_video_requests_number = {};
for my $request (@$requests) {
    my $endpoint_id = $request->{endpoint_id};
    my $video_id = $request->{video_id};
    $endpoint_to_video_requests_number->{$endpoint_id}->{$video_id} = $request->{count};
}

my $video_sizes = {};
for my $video (@$videos) {
    my $video_id = $video->{id};
    $video_sizes->{$video_id} = $video->{size};
}

#stupid greedy solution
my $result = {};

for my $cache_server (@$cache_servers) {
    my $cache_id = $cache_server->{id};
    #figure out enpoints connected
    my @endpoints_connected = ();
    for my $endpoint (@$endpoints) {
        my $is_cache_connected = scalar grep {$_->{cache_id} == $cache_id} @{$endpoint->{caches}};
        if($is_cache_connected) {
            push @endpoints_connected, $endpoint;
        }
    }

    my $wanted_videos_saving_time = {};

    for my $endpoint (@endpoints_connected) {
        my $endpoint_id = $endpoint->{id};
        for my $video_id (keys %{$endpoint_to_video_requests_number->{$endpoint_id}}) {
            my $requests_count = $endpoint_to_video_requests_number->{$endpoint_id}->{$video_id};
            $wanted_videos_saving_time->{$video_id}+=$requests_count*$enpoint_to_cache_latency_save->{$endpoint_id};
        }
    }

    for my $video_id (keys %$wanted_videos_saving_time) {
        $wanted_videos_saving_time->{$video_id} = $wanted_videos_saving_time->{$video_id} / $video_sizes->{$video_id};
    }

    my @ordered_videos_list = sort { $wanted_videos_saving_time->{$b} <=> $wanted_videos_saving_time->{$a}} keys %$wanted_videos_saving_time;

    my $size_taken = 0;
    my $videos_list = [];

    for my $video_id (@ordered_videos_list) {
        my $video_size = $video_sizes->{$video_id};
        if($size_taken + $video_size <= $cache_size) {
            $size_taken += $video_size;
            push @$videos_list, $video_id;
        }
    }

    $result->{$cache_id} = $videos_list;
}

#output
my $cache_servers_used = scalar keys %$result;
print $cache_servers_used."\n";
for my $cache_id (keys %$result) {
    print $cache_id.' '.join(' ', @{$result->{$cache_id}})."\n";
}

