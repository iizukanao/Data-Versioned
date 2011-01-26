package Data::Versioned::Circular;

=encoding utf-8

=head1 NAME

Data::Versioned::Circular - Maintain revision history of data as circular buffer

=head1 SYNOPSIS

  use Data::Versioned::Circular;

  my $data = Data::Versioned::Circular->new(size => 10);

  $data->set('name', 'Taro');  # revision is raised to 1
  print "revision: " . $data->get_last_rev('name') . "\n";  # prints 1

  $data->set('name', 'Jiro');
  print "revision: " . $data->get_last_rev('name') . "\n";  # prints 2

  print "latest: " . $data->get_last_data('name') . "\n";  # prints Jiro
  print "rev 1: " . $data->get_rev_data('name', 1) . "\n"; # prints Taro
  print "rev 2: " . $data->get_rev_data('name', 2) . "\n"; # prints Jiro

  my @revs = $data->get_available_revs('name');  # @revs = (1, 2)

  $data->delete_rev_older_than('name', 2);       # deletes revision < 2

  @revs = $data->get_available_revs('name');     # @revs = (2)

=head1 DESCRIPTION

Data::Versioned::Circular is a hash reference with data versioning.
It acts like an tiny key-value storage with history.
Its data reside only on memory.

=cut

use strict;
use warnings;
our $VERSION = '0.01';

use base 'Data::Versioned';
use Carp;
use Data::CircularBuffer;

=head1 METHODS

=head2 new

Returns new container.

=cut

sub new {
    my ($class, %args) = @_;

    return bless {
        revdata => {},
        size    => 10,
        %args,
    }, $class;
}

=head2 clear

Clears all data.

=cut

sub clear {
    my ($self) = @_;

    $self->{revdata} = {};
    return;
}

=head2 get_data_history

Returns all data value.

    my $values = $data->get_data_history('name');

=cut

sub get_data_history {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $buffer = $self->_get_cb($name);
    if ($buffer) {
        return $buffer->get_data;
    }
    return [];
}

sub _get_cb {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $buffer;
    my $struct = $self->{revdata}->{$name};
    if ($struct) {
        $buffer = $struct->{data};
    }
    return $buffer;
}

=head2 get_available_revs

    my $revs = $data->get_available_revs('name');

=cut

sub get_available_revs {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $buffer = $self->_get_cb($name);
    unless ($buffer) {
        return [];
    }
    my $num = $buffer->get_data_length;
    my @revs;
    if ( $num > 0 ) {
        my $last_rev = $self->{revdata}->{$name}->{headrev} || 0;
        @revs = reverse ($last_rev-$num+1 .. $last_rev);
    }
    return \@revs;
}

=head2 get_rev_data

    my $value = $data->get_rev_data('name', 3);  # 3 is the revision to get

=cut

sub get_rev_data {
    my ($self, $name, $revision) = @_;
    croak "name parameter must be specified" unless defined $name;
    croak "revision parameter must be specified" unless defined $revision;

    my $struct = $self->{revdata}->{$name};
    unless ($struct) {
        carp "get_rev_data($name, $revision): data is not initialized";
        return;
    }
    my $buffer = $struct->{data};
    unless ($buffer) {
        carp "get_rev_data($name, $revision): data is not initialized";
        return;
    }
    my $last_rev = $struct->{headrev} || 0;
    my $look_back = $last_rev - $revision;
    return $buffer->get_previous($look_back);
}

=head2 replace_rev_data

Replace existing revision value.

    $data->replace_rev_data('name', 3, 'value');

=cut

sub replace_rev_data {
    my ($self, $name, $revision, $value) = @_;
    croak "name parameter must be specified" unless defined $name;
    croak "revision parameter must be specified" unless defined $revision;

    my $struct = $self->{revdata}->{$name};
    unless ($struct) {
        carp "get_rev_data($name, $revision): data is not initialized";
        return;
    }
    my $buffer = $struct->{data};
    unless ($buffer) {
        carp "get_rev_data($name, $revision): data is not initialized";
        return;
    }
    my $last_rev = $struct->{headrev} || 0;
    my $look_back = $last_rev - $revision;
    $buffer->set_previous($look_back, $value);
    return;
}

=head2 set

Set the new value for the key.

    $data->update('name', 'value');

=cut

sub set {
    my ($self, $name, $value) = @_;
    croak "name parameter must be specified" unless defined $name;

    $self->{revdata}->{$name}->{headrev}++;
    my $buffer = $self->{revdata}->{$name}->{data};
    unless ($buffer) {
        $buffer = $self->{revdata}->{$name}->{data} = Data::CircularBuffer->new(
            size => $self->{size}
        );
    }
    $buffer->offer($value);
    return;
}

=head2 get_last_data

Returns the data which has been set most recently.

    my $value = $data->get_last_data('name');

=cut

sub get_last_data {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $buffer = $self->_get_cb($name);
    unless ($buffer) {
        return;
    }
    return $buffer->peek;
}

=head2 get_last_rev

Returns the latest revision.

    my $rev = $data->get_last_rev('name');

=cut

sub get_last_rev {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $struct = $self->{revdata}->{$name};
    unless ($struct) {
        return 0;
    }
    return $struct->{headrev} || 0;
}

=head2 delete_rev_older_than

Delete revisions that are older than specified value.

    $data->delete_rev_older_than('name', 2);

=cut

# optimization of this method is not critical
# because basically circular buffer per se is optimized
# so user may not need to call this method.
sub delete_rev_older_than {
    my ($self, $name, $least_revision) = @_;
    croak "name parameter must be specified" unless defined $name;
    croak "least_revision parameter must be specified" unless defined $least_revision;

    my $struct = $self->{revdata}->{$name};
    my $last_rev = $struct->{headrev} || 0;
    my $remain = $last_rev - $least_revision + 1;
    if ($remain < 0) {
        $remain = 0;
    }
    my $buffer = $self->_get_cb($name);
    if ($buffer) {
    }
    my $removal = $buffer->get_data_length - $remain;
    foreach my $i (1..$removal) {
        if ( $buffer->poll ) {
            last;
        }
    }
    return;
}

=item2 clear_revs

Clear all revision history for the key.
Head revision number is kept intact.

=cut

sub clear_revs {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    my $buffer = $self->_get_cb($name);
    if ($buffer) {
        $buffer->clear;
    }
    return;
}

=item2 remove

Delete all data (including revisions) for the key.

    $data->remove('name');

=cut

sub remove {
    my ($self, $name) = @_;
    croak "name parameter must be specified" unless defined $name;

    delete $self->{revdata}->{$name};
    return;
}

1;
__END__

=over 4

=back

=head1 AUTHOR

Nao Iizuka E<lt>iizuka@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
