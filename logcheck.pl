#!/usr/bin/perl


require 'logcheck.conf';
$mode="run";


sub head() {
	print "\n";
	print "-----------------------------\n";
	print "This is logcheck.pl V1.0.2\n";
	print "http://peters-webcorner.de\n";
	print "project hosted on origo\n";
	print "http://logcheck.origo.ethz.ch\n";
	print "-----------------------------\n\n";
}

if (($ARGV[0] ne "") && ($ARGV[0] ne "debug")) {
	head();
	print "you can use 'logcheck.pl debug' or 'logcheck.pl' without any parameters\n";
	print "hint: using debug will prevent script from sending mail...\n";
	exit 0;

}

if ($ARGV[0] eq "debug") {
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
				$Sender = $senderaddress;
				open(MAIL, "|$mailer -t") || die "Can't open $mailer!\n";
				print MAIL "To: ".$emailaddress."\n";
				print MAIL "Subject: ($thisfile) violation report $Jetztzeit\n\n\n";
				print MAIL $outtext;
				close(MAIL);
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
exit 0;


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
		$noffset = substr($_,0,15,);
		if(substr($_,0,15) eq $offset) {
			$jumpover=0;
			if($mode eq "debug") {
				print "offset found\n";	
			}
		}
	}
	close(LOG);
}


