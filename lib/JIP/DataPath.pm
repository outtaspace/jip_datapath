package JIP::DataPath;

use base qw(Exporter);

use strict;
use warnings;

use JIP::ClassField;
use Carp qw(croak);
use English qw(-no_match_vars);

our $VERSION = '0.01';

our @EXPORT_OK = qw(path);

has document => (get => q{+}, set => q{-});

sub path {
    my ($document) = @ARG;

    return __PACKAGE__->new(document => $document);
}

sub new {
    my ($class, %param) = @ARG;

    # Mandatory params
    croak q{Mandatory argument "document" is missing}
        unless exists $param{'document'};

    return bless({}, $class)->_set_document($param{'document'});
}

sub get {
    my ($self, $path_parts) = @ARG;

    return $self->document
        if @{ $path_parts } == 0;

    my ($contains, $context) = $self->_accessor($path_parts);

    if ($contains) {
        my $last_part = $path_parts->[-1] // q{};
        my $type      = ref $context      // q{};

        if ($type eq 'HASH' && length $last_part) {
            return $context->{$last_part};
        }
        elsif ($type eq 'ARRAY' && $last_part =~ m{^\d+$}x) {
            return $context->[$last_part];
        }
    }

    return;
}

sub contains {
    my $self = shift;

    my ($contains) = $self->_accessor(@ARG);

    return $contains;
}

sub set {
    my ($self, $path_parts, $value) = @ARG;

    if (@{ $path_parts } == 0) {
        $self->_set_document($value);
        return 1;
    }

    my ($contains, $context) = $self->_accessor($path_parts);

    if ($contains) {
        my $last_part = $path_parts->[-1] // q{};
        my $type      = ref $context      // q{};

        if ($type eq 'HASH' && length $last_part) {
            $context->{$last_part} = $value;
            return 1;
        }
        elsif ($type eq 'ARRAY' && $last_part =~ m{^\d+$}x) {
            $context->[$last_part] = $value;
            return 1;
        }
    }

    return 0;
}

sub _accessor {
    my ($self, $path_parts) = @ARG;

    my $context    = $self->document;
    my $last_index = $#{ $path_parts };

    foreach my $part_index (0 .. $last_index) {
        my $part = $path_parts->[$part_index];
        my $type = ref $context // q{};
        my $last = $part_index == $last_index;

        if ($type eq 'HASH' && exists $context->{$part}) {
            return 1, $context if $last;

            $context = $context->{$part};
        }
        elsif ($type eq 'ARRAY' && $part =~ m{^\d+$}x && @{ $context } > $part) {
            return 1, $context if $last;

            $context = $context->[$part];
        }
        else {
            return 0, undef;
        }
    }

    return 1, $context;
}

1;

