package Data::CircularBuffer;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if ( $args{size} > 0 ) {
        $self->init($args{size});
    }

    return $self;
}

sub get_data {
    my ($self) = @_;

    my @aligned;
    if ($self->is_empty) {
        return \@aligned;
    }

    # rewind head
    my $head = $self->{head} - 1;
    my $tail = $self->{tail};
    my $data = $self->{data};
    my $size = $self->{size};
    if ($head < 0) {
        $head += $size;
    }
    $head %= $size;

    # seek back till beginning of array
    if ($head < $tail) {
        while ($head >= 0) {
            push(@aligned, $data->[$head]);
            $head--;
        }
        $head = $size - 1;
    }
    while ($head >= $tail) {
        push(@aligned, $data->[$head]);
        $head--;
    }
    return \@aligned;
}

sub clone {
    my ($self) = @_;

    return __PACKAGE__->new(
        size => $self->{size},
        head => $self->{head},
        tail => $self->{tail},
        data => [ @{ $self->{data} } ],
    );
}

sub get_data_length {
    my ($self) = @_;

    my $head = $self->{head};
    my $tail = $self->{tail};
    if ($head < $tail) {
        $head += $self->{size};
    }
    return $head - $tail;
}

sub get_capacity {
    my ($self) = @_;

    return $self->{size} - 1;
}

sub expand {
    my ($self, $new_size) = @_;

    my $current_size = $self->{size};
    $new_size++;
    if ($new_size == $current_size) { # unchanged
        return;
    }

    if ($new_size < $current_size) { # about to shrink
        croak "data can not be shrinked";
        # TODO: implement shrink operation
    }

    my @new_data = reverse @{ $self->get_data };
    $self->{tail} = 0;
    $self->{head} = scalar @new_data;
    $self->{size} = $new_size;
    $self->{data} = \@new_data;
    return;
}

sub clear {
    my ($self) = @_;

    $self->{head} = 0;
    $self->{tail} = 0;
    $self->{data} = [];
    return;
}

sub init {
    my ($self, $size) = @_;

    $self->{size} = $size + 1;
    $self->{head} = 0;
    $self->{tail} = 0;
    $self->{data} = [];
    return;
}

sub is_full {
    my ($self) = @_;

    return ((($self->{head} + 1) % $self->{size}) == $self->{tail});
}

sub is_empty {
    my ($self) = @_;

    return $self->{tail} == $self->{head};
}

sub offer {
    my ($self, $value) = @_;

    my $is_full = $self->is_full;
    if ($is_full) {
        $self->poll;
    }
    $self->{data}->[ $self->{head} ] = $value;
    $self->{head}++;
    $self->{head} %= $self->{size};
    return $is_full;
}

sub poll {
    my ($self) = @_;

    my $is_empty = $self->is_empty;
    unless ($is_empty) {
        my $value = $self->{data}->[ $self->{tail} ];
        $self->{tail}++;
        $self->{tail} %= $self->{size};
    }
    return $is_empty;
}

sub peek {
    my ($self) = @_;

    return $self->get_previous(0);
}

sub get_previous {
    my ($self, $num_back) = @_;
    if ($num_back < 0) {
        carp "num_back parameter must be positive integer";
        return;
    }

    my $data_len = $self->get_data_length;
    if ($num_back >= $data_len) {
        carp "can not look back more than its capacity";
        return;
    }

    my $pos = $self->{head} - 1;
    my $size = $self->{size};
    $pos -= $num_back;
    if ($pos < 0) {
        $pos += $size;
    }
    $pos %= $size;
    return $self->{data}->[$pos];
}

sub set_previous {
    my ($self, $num_back, $value) = @_;

    my $data_len = $self->get_data_length;
    if ($num_back >= $data_len) {
        croak "Data::CircularBuffer can not look back more than its capacity";
    }
    if ($num_back < 0) {
        croak "num_back parameter must be positive integer";
    }

    my $pos = $self->{head} - 1;
    my $size = $self->{size};
    $pos -= $num_back;
    if ($pos < 0) {
        $pos += $size;
    }
    $pos %= $size;
    $self->{data}->[$pos] = $value;
    return;
}

1;
