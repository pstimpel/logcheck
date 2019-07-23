#!/usr/bin/perl

#    Logchecker - perl script to check unix logfiles and notify by email
#    if entries appear not covered by the whitelist
#    Copyright (C) long time ago by Peter, peters-webcorner.de
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

use File::Basename;
use File::Spec;
$dirname = File::Spec->rel2abs(dirname(__FILE__));

require $dirname.'/logcheck.conf';
$mode="run";
$frompart="";

if (defined($logcheckpath)) {

	print "There was change in the configuration starting from version 1.0.9!\n";
	print "\n";
	print '$file_whitelist=$logcheckpath."logcheck.whitelist"; is now'."\n";
	print '$file_whitelist="logcheck.whitelist";'."\n";
	print "\n";
	print '$file_logfiles=$logcheckpath."logcheck.logfiles"; is now'."\n";
	print '$file_logfilelist="logcheck.logfiles";'."\n";
	print "\n";
	print '$logcheckpath="/your/path/"; is now'."\n";
	print '#$logcheckpath="/your/path/";'."\n";
	print "\nPlease make these changes before you continue using logcheck.pl\n";
	exit 1;
}

$file_pidfile = $dirname."/logcheck.pid";

$file_whitelist = $dirname."/".$file_whitelist;
$file_logfilelist = $dirname."/".$file_logfilelist;

sub head() {
	print "\n";
	print "-----------------------------\n";
	print "This is logcheck.pl V1.0.9\n";
	print "https://peters-webcorner.de\n";
	print "project hosted on github\n";
	print "https://github.com/pstimpel/logcheck\n\n";
	print "Logchecker - Copyright (C) long time ago by Peter\n";
    print "This program comes with ABSOLUTELY NO WARRANTY; for details run `-l'.\n";
    print "This is free software, and you are welcome to redistribute it\n";
    print "under certain conditions. Check license for details.\n";
	print "-----------------------------\n\n";
}

if (($ARGV[0] ne "") && ($ARGV[0] ne "debug") && ($ARGV[0] ne "-l") && ($ARGV[0] ne "-r") && ($ARGV[0] ne "-d")) {
	head();
	print "Parameters:\n";
	print "logcheck.pl         normal run, parse logfiles and fire email if needed\n";
	print "logcheck.pl debug   prevents script from sending mail\n";
	print "logcheck.pl -d      prevents script from sending mail\n";
	print "logcheck.pl -l      prints license to console\n";
	print "logcheck.pl -p      removes existing pid-file with no further checks\n";
	print "logcheck.pl -h      this screen\n";
	print "PID: ".$$." \n";
	print "DIR: ".$dirname."\n";
	getpidfilecontent();
	if($pidstring ne "unknown") {
		print "!!! PID-file existing, created by process ".$pidstring." !!!\n";
	}
	exit 0;

}

if ($ARGV[0] eq "-l") {
	head();
	print "Content of license\n\n\n";
	system('cat LICENSE | more');
	exit 0;
}

if ($ARGV[0] eq "-r") {
	head();
	unlink($file_pidfile);
	print "done...\n";
	exit 0;
}

if ($ARGV[0] eq "debug" || $ARGV[0] eq "-d") {
	head();
	print "debug mode on...\n";
	$mode="debug";

}

if (-e $file_whitelist) {
	if($mode eq "debug") {
		print "whitelist found...\n";
	}
} 
else 
{
	open(ADR, ">$file_whitelist");
	print ADR "";
	close(ADR);
	print "Please edit ".$file_whitelist." first...\n";
	exit 1;
              
}
if (-e $file_logfilelist) {
	if($mode eq "debug") {
		print "list of logfiles found...\n";
	}
} else {
	open(ADR, ">$file_logfilelist");
       	print ADR "";
       	close(ADR);
       	print "Please edit ".$file_logfilelist." first...\n";
       	exit 1;
              
}


$read=0;
open(ADR, "<$file_whitelist");
while(<ADR>)
{
	chop($_);
	if(length($_) > 1) {
		if (substr($_,0,1) ne "#") 
		{
		$read++;
		push @whitelisted, $_;
		}
	}
}
close(ADR);
if ($read > 0) {
	if($mode eq "debug") {
		print $read." entries in whitelist found\n";
	}
}
else
{
	if($mode eq "debug") {
		print "no entries in whitelist found, may be not normal...\n";
	}
}



$read=0;
open(ADR, "<$file_logfilelist");
while(<ADR>)
{
	chop($_);
	if(length($_) > 1) {
		if (substr($_,0,1) ne "#") 
		{
		$read++;
		push @logfiles, $_;
		}	
	}
}
close(ADR);
if ($read > 0) {
	if($mode eq "debug") {
		print $read." entries in logfile list found\n";
	}
}
else
{
	print "there must be at least one entry in "..$file_logfilelist."\n";
	print "ABORTING NOW!!!\n";
	exit 1;
}

