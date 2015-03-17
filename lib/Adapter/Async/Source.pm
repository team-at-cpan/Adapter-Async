package Adapter::Async::Source;

use strict;
use warnings;

=head1 NAME

Adapter::Async::Source - interface for acting as a source to other
streams.

=head1 SYNOPSIS

 my $src = Adapter::Async::Source->from_stream($stream);
 $sink->from($src);
 $src->start;

=head1 DESCRIPTION

Stream::Interface::Sink
Stream::Interface::Source

Adapter::Async - IO::Async stream support for L<Stream::Interface>
Stream::POE - POE stream support for L<Stream::Interface>
Stream::Reflex - POE stream support for L<Stream::Interface>

When the sink is ready to write data, we start writing.
If the sink is no longer ready to accept data, we pause.

The source attempts to write to the sink - each time it has a block
ready, it'll send it directly to the sink.

sendfile:

 sendfile $src, $dst, $self->chunk_size;

If the sink is about to block, it calls source ->pause.
Sink calls source when it's ready to accept more data via ->resume.

Source data types:

=head3 Arrayref

=head3 File name

This will be opened as a file handle.

=head3 File handle

=head3 Coderef

=head3 Scalar ref

This will be treated as a byte buffer, similar to arrayref

=cut

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	$self->{ref_handlers} = {
		# Treat as string
		SCALAR => sub {
			my ($self, $item) = @_;
			$self->{data} = $$item;
		},
		# For an array, we iterate
		ARRAY => sub {
			my ($self, $item) = @_;
			$self->handle_item($item)->then(
			$self->{data} = $$item;
		},
		# Probably a filehandle
		GLOB => sub {

		},
		# With a regexp, we... uh. we don't?
		Regexp => sub {

		},
	}
	$self;
}

sub ref_handler {
	my ($self, $in) = @_;
	$self->{ref_handlers}->{Scalar::Util::blessed($in) || ref($in) // ''}
}

sub from {
	my ($self, $in) = splice @_, 0, 2;
	$self = $self->new unless ref $self;
	if(my $handler = $self->ref_handler($in)) {
		$handler->($self, $in, @_);
		return $self;
	} else {
		return $self;
	}
}

sub future {
	my $self = shift;
	$self->{future} ||= $self->{new_future} ? $self->{new_future}->($self) : Future->new;
}

sub wrap_string {
	my $class = shift;
	my $string = shift;
	my $self = bless {
		buffer => \$string,
	}, $class
}

sub attach_to_sink {
	my $self = shift;
	my $sink = shift;
}

=head2 bytes_available

Returns the number of bytes we have ready to write immediately.
May be zero.

=cut

sub bytes_available {
	my $self = shift;
	length ${$self->{buffer}}
}

1;

__END__

=head1 Integration with other modules

=head2 HOP::Stream

=head2 DSlib

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.

