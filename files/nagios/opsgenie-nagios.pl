#!/usr/bin/perl -w
# opsgenie-nagios.pl wrapper for setting "smart" priorities based on
# Nagios messages

use strict;
use feature qw(switch);
use Getopt::Long;

my $opsgenie = '/usr/local/bin/opsgenie.pl';
my @pargv;
my $OverwriteQuietHours=0;

# Grab our options.
my %options = ();
GetOptions(\%options, 'apikey=s', 'apikeyfile=s', 'event=s',
        'notification=s', 'priority:i', 'recipients=s', 'application=s',
        'tags=s', 'help|?') or exec($opsgenie, ("-help"));

if (!exists($options{'event'}) ||
    (lc($options{'event'}) ne 'host' && lc($options{'event'}) ne 'service')) {
    print STDERR "$0 wrapper requires -event=[host|service]\n";
    exit 1;
} else {
    push(@pargv, "-event=$options{'event'}");
}
if (exists($options{'priority'})) {
    print STDERR "$0 wrapper cannot accept priority option\n";
}

if (!exists($options{'apikey'}) && !exists($options{'apikeyfile'})) {
    print STDERR "$0 wrapper requires either an apikey or apikeyfile\n";
    exit 1;
} else {
    if (exists($options{'apikey'})) {
        push(@pargv, "-apikey=$options{'apikey'}");
    }
    if (exists($options{'apikeyfile'})) {
        push(@pargv, "-apikeyfile=$options{'apikeyfile'}");
    }
}

if (!exists($options{'recipients'})) {
    print STDERR "$0 wrapper requires a recipients list\n";
    exit 1;
}
push(@pargv, "-recipients=$options{'recipients'}");

$options{'notification'} ||= '';
push(@pargv, "-notification=$options{'notification'}");

# Host problem are "emergency"; note UNREACHABLE is not considered an emergency
if (lc($options{'event'}) eq 'host' && $options{'notification'} =~ '^PROBLEM: ' &&
    !($options{'notification'} =~ 'UNREACHABLE$')) {
    push(@pargv, "-priority=2");
    $OverwriteQuietHours = 1;
}

# Other host events (recoveries/acks) are "high"
elsif (lc($options{'event'}) eq 'host') { push(@pargv, "-priority=1"); }

# Breakdown for services
else {
    # NTP checks are mostly informational, so "high" if critical, otherwise "moderate"
    if    ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .*\/NRPE - Time offset .*Socket timeout/) { push(@pargv, "-priority=-1"); }
    elsif ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .*\/NRPE - Time offset CRITICAL/) { push(@pargv, "-priority=1"); }
    elsif ($options{'notification'} =~ /\/NRPE - Time offset/) { push(@pargv, "-priority=-1"); }
    # Rarely are PROCS checks indicative of service interruption
    elsif ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .*PROCS CRITICAL/) { push(@pargv, "-priority=1"); }
    # RBL criticals aren't emergency worthy
    elsif ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .*\/RBL [Cc]heck CRITICAL/) { push(@pargv, "-priority=1"); }
    # RAID battery cache warnings are "moderate"
    elsif ($options{'notification'} =~ /^PROBLEM: .*Dell Hardware WARNING.*\[probably harmless\]/) { push(@pargv, "-priority=-1"); }
    # UPS warnings need to be emergencies
    elsif ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .*\/UPS WARNING \(/) { push(@pargv, "-priority=2"); $OverwriteQuietHours=1; }
    # Default critical page is an emergency
    elsif ($options{'notification'} =~ /^(PROBLEM|FLAPPING(START|STOP)): .* CRITICAL \(/) { push(@pargv, "-priority=2"); $OverwriteQuietHours=1; }
    # Acknowledgement is "normal"
    elsif ($options{'notification'} =~ /^ACKNOWLEDGEMENT: /) { push(@pargv, "-priority=0"); }
    # Default recovery page is "normal"
    elsif ($options{'notification'} =~ /^RECOVERY: /) { push(@pargv, "-priority=0"); }
    # Everything else (warnings) is "high"
    else { push(@pargv, "-priority=1") }
}

if ($OverwriteQuietHours) {
    if (exists($options{'tags'})) {
        $options{'tags'} = "$options{'tags'},OverwriteQuietHours";
    } else {
        $options{'tags'} = "OverwriteQuietHours";
    }
}

if (exists($options{'tags'})) {
    push(@pargv, "-tags=$options{'tags'}");
}

unshift(@pargv, $opsgenie);
exec @pargv
