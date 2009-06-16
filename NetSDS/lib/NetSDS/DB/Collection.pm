package NetSDS::DB::Collection;
########################################################################
# $Id$
########################################################################

=head1 NAME

NetSDS::DB::Collection - API для маніпулювання об'ктами зберіганими у базі даних
та які містять дочірні списки значень.

=head1 SYNOPSIS

	use NetSDS::DB::Collection;
	our @ISA = qw(
	  NetSDS::DB::Collection
	);

=head1 DESCRIPTION

Абстрактний клас C<NetSDS::DB::Collection> реалізує маніпуляції з об'єктами бази даних,
що містять списки значень.
Призначений для породження від нього конкретних класів.

Породжений від L<NetSDS::DB::Object>.

=cut

use 5.8.0;
use strict;
use warnings 'all';

use NetSDS::DB::Single;
our @ISA = qw(
  NetSDS::DB::Single
);

our $VERSION = sprintf( "0.1.0.%d", q$Revision: 8 $ =~ m/(\d+)/ );

our @EXPORT = qw();

use NetSDS::Const;

use NetSDS::Util::Struct qw(
  arrays2hash
);

#***********************************************************************

=head1 CLASS METHODS

=over

=item B<sql_config()> - class method

Повертає конкретні значення для формування запитів відповідного класу:

	table     => назва таблиці об'єкта
	seq       => автоматично генеровані дані для деяких полів у вигляді C<field_name> => C<QUERY_PART>
	fields    => список необхідних полів об'єкта, окрім ключових
	dequote   => список полів та функцій для "розпакування" даних
	key       => список ключових полів об'єкта (захищаються автоматично)
	preserved => список захищених полів об'єкта
	what_by   => список полів за якими теж можна завантажувати об'єкт (:by_field_name)
	lists     => посилання на хеш що визначає залежні списки значень, де ключі є назвами відповідних таблиць

	опис залежної таблиці:

		назва_таблиці => {
			seq     => автоматично генеровані дані для деяких полів у вигляді C<field_name> => C<QUERY_PART>
			key     => список ключових полів
			fields  => список необхідних полів, окрім ключових
			dequote => список полів та функцій для "розпакування" даних
			link    => зв'язуючі поля із полями охоплюючого об'єкта
			name    => поле, що містить назву елемента списку
			value   => поле, що містить значення елемента списку
		},

Цей метод треба перевизначати у породжених класах, відповідно до потреб

=cut

