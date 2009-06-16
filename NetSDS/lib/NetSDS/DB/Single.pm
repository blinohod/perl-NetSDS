package NetSDS::DB::Single;
########################################################################
# $Id$
########################################################################

=head1 NAME

NetSDS::DB::Single - API для маніпулювання поодинокими об'єктами зберіганими у базі даних.

=head1 SYNOPSIS

	use NetSDS::DB::Single;
	our @ISA = qw(
	  NetSDS::DB::Single
	);

=head1 DESCRIPTION

Абстрактний клас C<NetSDS::DB::Single> реалізує маніпуляції з поодинокими об'єктами бази даних.
Призначений для породження від нього конкретних класів.

Породжений від L<NetSDS>.

=cut

use 5.8.0;
use strict;
use warnings 'all';

use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '0.1';

our @EXPORT = qw();

use NetSDS::Const;
use NetSDS::DB;

#***********************************************************************

=head1 CLASS METHODS

=over

=item B<sql_key($KEY)> - class method

Повертає розгорнутий ключ SQL-запиту

=cut

#-----------------------------------------------------------------------
sub sql_key {
	my ( $proto, $key ) = @_;
	my $class = ref($proto) || $proto;

	return $class . "::" . $key;
}

#***********************************************************************

=item B<dbm(...)>

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_class_var('dbm');

#***********************************************************************

=item B<class_init(%params)> - class method

Іниціалізація класу

=cut

#-----------------------------------------------------------------------
sub class_init {
	my ( $class, %params ) = @_;

	my $dbm = $params{dbm};
	if ($dbm) {
		unless ( ref($dbm) ) {
			$dbm = $class->application->$dbm;
			unless ($dbm) {
				return $class->error( "Wrong DBM metod %s->%s", ref( $class->application ), $dbm );
			}
		}
		$class->dbm($dbm);

		unless ( my $oka = $class->make_sql ) {
			return $oka;
		}

		return $class;
	} else {
		return $class->error( "Undefined 'dbm' parameter for class: $class" );
	}
} ## end sub class_init

#***********************************************************************

=item B<sql_config()> - class method

Повертає конкретні значення для формування запитів відповідного класу:

	table     => назва таблиці об'єкта
	seq       => автоматично генеровані дані для деяких полів у вигляді C<field_name> => C<QUERY_PART>
	fields    => список необхідних полів об'єкта, окрім ключових
	primary   => список ключових полів об'єкта (захищаються автоматично)
	secondary => список полів за якими теж можна завантажувати об'єкт (:by_field_name)

По всім полям з C<fields> та  C<key> відповідні методи створюються автоматично.

Цей метод треба перевизначати у породжених класах, відповідно до потреб

=cut

#-----------------------------------------------------------------------
sub sql_config {
	my ($this) = @_;

	return $this->error( "Abstract class used directly: " . ref($this) || $this . ' => sql_config()' );

	# подано як приклад
	return {
		table  => 'schema.obj',
		fields => {
			id => {
				ins => "NEXTVAL('schema.obj_id_seq')",
			},
			name => {
				upd => 1,
			},
			status => {
				upd => 1,
			},
			created => {
				ins => "NOW()",
			},
			modified => {
				ins => "NOW()",
				upd => 1,
			},
		},
		primary => 'by_id',
		unique  => {
			by_id   => [qw(id)],
			by_name => [qw(name)],
		},
	};
} ## end sub sql_config

#***********************************************************************

=item B<make_sql()> - class method

Створює та повертає SQL-запити та ключі для них у вигляді готовому для
підготовки у драйвері DBI.

=cut

#-----------------------------------------------------------------------
sub make_sql {
	my ($this) = @_;

	my $cfg = $this->sql_config;
	my $dbm = $this->dbm;

	my ( $table, $fields, $primary, $unique ) = @{$cfg}{qw(table fields primary unique)};

	unless ($table) {
		return $this->error( "Undefined table for '%s'", $this );
	}

	unless ( ref( $unique->{$primary} ) ) {
		return $this->error( "Undefined primary key for table '%s' in '%s'", $table, $this );
	}

	my $keyfld = $unique->{$primary};
	map { $fields->{$_}->{upd} = 0 } @{$keyfld};
	my $keyopt = join( ' AND ', map { $_ . ' = ?' } @{$keyfld} );

	my $allfld = [ sort keys %{$fields} ];
	my $allnam = join( ',', @{$allfld} );
	my $allopt = join( ',', map { '?' } @{$allfld} );

	my $updfld = [ grep { $fields->{$_}->{upd} } @{$allfld} ];
	my $updopt = join( ',', map { $_ . ' = ?' } @{$updfld} );

	my $oka = $dbm->add_preps(
		$this->sql_key("insert") => sprintf( "INSERT INTO %%s.%s (%s) VALUES (%s)", $table, $allnam, $allopt ),
		$this->sql_key("update") => sprintf( "UPDATE %%s.%s SET %s WHERE %s",       $table, $updopt, $keyopt ),
		$this->sql_key("delete") => sprintf( "DELETE FROM %%s.%s WHERE %s",         $table, $keyopt ),
	);
	unless ($oka) {
		return $oka;
	}

	while ( my ( $name, $data ) = each( %{$unique} ) ) {
		my $uniopt = join( ' AND ', map { $_ . '=?' } @{$data} );

		$oka = $dbm->add_preps( $this->sql_key("sel_$name") => sprintf( "SELECT %s FROM %%s.%s WHERE %s", $allnam, $table, $uniopt ) );
		unless ($oka) {
			return $oka;
		}
	}

	my $mod = {};
	while ( my ( $field, $data ) = each( %{$fields} ) ) {
		if ( $data->{ins} ) {
			$oka = $dbm->add_preps( $this->sql_key("ins_$field") => sprintf( "SELECT %s AS %s", $data->{ins}, $field ) );
			unless ($oka) {
				return $oka;
			}
		}

		if ( $data->{upd} ) {
			$mod->{$field} = 1;
			$this->mk_accessors($field);
		} else {
			$this->mk_ro_accessors($field);
		}
	}

	$oka = $dbm->prepare;
	unless ($oka) {
		return $oka;
	}

	$this->mk_class_var(qw(_ins _key _mod _upd));

	$this->_mod($mod);
	$this->_ins($allfld);
	$this->_upd($updfld);
	$this->_key($keyfld);

	return $oka;
} ## end sub make_sql

