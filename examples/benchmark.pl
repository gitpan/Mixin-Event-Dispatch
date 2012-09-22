#!/usr/bin/env perl
use strict;
use warnings;
package Via::Inheritance;
use parent qw(Mixin::Event::Dispatch);

# no need for this peskiness
use constant EVENT_DISPATCH_ON_FALLBACK => 0;

sub new { bless {}, shift }

package main;
use Benchmark qw(:hireswallclock cmpthese);
use Mixin::Event::Dispatch::Event;

my $obj = Via::Inheritance->new;
$obj->add_handler_for_event(
	invoke => sub {
		my $self = shift;
	},
);
$obj->add_handler_for_event(
	two => sub {
		my $self = shift;
	},
) for 1..2;
$obj->subscribe_to_event(
	subscribe => sub {
		my $ev = shift;
	},
);
cmpthese -3 => {
	subscribe => sub {
		$obj->subscribe_to_event(
			subscriber => sub { },
		);
	},
	add_handler => sub {
		$obj->add_handler_for_event(
			add_handler => sub { },
		);
	},
	invoke => sub {
		$obj->invoke_event('invoke')
	},
	invoke_two => sub {
		$obj->invoke_event('two')
	},
	invoke_missing => sub {
		$obj->invoke_event('missing')
	},
	invoke_subscription => sub {
		$obj->invoke_event('subscribe')
	},
	instantiate_event => sub {
		Mixin::Event::Dispatch::Event->new(
			name => 'some_event',
			instance => $obj,
			handlers => [ sub {}, sub {} ],
		);
	},
	bless_event => sub {
		bless {
			name => 'some_event',
			instance => $obj,
			handlers => [ sub {}, sub {} ],
		}, 'Mixin::Event::Dispatch::Event';
	}
};

warn "done\n";

