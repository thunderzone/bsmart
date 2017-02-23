#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my $filename = shift;
$filename //= './kittens.in';
open(my $fh, '<', $filename);

my $cache_servers = [
    {
        id => 0,
        size => 10000,
    },
    {
        id => 1,
        size => 1000,
    },
];
my $videos = [
    {
        id => 0,
        size => 1000,
    },
    {
        id => 1,
        size => 500,
    },
];
my $endpoints = [
    {
        id => 0,
        latency => 1000,
        caches => [
            {
                cache_id => 0,
                latency => 500,
            },
            {
                cache_id => 1,
                latency => 700,
            },
        ],
    },
    {
        id => 1,
        latency => 500,
        caches => [],
    }
];
my $requests = [
    {
        endpoint_id => 0,
        video_id => 0,
        number => 500,
    },
    {
        enpoint_id => 0,
        video_id => 1,
        number => 2000,
    },
    {
        endpoint_id => 1,
        video_id => 0,
        number => 100,
    }
];

# process the time saved
my $enpoint_to_cache_latency_save = {};
for my $endpoint (@$endpoints) {
    my $default_latency = $endpoint->{latency};
    for my $cache (@{$endpoint->{caches}}) {
        $enpoint_to_cache_latency_save->{$cache->{cache_id}} = $default_latency - $cache->{latency};
    }
}

