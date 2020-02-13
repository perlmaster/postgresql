#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : postgres-list-db.pl
#
# Author    : Barry Kimelman
#
# Created   : February 13, 2020
#
# Purpose   : List all the databases under a postgresql server
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "print_lists.pl";
require "display_pod_help.pl";
my %options = ( "d" => 0 , "h" => 0 );

my ( $status , $dbh  , $database , $username , $password , $host );
my ( $sql , $sth , $ref , $row , $port );
my ( @Name , @Owner , @Encoding , @Collate , @Ctype , @Access_privileges );

$status = getopts("hd",\%options);
if ( $options{"h"} ) {
	display_pod_help($0);
	exit 0;
} # IF
unless ( $status && 2 < scalar @ARGV ) {
	die("Usage : $0 [-dh] database username password [port]\n");
} # UNLESS
$host = "127.0.0.1";
( $database , $username , $password ) = @ARGV;
$port = (3 == scalar @ARGV) ? 5432 : $ARGV[3];

@Name = ();
@Owner = ();
@Encoding = ();
@Collate = ();
@Ctype = ();
@Access_privileges = ();


$dbh = DBI->connect("dbi:Pg:dbname=$database;host=$host;port=$port",
                          $username,
                          $password,
                          {AutoCommit => 0, RaiseError => 1, PrintError => 0}
                         );
unless ( defined $dbh ) {
	die("Error connecting to '${database}' on '${host}'  : $DBI::errstr\n ");
} # UNLESS

# pg_catalog.array_to_string(d.datacl, E'\n') AS "Access privileges"
$sql =<<SQL;
SELECT d.datname as "Name",
       pg_catalog.pg_get_userbyid(d.datdba) as "Owner",
       pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
       d.datcollate as "Collate",
       d.datctype as "Ctype",
	coalesce(nullif(pg_catalog.array_to_string(d.datacl, '<CR>'),''),'---') AS "Access privileges"
FROM pg_catalog.pg_database d
ORDER BY d.datname;
SQL

$sth = $dbh->prepare($sql);
unless ( defined $sth ) {
	warn("can't prepare sql : $sql\n$DBI::errstr\n");
	$dbh->disconnect();
	die("Goodbye ...\n");
} # UNLESS
unless ( $sth->execute ) {
	warn("can't execute sql : $sql\n$DBI::errstr\n");
	$dbh->disconnect();
	die("Goodbye ...\n");
} # UNLESS

while ( $ref = $sth->fetchrow_hashref ) {
	push @Name,$ref->{'Name'};
	push @Owner,$ref->{'Owner'};
	push @Encoding,$ref->{'Encoding'};
	push @Collate,$ref->{'Collate'};
	push @Ctype,$ref->{'Ctype'};
	push @Access_privileges,$ref->{'Access privileges'};
} # WHILE over all rows in table
$sth->finish();

$dbh->disconnect; # disconnect from databse
print "\n";
print_lists( [ \@Name , \@Owner , \@Encoding , \@Collate , \@Ctype , \@Access_privileges ] ,
		[ "Name" , "Owner" , "Encoding" , "Collate" , "Ctype" , "Access_privileges"] ,
		"=");

exit 0;
__END__
=head1 NAME

postgres-list-db.pl - List the databases under a postgresql server

=head1 SYNOPSIS

postgres-list-db.pl [-dh] database username password [port]

=head1 DESCRIPTION

List the databases under a postgresql server

=head1 PARAMETERS

  database - name of a postgresql database
  username - name of database user
  password - password of database user
  port - override default port number of 5432

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

postgres-list-db.pl mydb user123 pass123

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