#***********************************************************************

=item B<new([...])> - class constructor

	unique - По якому ключу читати об'єкт. Якщо не заданий, то об'єкт створюється
	data   - Дані для створення чи читання об'єкту

=back

=cut

#-----------------------------------------------------------------------
sub new {
	my ( $class, %params ) = @_;

	$class->error();

	my $dbm = $class->dbm;
	unless ( defined($dbm) ) {
		return $class->error( "Undefined DBM for '%s'", $class );
	}

	my $config = $class->sql_config;

	my ( $unique, $data ) = @params{qw(unique data)};

	my $this = undef;
	if ( defined($unique) ) {
		unless ( $config->{unique}->{$unique} ) {
			return $class->error( "Unknown unique keys '%s'", $unique );
		}

		unless ( $this = $dbm->get_row_hash( $class->sql_key("sel_$unique"), @{$data}{ @{ $config->{unique}->{$unique} } } ) ) {
			return $this;
		}
	} else {
		$this = {};
		my $fields = $config->{fields};

		while ( my ( $field, $fdat ) = each( %{$fields} ) ) {
			if ( exists( $data->{$field} ) ) {
				$this->{$field} = $data->{$field};
			} elsif ( $fdat->{ins} ) {
				my $res = $dbm->get_one( $class->sql_key("ins_$field") );
				unless ( defined($res) ) {
					return undef;
				}
				$this->{$field} = $res;
			} else {
				$this->{$field} = undef;
			}
		}

		$this->{_NEW_} = 1;
	} ## end else [ if ( defined($unique) )

	unless ( defined($this) ) {
		return $class->error("Object wrong or not found");
	}

	$this->{_STATUS_} = 0;

	$this = $class->SUPER::new($this);

	return $this;
} ## end sub new

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<set($NAME => $VALUE, ...)> - object method

Задає значення полів об'єкту та змінює його статус.

Не дає можливості змінювати захищені поля

=cut

#-----------------------------------------------------------------------
sub set {
	my ( $this, %params ) = @_;

	if (%params) {
		my $mod = $this->_mod;
		while ( my ( $key, $value ) = each(%params) ) {
			if ( $mod->{$key} ) {
				$this->{$key} = $value;
				$this->{_STATUS_} = 1;
			} else {
				return $this->error( "Can't alter the value of '%s' on objects of object '%s'", $key, $this );
			}
		}

		return 1;
	} else {
		return $this->error( "Can't set undefined field name(s) in '%s' object", $this );
	}
}

#***********************************************************************

=item B<is_modified()> - object method

Чи є об'єкт зміненим

=cut

#-----------------------------------------------------------------------
sub is_modified {
	my ($this) = @_;

	if ( $this->{_STATUS_} or $this->{_NEW_} ) {
		return 1;
	}

	return 0;
}

#***********************************************************************

=item B<delete()> - object method

Позначити об'єкт, як такий, що підлягає знищенню та актуалізує
зміни у базі

=cut

#-----------------------------------------------------------------------
sub delete {
	my ($this) = @_;

	$this->{_STATUS_} = -1;

	unless ( $this->update ) {
		return undef;
	}

	undef($this);

	return 1;
}

#***********************************************************************

=item B<update([$no_transaction])> - object method

Актуалізує зміни у базі.

=cut

#-----------------------------------------------------------------------
sub update {
	my ( $this, $no_transaction ) = @_;

	my $config = $this->sql_config;

	unless ( $this->is_modified ) {
		return 1;
	}

	my $dbm = $this->dbm;

	unless ($no_transaction) {
		$dbm->begin_transaction;
	}

	if ( $this->{_STATUS_} < 0 ) {
		unless ( $this->{_NEW_} ) {
			unless ( $dbm->do_one( $this->sql_key("delete"), $this->get( @{ $this->_key } ) ) ) {
				$dbm->rollback_transaction;
				return undef;
			}
		}
	} elsif ( $this->{_NEW_} ) {
		if ( $dbm->do_one( $this->sql_key("insert"), $this->get( @{ $this->_ins } ) ) ) {
			$this->{_NEW_}    = 0;
			$this->{_STATUS_} = 0;
		} else {
			$dbm->rollback_transaction;
			return undef;
		}
	} elsif ( $this->{_STATUS_} > 0 ) {
		if ( $dbm->do_one( $this->sql_key("update"), $this->get( @{ $this->_upd } ), $this->get( @{ $this->_key } ) ) ) {
			$this->{_STATUS_} = 0;
		} else {
			$dbm->rollback_transaction;
			return undef;
		}
	}

	unless ($no_transaction) {
		$dbm->commit_transaction;
	}

	if ( $this->{_STATUS_} < -1 ) {
		%{$this} = ( _STATUS_ => -2, );
	}

	return 1;
} ## end sub update

#***********************************************************************
1;
__END__

=back

=head1 EXAMPLES

Empty

=head1 BUGS

Unknown

=head1 SEE ALSO

Empty

=head1 TODO

Empty

=head1 AUTHOR

Valentyn Solomko <pere@pere.org.ua>

=cut
