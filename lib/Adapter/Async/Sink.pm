package Data::Aliran::Sink;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.001';

=head1 NAME

Data::Aliran::Sink - interface for receiving data

=head1 SYNOPSIS

=head1 DESCRIPTION

=over 4

=item * Socket - we write incoming data to the socket

=item * File - data is written directly to the file

=item * Array - each new piece of data we read is pushed into an array

=item * Scalar - all data ends up in a string

=back

Start writing data.
On timeout, cancel the source.
On completion, mark future as done.

We tell the source to send us data. Once the source has sent us data,
we tell it to send again, until we hit the high watermark.

on_write_ready => $self->write_next_chunk

sub recv {
	my $self = shift;
	$self->{buffer} .= shift;
	$source->pause if length $self->{buffer} > HIGH_WATERMARK;
}

sub write_next_chunk {
	my $self = shift;
	$output->write(substr $self->{buffer}, 0, min(CHUNK, length), '');
	$source->resume if $source->is_paused && length $self->{buffer} <= LOW_WATERMARK;
}

# source

sub update {
	my $self = shift;
	$sink->recv($data);
}

=cut

use curry::weak;

use constant DEFAULT_LOW_WATERMARK  =>  4096;
use constant DEFAULT_HIGH_WATERMARK => 65536;

=head1 METHODS

=cut

sub attach_source {
	my $self = shift;
	my $src = shift;
}

#sub {
#	my $self = shift;
##	$self->source->
#}

sub wrap_stream {
	my $class = shift;
	my $stream = shift;
	my $self = bless {
	}, $class;
	$stream->configure(
		on_read => $self->curry::weak::on_read,
	);
	say "wrapped";
	$self;
}

sub on_read {
	my $self = shift;
	my ($stream, $buffref, $eof) = @_;
	while($$buffref =~ s/^([^\n\r]+)[\n\r]+//) {
		say "Line: $1";
	}

	if( $eof ) {
		say "EOF";
	}

	return 0;
}

sub source {
	my $self = shift;
	return $self->{source} unless @_;
	$self->{source} = my $source = shift;
	$source->attach_to_sink($self);
	return $self;
}

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.

...

translations, filters
byte accounting
bandwidth control
priority hierarchy

transports:
* IAstream
* IAsocket
* udp

discard $x => 'Client connection';

for(@_) {
say and next unless ref;
weaken(my $copy = $_);
undef $_;
die $copy if defined $copy;
}

cc ssl client verification
fork/thread for code or external pipe
rate limiting - N packets/sec, consolidate existing data on write

