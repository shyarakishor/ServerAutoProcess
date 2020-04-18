#!/usr/bin/perl -w
use strict;

# Dependencies ###################################
use FileHandle qw();
use File::Basename qw();
use Cwd qw();
my $base_dir;
my $relative_path;

BEGIN {
   $relative_path = './';
   $base_dir = Cwd::realpath(File::Basename::dirname(__FILE__) . '/' . $relative_path);
}
# Dependencies ####################################

use lib "$base_dir/lib64/perl5";

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser) ;
use YAML::XS qw(LoadFile Load);
use Template qw(process);;
use JSON;
use Data::Dumper;
##################################################

# Version Info ###################################
my $VERSION = "1.0.0";
##################################################

my $config_file = $ARGV[0];
if ( !defined $config_file ) {
	print "Please mentioned config file as a first argument. \n";exit;
}

#################
# Config Values #
#################
# my $CONFIG_FILE = "$base_dir/resources/$config_file";
my $CONFIG_FILE = $config_file;

# Load Config Data #######################################	
my $filedata = LoadFile($CONFIG_FILE);

my $server_list  = $filedata->{server_list};
my $summary_file = $filedata->{summary_file};
my $detail_file  = $filedata->{detail_file};
my $temp_file    = $filedata->{temp_file};
my $autoserv     = $filedata->{AUTOSERV};

####Read CSV File and Collect Lines
my $servers = [];
my $fh = FileHandle->new;
if ( $fh->open("< $server_list") ) {
	while (my $line = $fh->getline()) {
		chomp($line);
		$line =~ s/\r|\n//g;
		&trim_space($line);
		push @$servers, $line;
	}
	$fh->close;
} 
else {
	print "Cannot open $server_list"; 
	die;
}

##check if file exists then remove it and create new one
if ( -e $summary_file ) {
	`rm $summary_file`;
	`rm $detail_file`;
}
if ( -e $temp_file ) {
	`rm $temp_file`;
}
###remove end

##open summary file handle
open(SUMMARYFILE, "> $summary_file");
open(DETAILFILE, "> $detail_file");
##end summary file handle

####Read server list
##start read and prepare Graph
if( scalar @$servers ) {
	foreach my $server ( @$servers ) {
		$server = &trim_space( $server );
		$server =~ s/\r|\n//g;
		next if $server =~ /^\s*$/;

		`AR_PA9 $server% | sed /Job/d | sed /__/d | sed /AUTOSERV/d | sed '/^$/d' | awk '{ print $1 ","  $2 "," $3 "," $4 "," $5 "," $6}' > $temp_file`;

		if ( -e $temp_file && -s $temp_file ) {
			open(LOGFILE, $temp_file);
			my $file_string = <LOGFILE>;
			close(LOGFILE);
			if ($file_string =~ /,FA/i ) {
			   print SUMMARYFILE "$server,RED\n";
			}
			else {
			   print SUMMARYFILE "$server,GREEN\n";
			}

			print DETAILFILE $file_string;

			##remove temp file
			if ( -e $temp_file ) {
				`rm $temp_file`;
			}
		}
	}
}
##remove temp file
if ( -e $temp_file ) {
	`rm $temp_file`;
}
##remove temp file end

close(SUMMARYFILE);
close(DETAILFILE);

##trim
sub trim_space {
	my $line = shift;

	$line =~ s/^\s+//g;
	$line =~ s/\s+$//g;

	return $line;
}

print "Finished \n";
exit;
