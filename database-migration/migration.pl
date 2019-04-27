#!/usr/bin/perl

# File:        migration.pl
# Version:     1.0.6
# Date:        26/4/2019
# Name:        Dan
# E-mail:      dvuk84@gmail.com
# Description: MySQL database migration script that can migrate a database or
#              a list of databases from one server to another.
# Interpreter: Perl 5.26.1
# Libraries:
#   DBI
#   Getopt

use strict;
use warnings;
use DBI;
use Getopt::Long qw(GetOptions);

#
# Take a dump of the database and user
#
sub dbdump {

  # local vars
  my ($database, $admin_dbuser, $admin_dbpass, $from_hostname, $dumpdir, $ver, $mysqlauth) = @_;
  my ($user, $pass);

  # connection string
  my $connection = DBI->connect("DBI:mysql:;$from_hostname", $admin_dbuser, $admin_dbpass) or die "CONNECTION ERROR: " . $DBI::errstr;

  # exit if there are connection errors, we don't want to continue
  if (not defined $connection) {
    exit 1;
  }

  # sql query to avoid passing variables to prepare()
  my $sql = "SELECT CONCAT(mysql.user.User,\",\",mysql.user.$ver) FROM mysql.user LEFT JOIN mysql.db ON mysql.db.User = mysql.user.User WHERE mysql.db.Db = '$database'";

  # run sql query
  my $query = $connection->prepare($sql);
  $query->execute() or die "QUERY ERROR: " . $DBI::errstr;

  # get user and pass
  while (my @row = $query->fetchrow_array) {
    eval {
      ($user, $pass) = (split /,/, $row[0]);
      1;
    } or do {
      my $error = $@ || 'Unknown failure';
      say STDERR "USER DUMP ERROR: Could not get username or password for $database,$error";
      exit 1;
    };
  }

  # end sql connection
  $connection->disconnect;

  # mysqldump
  eval {
    system("mysqldump --defaults-file=$mysqlauth -h $from_hostname $database > $dumpdir$database.sql");
    say STDERR "DUMP SUCCESS: $dumpdir$database.sql,$user,$pass";
    1;  
  } or do {
    my $error = $@ || 'Unknown failure';
    say STDERR "DUMP ERROR: $dumpdir$database.sql,$error";
    cleanup(1, $dumpdir, $database, $user);
    exit 1; 
  };

  # return username and password
  return ($user, $pass);
}

#
# Import the dump onto a new server
#
sub dbimport {

  # local vars
  my ($admin_dbuser, $admin_dbpass, $to_hostname, $database, $dumpdir, $user, $pass, $mysqlauth) = @_;

  # connection string
  my $connection = DBI->connect("DBI:mysql:;$to_hostname", $admin_dbuser, $admin_dbpass) or die "CONNECTION ERROR: " . $DBI::errstr;

  # exit if there are connection errors, we don't want to continue
  if (not defined $connection) {
    exit 1;
  }

  # sql query to avoid passing variables to prepare()
  my @sql = (
    "CREATE DATABASE IF NOT EXISTS $database",
    "CREATE USER IF NOT EXISTS '$user'\@'%'",
    "ALTER USER '$user'\@'%' IDENTIFIED WITH 'mysql_native_password' AS '$pass' REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK",
    "GRANT ALL PRIVILEGES ON `$database`.* TO '$user'\@'%'",
    "GRANT USAGE ON *.* TO '$user'\@'%'",
    "FLUSH PRIVILEGES",
  );

  # import the user
  for (@sql) {
    my $query = $connection->prepare($_);
    $query->execute() or die "QUERY ERROR: " . $DBI::errstr;
  }

  # end sql connection
  $connection->disconnect();

  # import the database
  eval {
    system("mysql --defaults-file=$mysqlauth -h $to_hostname $database < $dumpdir$database.sql");
    say STDERR "IMPORT SUCCESS: Successfully imported $database and created $user";
    1;  
  } or do {
    my $error = $@ || 'Unknown failure';
    say STDERR "IMPORT ERROR: $database";
    cleanup(2, $dumpdir, $database, $user);
    exit 1;  
  };

}

#
# Drop the database and user on the old database server
#
sub dropdb {

  # local vars
  my ($admin_dbuser, $admin_dbpass, $from_hostname, $database, $user) = @_;

  # connection string
  my $connection = DBI->connect("DBI:mysql:;$from_hostname", $admin_dbuser, $admin_dbpass) or die "CONNECTION ERROR: " . $DBI::errstr;

  # exit if there are connection errors, we don't want to continue
  if (not defined $connection) {
    exit 1;
  }

  # sql query to avoid passing variables to prepare()
  my @sql = (
    "DROP DATABASE $database",
    "DROP USER $user",
  );

  # drop database and user
  for (@sql) {
#    my $query = $connection->prepare($_);
#    $query->execute() or die "QUERY ERROR: " . $DBI::errstr;
    say STDOUT $_;
  }

  # end sql connection
  $connection->disconnect();

}