if (-e $file_pidfile) {
	if($mode eq "debug") {
		print "There is a pid-file already, ".$file_pidfile.", abort execution\n";
		exit 1;
	} else {
		getpidfilecontent();
		$psstring = `ps fax`;
		$Jetztwert = time();
		$Jetztzeit = localtime($Jetztwert);
		$mailer = '/usr/sbin/sendmail';
		if (defined($senderaddress)) {
		$frompart="-f $senderaddress";
		}

		open(MAIL, "|$mailer -t $frompart") || die "Can't open $mailer!\n";
		print MAIL "To: ".$emailaddress."\n";
		print MAIL "Subject: Logs NOT CHECKED report $Jetztzeit\n\n\n";
		print MAIL "There is a pid-file already at ".$file_pidfile.", and the execution of logcheck was aborted!\n\nRemove the pid-file, but make sure logcheck is not running anymore. See output of ps fax below\n\n";
		print MAIL "Pid of this (the aborted process) is: ".$$."\n";
		print MAIL "Pid of blocking process is: ".$pidstring."\n\n";
		
		print MAIL $psstring."\n\n";
		close(MAIL);
		exit 1;
	}
}

open(ADR, ">$file_pidfile");
print ADR $$;
close(ADR);


foreach $thisfile (@logfiles) {
	$outtext="";
	$noffset="";
	$offset;
	$jumpover;
	if($mode eq "debug") {
		print "processing ".$thisfile."\n";
	}
	if(-e $thisfile) 
	{
		$useoffset=0;
		$thisoffset="";
		gettimestamplength();
		if(-e $thisfile.".offset") {
			if($mode eq "debug") {
				print "using ".$thisfile.".offset\n";
			}
			$useoffset=1;
			open(OFF,"<$thisfile.offset");
			while(<OFF>)
			{
				$offset=$_;
				if($mode eq "debug") {
					print "offset is $_\n";	
				}
			}
			close(OFF);
		}	
		$jumpover=1;	
		check();
		if($jumpover==1) {
			unlink($thisfile.".offset");
			if($mode eq "debug") {
				print "offset not found, reparsing without offset\n";	
			}
			$jumpover=0;
			$offset="";
			check();
		}
		if ($outtext ne "") {
			if($mode eq "debug") {
				print "mail not sent, cause debug is enabled\n";	
				print "content of mail to $emailaddress would be:\n---------------------------------\n";
				print $outtext;
				print "\n---------------------------------\nend of mail\n";
			} else {
				$Jetztwert = time();
				$Jetztzeit = localtime($Jetztwert);
				$mailer = '/usr/sbin/sendmail';
				if (defined($senderaddress)) {
				$frompart="-f $senderaddress";
				}

				open(MAIL, "|$mailer -t $frompart") || die "Can't open $mailer!\n";
				print MAIL "To: ".$emailaddress."\n";
				print MAIL "Subject: ($thisfile) violation report $Jetztzeit\n\n\n";
				print MAIL $outtext;
				close(MAIL);
				$command="\/usr\/bin\/logger -p warn logcheckprint";
                system($command);
			}
		} else {
			if($mode eq "debug") {
				print "nothing to send, $thisfile seems to be ok\n";	
			}
		}
		if ($noffset ne "") {
			if($mode eq "debug") {
				print "new offset written in ".$thisfile.".offset\n";	
			}
			open(ADR, ">$thisfile.offset");
			       print ADR $noffset;
			close(ADR);
		}
	}
	else
	{
		print STDERR "logfile $thisfile not found...ignoring\n";
	}	
}

unlink($file_pidfile);

exit 0;

sub gettimestamplength() {
	# is reading the first line and guessing how long is the timestring
	open (TEMPLOG,"<$thisfile");
	$firstline = <TEMPLOG>;
	close (TEMPLOG);
	$firstline =~/(^.*\d{2}\:\d{2}\:\d{2}.*?\s)/gm;
	$temptimestring = $1;
	$lengthtimestring = length($temptimestring)-1;
	if($mode eq "debug") {
		print "Following timestamp has been found $temptimestring.\n";
		print "It is $lengthtimestring characters long.\n";
	}
}

sub check() {
	# checks the logfile itself
	open(LOG,"<$thisfile");
	while(<LOG>) 
	{
		if ($jumpover == 0) {
			$wl=0;
			foreach $wltext (@whitelisted) 
			{
				if($_ =~/$wltext/) 
				{
					$wl=1;
				}
			}
			if($wl==0) 
			{
				$outtext=$outtext.$_;
			}
		}	
		$noffset = substr($_,0,$lengthtimestring,);
		if(substr($_,0,$lengthtimestring) eq $offset) {
			$jumpover=0;
			if($mode eq "debug") {
				print "offset found\n";	
			}
		}
	}
	close(LOG);
}

sub getpidfilecontent() {
	$pidstring="unknown";
	open(ADR, "<$file_pidfile");
	while(<ADR>)
	{
		chop($_);
		if(length($_) > 1) {
			if (substr($_,0,1) ne "#") 
			{
				$pidstring = $_;
			}	
		}
	}
	close(ADR);
}
