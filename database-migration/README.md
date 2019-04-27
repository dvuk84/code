This script will take a file that contains a list of MySQL databases, separated by newline, that need migrating from one server to another and migrate both databases and users. Supported MySQL version are 5.0 to 8.0.

```
Usage: ./migration.pl --file list.txt --from db1.server.com --to db2.server.com

       --file    File should contain a list of databases that need to be migrated
                 separated by newline.

       --from    Database server you want to migrate from. Can be both a hostname
                 or an IP address.

       --to      Database server you want to migrate to. Can be both a hostname
                 or an IP address.
```
What you should expect to see on the screen:

```
Starting migration and logging to migration.log. Please don't quit.
Migrating _blog_www_testdomain_co_uk from db1.server.com to db2.server.com
All done.
```

What you should expect to see in the log file:

```
Fri Apr 26 18:54:39 2019
DUMP SUCCESS: /tmp/_blog_www_testdomain_co_uk.sql,testuser_1165753,*CBDA982AAF06B01815D51308930560B075F4B7CE
IMPORT SUCCESS: Successfully imported _blog_www_testdomain_co_uk and created testuser_1165753
```

You will have to update the following in the main section:

```perl
my $logfile      = "migration.log";
my $mysqlauth    = ".my.cnf";
my $admin_dbuser = "root";
my $admin_dbpass = "abc123";
my $dumpdir      = "/tmp/";
```
