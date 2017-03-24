#!/usr/bin/perl

use strict;
use IO::Socket;
use POSIX;
use warnings;
use Config::Simple;
	
sub logMonitor{ #subrouting to connect to the PBX log and monitor for the Emergency calls
	my ($HOST, $PORT)= @_;	

	OUTER: if (my $sock = new IO::Socket::INET(PeerAddr => $HOST, PeerPort => $PORT,Proto => "tcp",)) {

		 while (<$sock>) {
			s/^\0+//; # Remove leading null characters

			chomp ($_);
			my $data = substr($_, 1,17);
			my $event = substr ($data, 2,1);
			my $hr = substr ($data, 3,2);
			my $min = substr ($data,5,2);
			my $year = substr($data, 9,4);
			my $mon = substr($data, 13,2);
			my $day = substr ($data,15,2);
			#print "$hr:$min on $year-$mon-$day \n";

			if ($event eq "A") {
				my $agent = substr($_, 17,4);
#				print "\n Agent $agent logged in \n" ;
				my $output = "Agent $agent logged in at $hr:$min on ext $year";
				filePrint($output);
				}
			if ($event eq "B") {
				my $agent = substr($_, 17,4);
				my $output = "Agent $agent logged out at $hr:$min from ext $year" ;
				filePrint($output);
				}
			if ($event eq "C") {
				my $agent = substr($_, 17,4);
				my $output = "Agent $agent set to DND" ;
				filePrint($output);
				}
			if ($event eq "D") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent removed DND" ;
				filePrint($output);
				}
			if ($event eq "E") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent set Make Busy" ;
				filePrint($output);
				}
			if ($event eq "F") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent removed make busy" ;
				filePrint($output);
				}
			if ($event eq "G") {
				my $agent = substr($_, 17,4);
				my $dirNum = substr($_, 10,7);
				my $output =  "Agent $agent answered an ACD call from $dirNum" ;
				filePrint($output);
				}
			if ($event eq "H") {
				my $agent = substr($_, 17,4);
				my $dirNum = substr($_, 10,7);
				my $output =  "Agent $agent answered a personal call from $dirNum" ;
				filePrint($output);
				}
			if ($event eq "I") {
				my $agent = substr($_, 17,4);
				my $dirNum = substr($_, 10,7);
				my $output =  "Agent $agent placed a call from extension $dirNum" ;
				filePrint($output);
				}
			if ($event eq "J") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent is idle" ;
				filePrint($output);
				}
				if ($event eq "K") {
				my $agentNum = substr($_, 16,3);
				my $groupNum = substr($_, 10,3);
				my $waitNum = substr($_, 13,3);
				my $longNum = substr($_, 19,4);
				my $output =  "Group $groupNum has $agentNum active agents, $waitNum waiting calls with $longNum the longest waiting call" ;
				filePrint($output);
				}
			if ($event eq "L") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent work timer started" ;
				filePrint($output);
				}
			if ($event eq "M") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent work timer expired" ;
				filePrint($output);
				}
			if ($event eq "N") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent placed call on hold" ;
				filePrint($output);
				}
			if ($event eq "O") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent retrieved call from hold" ;
				filePrint($output);
				}
			if ($event eq "P") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent hold was abandoned" ;
				filePrint($output);
				}
#				if ($event eq "Q") {
#				my $agent = substr($_, 17,4);
#				my $output =  "Path report $data" ;
#				filePrint($output);
#				}
			if ($event eq "S") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent answered remote ACD call" ;
				filePrint($output);
				}
			if ($event eq "T") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent is ringing" ;
				filePrint($output);
				}
			if ($event eq "U") {
				my $agent = substr($_, 17,4);
				my $output =  "Agent $agent ended ringing call" ;
				filePrint($output);
				}				
		}
	}	
	else {			
		print "Failed to connect to $HOST on $PORT. Will retry in a minute.\n";
		sleep 60;
		goto OUTER;
		}
} #End of monitor subroutine

sub filePrint{	#write data to file with date and time stamp
	my ($DATA)= @_;	
	print "$DATA\n";
	my $dateStamp = strftime '%Y-%m-%d', localtime;
	my $file = "$dateStamp.log";
	my $timeStamp = strftime '%H:%M:%S', localtime;
	if (-f $file){
		open (my $fh,'>>', $file);
		print $fh "$timeStamp | $DATA\n";
		close $file;
	}
	else {
		open (my $fh,'>', $file);
		print $fh "$timeStamp | $DATA\n";
		close $file;
	}
}# End of filePrint routine

my $cfg = new Config::Simple();
$cfg->read('config.ini');
my $HOST = $cfg->param("pbx");
my $PORT = $cfg->param("port");

# Add a message to the logfile to show script starting
filePrint ("ACD Logger has started");

#Open the log monitoring subroutine
logMonitor($HOST, $PORT);