#
# Sanity check
#
sub sanitycheck {

  # local vars
  my ($filename, $from_hostname, $to_hostname, $admin_dbuser, $admin_dbpass) = @_;
  my ($var, $val, $ver, $major, $minor);

  # explain how to use the script
  my $usage = <<'USAGE';
Usage: ./migration.pl --file list.txt --from db1.server.com --to db2.server.com

       --file    File should contain a list of databases that need to be migrated
                 separated by newline.

       --from    Database server you want to migrate from. Can be both a hostname
                 or an IP address.

       --to      Database server you want to migrate to. Can be both a hostname
                 or an IP address.
USAGE

  # exit if flag values are missing
  if ($filename eq "" or $from_hostname eq "" or $to_hostname eq "") {
    print $usage;
    exit 1;
  # otherwise run some checks
  } else {

    # check file access
    if ( -e $filename ) { 
      open(my $fh, '<', $filename) or die "FILE ERROR: Could not open $filename";
      close $fh;
    } else {
      say STDERR "FILE ERROR: $filename does not exist";
      exit 1;
    }

    # check mysql access to source server
    my $connection_from = DBI->connect("DBI:mysql:;$from_hostname", $admin_dbuser, $admin_dbpass) or die "CONNECTION ERROR: " . $DBI::errstr;
    if (not defined $connection_from) {
      say STDERR "CONNECTION ERROR: Could not connect to $from_hostname";
      exit 1;
    } else {
      my $sql = 'SHOW VARIABLES LIKE "version"';
      my $query = $connection_from->prepare($sql);
      $query->execute() or die "QUERY ERROR: " . $DBI::errstr;
      # get mysql version
      while (my @row = $query->fetchrow_array) {
      eval {
        ($val, $var) = (split / /, $row[1]);		# 5.7.18
        ($major, $minor) = (split /\./, $val)[0, 1];	# 5, 7
        if ($major == 5) {
          if ($minor >= 7) {
            $ver = "authentication_string";
          } else {
            $ver = "Password";
          }
        } elsif ($major == 8) {
          if ($minor == 0) {
            $ver = "authentication_string";
          } else {
            say STDERR "MYSQL ERROR: Unsupported version";
            $connection_from->disconnect();
            exit 1;
          }
        } else {
          say STDERR "MYSQL ERROR: Unknown version";
          $connection_from->disconnect();
          exit 1;
        }
        1;  
      } or do {
        my $error = $@ || 'Unknown failure';
        say STDERR "QUERY ERROR: Could not get MySQL version, $error";
        $connection_from->disconnect();
        exit 1;
      };  
  }
      $connection_from->disconnect();
    }

    # check mysql access to destination server
    my $connection_to = DBI->connect("DBI:mysql:;$to_hostname", $admin_dbuser, $admin_dbpass) or die "CONNECTION ERROR: " . $DBI::errstr;
    if (not defined $connection_to) {
      exit 1;
    } else {
      $connection_to->disconnect();
    }
  }

  return $ver;
}

#
# Get current time
#
sub gettime {
  return gmtime();
}

#
# Cleanup after error
#
sub cleanup {

  # local vars
  my ($stage, $dumpdir, $database, $user) = @_;

  # do a cleanup depending on the stage in the code
  if ($stage == 1) {
    # delete the sql dump
    unlink $dumpdir$database;
  } elsif ($stage == 2 ) {
    # TODO
    # drop database on the destination
    # drop user on the destination

    # delete the sql dump
    unlink $dumpdir$database;
  }
}

################################################## main ##################################################

# vars
my ($database, $from_hostname, $to_hostname, $filename, $ver);
my $logfile      = "migration.log";
my $mysqlauth    = ".my.cnf";
my $admin_dbuser = "";
my $admin_dbpass = "";
my $dumpdir      = "/tmp/";
my $datetime     = gettime();

# error logging
open(STDERR, ">>", $logfile);

# begin logging with a timestamp
say STDERR "\n$datetime";

# save mysql credentials in a file so that we don't pass them on cli
open(my $fh_mysqlauth, '>', $mysqlauth) or die "FILE ERROR: Could not open $mysqlauth";
say $fh_mysqlauth "[client]\nuser=$admin_dbuser\npassword=$admin_dbpass";
close $fh_mysqlauth;

# get arguments
GetOptions(
  '--file=s' => \$filename,
  '--from=s' => \$from_hostname,
  '--to=s'   => \$to_hostname,
) or die "Usage: $0 ./migration.pl --file=list.txt --from=db1.server.com --to=db2.server.com\n";

# do a basic sanity check
$ver = sanitycheck($filename, $from_hostname, $to_hostname, $admin_dbuser, $admin_dbpass);

# open list
open(my $fh_filename, $filename) or die "FILE ERROR: Could not open $filename"; 

# let's begin
say STDOUT "Starting migration and logging to $logfile. Please don't quit.";

# read from the list
while (my $row = <$fh_filename>) {
  chomp($row);
  $database = $row;
  
  # some output for the user
  say STDOUT "+ Migrating $database from $from_hostname to $to_hostname";

  # 1.Take a dump of the database, username and password
  my ($user, $pass) = dbdump($database, $admin_dbuser, $admin_dbpass, $from_hostname, $dumpdir, $ver, $mysqlauth);

  # 2.Import the dump onto a new database server
  dbimport($admin_dbuser, $admin_dbpass, $to_hostname, $database, $dumpdir, $user, $pass, $mysqlauth);

  # 3.Drop the database and user on the old database server
  dropdb($admin_dbuser, $admin_dbpass, $from_hostname, $database, $user);

  # 4. Cleanup
  # remove .my.cnf
  # remove the dump file
}

# close file
close $fh_filename;
say STDOUT "All done.";
