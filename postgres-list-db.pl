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

my ( $status , $dbh  , $database , $username , $password , $host );
my ( $sql , $sth , $ref , $row , $port );
my ( @Name , @Owner , @Encoding , @Collate , @Ctype , @Access_privileges );

@Name = ();
@Owner = ();
@Encoding = ();
@Collate = ();
@Ctype = ();
@Access_privileges = ();

$database = 'mydatabase';
$username = 'myusername';
$password = 'mypassword';
$host = "127.0.0.1";
$port = 5432;

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