#-----------------------------------------------------------------------
sub sql_config {
	my ($this) = @_;

	return $this->error( "Abstract class used: " . ref($this) || $this . ' => sql_config()' );

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

		lists => {
			'schema.profiles' => {
				fields => {
					id => {
						ins => "NEXTVAL('schema.profiles_id_seq')",
					},
					name => {
						upd => 1,
					},
					value => {
						upd => 1,
					},
					user_id    => {},
					service_id => {},
				},
				primary => 'by_id',
				unique  => {
					by_id   => [qw(id)],
					by_name => [qw(user_id service_id name)],
				},
				link => {
					user_id => 'id',
				},
				name  => 'name',
				value => 'value',
			},

			'schema.groups' => {
				fields => {
					id => {
						ins => "NEXTVAL('schema.groups_id_seq')",
					},
					name => {
						upd => 1,
					},
					title => {
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
					description => {
						upd => 1,
					},
					owner_id   => {},
					service_id => {},
				},
				primary => 'by_id',
				unique  => {
					by_id   => [qw(id)],
					by_name => [qw(owner_id service_id name)],
				},
				link => {
					owner_id => 'id',
				},
				name  => 'name',
				value => 'title',
			},
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

	my $oka = $this->SUPER::make_sql;

	my $cfg = $this->sql_config;
	my $dbm = $this->dbm;

	my $chimod = {};
	my $chiins = {};
	my $chiupd = {};
	my $chikey = {};
	while ( my ( $table, $config ) = each( %{ $cfg->{lists} } ) ) {

		my ( $fields, $primary, $unique, $link ) = @{$cfg}{qw(fields primary unique link)};

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

		my $lnkopt = join( ' AND ', map { $_ . ' = ?' } sort keys %{$link} );

		$oka = $dbm->add_preps(
			$this->sql_key("$table\_select") => sprintf( "SELECT %s FROM %%s.%s WHERE %s",      $allnam, $table,  $lnkopt ),
			$this->sql_key("$table\_insert") => sprintf( "INSERT INTO %%s.%s (%s) VALUES (%s)", $table,  $allnam, $allopt ),
			$this->sql_key("$table\_update") => sprintf( "UPDATE %%s.%s SET %s WHERE %s",       $table,  $updopt, $keyopt ),
			$this->sql_key("$table\_delete") => sprintf( "DELETE FROM %%s.%s WHERE %s",         $table,  $keyopt ),
		);
		unless ($oka) {
			return $oka;
		}

		#--------------------------------
		my $mod = {};
		while ( my ( $field, $data ) = each( %{$fields} ) ) {
			if ( $data->{ins} ) {
				$oka = $dbm->add_preps( $this->sql_key("$table\_ins_$field") => sprintf( "SELECT %s AS %s", $data->{ins}, $field ) );
				unless ($oka) {
					return $oka;
				}
			}

			if ( $data->{upd} ) {
				$mod->{$field} = 1;
			}
		}

		$oka = $dbm->prepare;
		unless ($oka) {
			return $oka;
		}

		$chimod->{$table} = $mod;
		$chiins->{$table} = $allfld;
		$chiupd->{$table} = $updfld;
		$chikey->{$table} = $keyfld;
	} ## end while ( my ( $table, $config...

	$this->mk_class_var(qw(childs_mod childs_ins childs_upd childs_key));

	$this->childs_mod($chimod);
	$this->childs_ins($chiins);
	$this->childs_upd($chiupd);
	$this->childs_key($chikey);

	return $oka;
} ## end sub make_sql

#***********************************************************************

=item B<new([...])> - class constructor

	unique - По якому ключу читати об'єкт. Якщо не заданий, то об'єкт створюється
	data   - Дані для створення чи читання об'єкту
	load   - Завантажити дочірні дані

=back

=cut

#-----------------------------------------------------------------------
sub new {
	my ( $class, %params ) = @_;

	my ($load) = delete( @params{qw(load)} );
	my $this = $class->SUPER::new(%params);

	unless ($this) {
		return $this;
	}

	$this->set( childs => {} );

	if ($load) {
		foreach my $table ( $this->childs ) {
			$this->childs($table);
		}
	}

	return $this;

} ## end sub new

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<childs($table)> - object method

Повертає всі елементи списку для вказазаної таблиці.
Бажано не використовувати напряму.

=cut

#-----------------------------------------------------------------------
sub childs {
	my ( $this, $table ) = @_;

	my $config = $this->sql_config;

	if ($table) {
		my $childs = $this->get('childs');

		unless ( $childs->{$table} ) {
			my $htbl = $config->{lists}->{$table};
			unless ($htbl) {
				return $this->error( "Unknown child table '%s'", $table );
			}

			my ( $cnam, $clnk ) = @{$htbl}{qw(name link)};

			my $dbm = $this->dbm;
			my $sth = $dbm->statement( $this->sql_key("$table\_select") );
			if ($sth) {
				my $loaded = {};
				if ( $sth->execute( $this->get( @{$clnk}{ sort keys %{$clnk} } ) ) ) {
					while ( my $row = $sth->fetchrow_hashref ) {
						$loaded->{ $row->{$cnam} } = $row;
					}

					$childs->{$table} = $loaded;

					return $loaded;
				} else {
					return $this->error($sth);
				}
			} else {
				return undef;
			}
		} ## end unless ( $childs->{$table})

		return $childs->{$table};
	} else {
		return keys %{ $config->{lists} };
	}
} ## end sub childs

#***********************************************************************

=item B<lookup_child_items($table, $sub)> - object method

Виконує перегляд елементів за логікою вказаною у C<$sub>.

Наприклад:

	my $res = [];
	my $sub = sub {
		my ($rec) = @_;

		if ($rec->{type} eq 'aaa') {
			push(@{$res}, $rec);

			return (scalar(@{$res}) < 10);
		}

		return 1;
	};

	$this->lookup_child_items('data', $sub);

=cut

#-----------------------------------------------------------------------
sub lookup_child_items {
	my $this  = shift(@_);
	my $table = shift(@_);
	my $sub   = shift(@_);

	my $childs = $this->childs($table);
	unless ($childs) {
		return $childs;
	}

	foreach my $rec ( values %{$childs} ) {
		#		my $ret = $sub->(%{$rec}); # цей варіант безпечний, але повільніший
		my $ret = $sub->( $rec, @_ );    # цей варіант швидший, але небезпечний
		unless ($ret) {
			last;
		}
	}
}

#***********************************************************************

=item B<set_child_item(...)> - object method

Додає новий чи модифікує існуючий елемент вказаного списку.

=cut

#-----------------------------------------------------------------------
sub set_child_item {
	my ( $this, $table, %params ) = @_;

	if (%params) {
		my $childs = $this->childs($table);
		unless ($childs) {
			return $childs;
		}

		my $config = $this->sql_config;
		my $lists  = $config->{lists}->{$table};

		my ( $cnam, $clnk ) = @{$lists}{qw(name link)};
		my $name = $params{$cnam};
		unless ($name) {
			return $this->error( "Undefined item name for table '%s'", $table );
		}

		my $ins    = $lists->{fields};
		my @fields = keys %{$ins};

		my $ent = $childs->{$cnam};
		if ($ent) {
			if ( exist( $ent->{_NEW_} ) and $ent->{_NEW_} ) {
				foreach my $field (@fields) {
					if ( exists( $params{$field} ) ) {
						$ent->{$field} = $params{$field};
					}
				}
			} else {
				my $mod = $this->childs_mod->{$table};
				foreach my $field (@fields) {
					if ( exists( $params{$field} ) ) {
						if ( $mod->{$field} ) {
							$ent->{$field} = $params{$field};
						}
					}
				}
			}
		} else {
			$ent = $childs->{$cnam} = {
				_NEW_ => 1,
			};

			my $dbm = $this->dbm;
			foreach my $field (@fields) {
				if ( exists( $params{$field} ) ) {
					$ent->{$field} = $params{$field};
				} elsif ( $ins->{$field}->{ins} ) {
					$ent->{$field} = $dbm->get_one( $this->sql_key("$table\_ins_$field") );
				} else {
					$ent->{$field} = undef;
				}
			}

			while ( my ( $field, $link ) = each( %{$clnk} ) ) {
				$params{$field} = $this->get($link);
			}
		} ## end else [ if ($ent)

		$ent->{_STATUS_} = 1;
	} ## end if (%params)

	return 1;
} ## end sub set_child_item

#***********************************************************************

=item B<del_child_item(...)> - object method

Призначає знищення елементу списку вказаної таблиці

=cut

#-----------------------------------------------------------------------
sub del_child_item {
	my ( $this, $table, @names ) = @_;

	if (@names) {
		my $childs = $this->childs($table);
		unless ($childs) {
			return $childs;
		}

		foreach my $name (@names) {
			if ( exists( $childs->{$name} ) ) {
				$childs->{$name}->{_STATUS_} = -1;
			}
		}
	}

	return 1;
}

#***********************************************************************

=item B<get_child_field(...)> - object method

Повертає значення заданого поля вказаного списку для зазначених елементів списку

=cut

#-----------------------------------------------------------------------
sub get_child_field {
	my ( $this, $table, $field, @names ) = @_;

	my $childs = $this->childs($table);
	unless ($childs) {
		return $childs;
	}

	if (@names) {
		return map { ( $_ and exists( $_->{$field} ) ) ? $_->{$field} : undef } @{$childs}{@names};
	} else {
		return map {
			if ( $childs->{$_} )
			{
				( $_, $childs->{$_}->{$field} );
			} else {
				delete( $childs->{$_} );
				( $_, undef );
			}
		} keys %{$childs};
	}
} ## end sub get_child_field

#***********************************************************************

=item B<set_child_field(...)> - object method

Встановлює значення заданого поля вказаного списку для зазначених елементів списку

=cut

#-----------------------------------------------------------------------
sub set_child_field {
	my ( $this, $table, $field, %params ) = @_;

	if (%params) {
		unless ( $this->childs_mod->{$table}->{$field} ) {
			return $this->error( "Can't modify '%s' field in table '%s'", $field, $table );
		}

		my $childs = $this->childs($table);
		unless ($childs) {
			return $childs;
		}

		my $config = $this->sql_config;
		my $lists  = $config->{lists}->{$table};
		my ( $cnam, $clnk ) = @{$lists}{qw(name link)};
		my $ins    = $lists->{fields};
		my @fields = keys %{$ins};

		while ( my ( $name, $value ) = each(%params) ) {
			my $ent = $childs->{$name};
			unless ($ent) {
				$ent = $childs->{$name} = {
					_NEW_ => 1,
					$cnam => $name,
				};

				my $dbm = $this->dbm;
				# FIXME
				# вважаємо, що value не має зазвичаєвого значення.
				# треба пізніше перевіряти ситуацію у make_sql
				foreach my $fld (@fields) {
					if ( $ins->{$fld}->{ins} ) {
						# FIXME
						# чиє undef помилкою. ХЗ. Значить не перевіряємо
						$ent->{$fld} = $dbm->get_one( $this->sql_key("$table\_ins_$fld") );
					} else {
						$ent->{$fld} = undef;
					}
				}

				while ( my ( $field, $link ) = each( %{$clnk} ) ) {
					$ent->{$field} = $this->get($link);
				}
			} ## end unless ($ent)

			# FIXME
			# вважаємо, що value не зроблять ro.
			# треба пізніше перевіряти ситуацію у make_sql
			$ent->{$field} = $value;
			$ent->{_STATUS_} = 1;
		} ## end while ( my ( $name, $value...

		return 1;
	} ## end if (%params)

	return 0;
} ## end sub set_child_field

#***********************************************************************

=item B<get_child_value(...)> - object method

Повертає значення для зазначених елементів вказаного списку

=cut

#-----------------------------------------------------------------------
sub get_child_value {
	my ( $this, $table, @names ) = @_;

	return $this->get_child_field( $table, $this->sql_config->{lists}->{$table}->{value}, @names );
}

#***********************************************************************

=item B<get_child_value_hash(...)> - object method

Повертає значення для зазначених елементів вказаного списку

=cut

#-----------------------------------------------------------------------
sub get_child_value_hash {
	my ( $this, $table, @names ) = @_;

	return arrays2hash( \@names, [ $this->get_child_value( $table, @names ) ] );
}

#***********************************************************************

=item B<set_child_value(...)> - object method

Встановлює значення для зазначених елементів вказаного списку

=cut

#-----------------------------------------------------------------------
sub set_child_value {
	my ( $this, $table, %params ) = @_;

	return $this->set_child_field( $table, $this->sql_config->{lists}->{$table}->{value}, %params );
}

#***********************************************************************

=item B<is_modified()> - object method

Чи є об'єкт зміненим

=cut

#-----------------------------------------------------------------------
sub is_modified {
	my ($this) = @_;

	if ( $this->SUPER::is_modified ) {
		return 1;
	}

	foreach my $childs ( values %{ $this->{childs} } ) {
		foreach my $ent ( values %{$childs} ) {
			if ( ( exists( $ent->{_STATUS_} ) and $ent->{_STATUS_} ) or ( exists( $ent->{_NEW_} ) and $ent->{_NEW_} ) ) {
				return 1;
			}
		}
	}

	return 0;
}

#***********************************************************************

=item B<update([$no_transaction])> - object method

Актуалізує зміни у базі.

=cut

#-----------------------------------------------------------------------
sub update {
	my ( $this, $no_transaction ) = @_;

	unless ( $this->is_modified ) {
		return 1;
	}

	my $dbm = $this->dbm;

	unless ($no_transaction) {
		$dbm->begin_transaction;
	}

	unless ( $this->SUPER::update(1) ) {
		return undef;
	}

	if ( $this->{_STATUS_} < 0 ) {
		# FIXME вважаємо, що грохаються через 'ON DELETE CASCADE'
		unless ($no_transaction) {
			$dbm->commit_transaction;
		}

		return 1;
	}

	my $lists = $this->sql_config->{lists};

	foreach my $table ( $this->childs ) {
		my $config = $lists->{$table};

		my ( $cnam, $fields ) = @{$config}{qw(name fields)};

		my $sti = $dbm->statement( $this->sql_key("$table\_insert") );
		unless ($sti) {
			$dbm->rollback_transaction;
			return undef;
		}

		my $std = $dbm->statement( $this->sql_key("$table\_delete") );
		unless ($std) {
			$dbm->rollback_transaction;
			return undef;
		}

		my $stu = $dbm->statement( $this->sql_key("$table\_update") );
		unless ($stu) {
			$dbm->rollback_transaction;
			return undef;
		}

		my $mod = $this->childs_mod->{$table};
		my $ins = $this->childs_ins->{$table};
		my $upd = $this->childs_upd->{$table};
		my $key = $this->childs_key->{$table};

		my $childs = $this->childs($table);

		foreach my $ent ( values %{$childs} ) {
			next unless ($ent);

			my $sta = $ent->{_STATUS_} || 0;
			my $new = $ent->{_NEW_}    || 0;

			if ( $sta < 0 ) {
				unless ($new) {
					unless ( $dbm->do_one( $std, @{$ent}{ @{$key} } ) ) {
						$dbm->rollback_transaction;
						return undef;
					}
				}

				delete( $childs->{ $ent->{$cnam} } );
			} elsif ($new) {
				unless ( $dbm->do_one( $sti, @{$ent}{ @{$ins} } ) ) {
					$dbm->rollback_transaction;
					return undef;
				}

				$ent->{_NEW_}    = 0;
				$ent->{_STATUS_} = 0;
			} elsif ( $sta > 0 ) {
				unless ( $dbm->do_one( $stu, @{$ent}{ @{$upd} }, @{$ent}{ @{$key} } ) ) {
					$dbm->rollback_transaction;
					return undef;
				}

				$ent->{_STATUS_} = 0;
			}
		} ## end foreach my $ent ( values %{...
	} ## end foreach my $table ( $this->childs)

	unless ($no_transaction) {
		$dbm->commit_transaction;
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
