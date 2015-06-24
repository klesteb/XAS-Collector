package XAS::Model::Database::Messaging::Result::Alert;

our $VERSION = '0.01';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM'
;

__PACKAGE__->load_components( qw/ InflateColumn::DateTime OptimisticLocking / );
__PACKAGE__->table( 'alert' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        sequence          => 'alert_id_seq',
        is_nullable       => 0
    },
    hostname => {
        data_type   => 'varchar',
        size        => 254,
        is_nullable => 0
    },
    datetime => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 0
    },
    level => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    facility => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    process => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    message => {
        data_type   => 'varchar',
        size        => 256,
        is_nullable => 0
    },
    pid => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0
    },
    tid => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    msgnum => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0
    },
    cleared => {
        data_type     => 'boolean',
        default_value => 'f',
        is_nullable   => 0
    },
    cleartime => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 1
    },
    revision => {
        data_type   => 'integer',
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
}

sub table_name {
    return __PACKAGE__;
}

1;
