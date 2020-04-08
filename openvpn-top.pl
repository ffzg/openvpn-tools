#!/usr/bin/perl
use warnings;
use strict;
use autodie;

use IO::Socket::INET;
use Data::Dump qw(dump); # sudo apt install libdata-dump-perl

my $debug = $ENV{DEBUG} || 0;

my $sock = IO::Socket::INET->new(PeerAddr => 'localhost',
	PeerPort => 2000, # openvpn --management 127.0.0.1 2000
	Proto    => 'tcp') || die "can't connect: $!";

sub in {
	my $expect = shift;
	my $in = <$sock>;
	chomp($in);
	warn "<< [$in]\n" if $debug;
	return $in;
}

my $in = in;
die "expect >INFO" unless $in =~ m/^>INFO/;

my $status;

print $sock "status\n";
while( <$sock> ) {
	s/[\r\n]+$//;
	warn "<< [$_]\n" if $debug;
	last if m/^END/;

	my @v = split(/,/,$_);
	next if $v[0] =~ m/\s+/; # header labels have spaces

	if ( $#v == 4 ) {
		$status->{ $v[0] } = {
			client => $v[1],
			recv => $v[2],
			sent => $v[3],
			since => $v[4]
		}
	} elsif ( $#v == 3 ) {
		$status->{ $v[1] }->{ip} = $v[0];
		$status->{ $v[1] }->{last_ref} = $v[3];
	}

}

print $sock "quit\n";

close($sock);

warn "# status = ",dump($status) if $debug;

my @cols = qw( client ip recv sent since last_ref);

foreach my $login ( sort keys %$status ) {
	my $u = $status->{$login};
	printf("%-10s %-20s %-10s %10s %10s %s - %s\n", $login, map { $u->{$_} } @cols);
}
