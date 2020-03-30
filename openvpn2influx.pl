#!/usr/bin/perl
use warnings;
use strict;
use Time::HiRes;
use autodie;

my $influx_url = shift @ARGV || 'http://influx.ffzg.hr:8086/write?consistency=any&db=telegraf';
my $debug = $ENV{DEBUG} || 0;

while(1) { ## white forever

my $in = 0;

open(my $s, '<', '/var/log/openvpn-ffzg-general-ldap-status.log');
while(<$s>) {
	chomp;

	#warn "##$_##\n";

	if ( m/^Common Name/ ) {
		$in = 1;
		next;
	} elsif ( m/^ROUTING TABLE/ ) {
		$in = 0;
		next;
	} elsif ( m/^Virtual Address/ ) {
		$in = 2;
		next;
	} elsif ( m/^GLOBAL STATS/ ) {
		$in = 0;
		next;
	}

	#warn "# $in [$_]\n";

	my $t = int( Time::HiRes::time() * 1_000_000_000 );

	if ( $in == 1 ) {
		my ( $user, $real_addr, $recv, $send, $since ) = split(/,/);
		my $influx = qq{openvpn_transfer,user=$user real_addr="$real_addr",recv=${recv}i,send=${send}i $t};
		print "$influx\n" if $debug;
		system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
	}

};
close($s);

sleep 10;

} ## while forever


