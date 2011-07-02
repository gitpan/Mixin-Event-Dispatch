package Mixin::Event::Dispatch;
# ABSTRACT: Mixin methods for simple event/message dispatch framework
use strict;
use warnings;
use List::UtilsBy ();
use Try::Tiny;

our $VERSION = 0.001;

=head1 NAME

Mixin::Event::Dispatch - mixin methods for simple event/message dispatch framework

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 # Add a handler then invoke it
 my $obj = Some::Class->new;
 $obj->add_handler_for_event(some_event => sub { my $self = shift; warn "had some_event: @_"; 1; });
 $obj->invoke_event(some_event => 'message here');

 # Attach event handler for all on_XXX named parameters
 package Event::User;
 sub configure {
	my $self = shift;
	my %args = @_;
	$self->add_handler_for_event(
		map { (/^on_(.*)$/) ? ($1 => $args{$_}) : () } for keys %args
	);
	return $self;
 }

=head1 DESCRIPTION

Add this in as a parent to your class, and it'll provide some methods for defining event handlers (L</add_event_handler>) and calling them (L</invoke_event>).

=head1 METHODS

=cut


=head2 invoke_event

Takes an C<event> parameter, and optional additional parameters that are passed to any callbacks.

 $self->invoke_event('new_message', from => 'fred', subject => 'test message');

Returns $self if a handler was found, undef if not.

=cut

sub invoke_event {
	my $self = shift;
	my $ev = shift;
	my @param = @_;

# Run a given coderef for the event, returning true if it should then be removed as a handler.
	my $run_event = sub {
		my $code = shift;
		return try {
			!$code->($self, @param);
		} catch {
			die $_ if $ev eq 'event_error';
			$self->invoke_event(event_error => $_) or die "$_ and no event_error handler found";

			# Remove this event handler since it appears to be broken
			return 1;
		}
	};

	my $stack = $self->event_stack;
# If we have handlers for this event, use them directly.
	if($stack && scalar @{$stack->{$ev} || [] }) {
		# Run all the queued code for this event, removing the handlers that return false.
		List::UtilsBy::extract_by { $run_event->($_) } @{$self->event_stack->{$ev}};
		return $self;
	} elsif(my $code = $self->can("on_$ev")) {
# Otherwise check for on_event handler and use that instead.
		$run_event->($code);
		return $self;
	}
	return undef;
}

=head2 add_handler_for_event

Adds handlers to the stack for the given events.

 $self->add_handler_for_event(
 	new_message	=> sub { warn @_; 1 },
 	login		=> sub { warn @_; 1 },
 	logout		=> sub { warn @_; 1 },
 );

=cut

sub add_handler_for_event {
	my $self = shift;

# Init if we haven't got a valid event_stack yet
	$self->clear_event_handlers unless $self->event_stack;

# Add the defined handlers
	while(@_) {
		my ($ev, $code) = splice @_, 0, 2;
		push @{$self->event_stack->{$ev}}, $code;
	}
	return $self;
}

=head2 event_stack

Accessor for the event stack itself - should return a hashref which maps event names to arrayrefs for
the currently defined handlers.

=cut

sub event_stack { shift->{event_stack} }

=head2 clear_event_handlers

Removes all queued event handlers.

Will also be called when defining the first handler to create the initial L</event_stack> entry, should
be overridden by subclass if something other than $self->{event_stack} should be used.

=cut

sub clear_event_handlers {
	my $self = shift;
	$self->{event_stack} = { };
	return $self;
}

1;

__END__

=head1 SEE ALSO

There are at least a dozen similar modules already on CPAN, eventually I'll add a list of them here.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
