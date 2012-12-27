#!/usr/bin/perl -w
use strict;
use XML::Simple;

my $xml = `cat schedule`;
my $ref = XMLin($xml);

# use Data::Dumper;
# print Dumper($ref);


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#    localtime(time-(60*60*24*5));
    localtime(time);
$mon+=1;
$year+=1900;

if ($hour < 4) {
    $mday--;
    $hour+=24;
}

my %seen;

sub ttm ($) {
# time to minutes
    if ($_[0] =~ /(\d+):(\d+)/) {
	return ($1*60 + $2);
    }
    return 0;
}

sub search($$$);

sub search($$$) {
# die eigentliche Suche

    my ($saal, $recurse, $offset) = (@_);
    my $found = 0;

    foreach my $day (@{$ref->{day}}) {
	
	next unless $day->{date} eq "$year-$mon-$mday";
	
	foreach my $event_id ( keys %{$day->{room}->{$saal}->{event}} ) {
	    
	    my $event = $day->{room}->{$saal}->{event}->{$event_id};
	    
	    my $now = $hour*60 + $min + $offset;
	    if ($now >= ttm($event->{start})
		and
		$now <= ttm($event->{start})+ttm($event->{duration})
		and
		!exists $seen{$event_id}) {

		my @persons;

		if (exists $event->{persons}->{person}->{content}) {
		    push @persons, $event->{persons}->{person}->{content};
		} else {
		    @persons = map { $_->{content} } values %{$event->{persons}->{person}};
		}
		
		$seen{$event_id}++; ### WTF HACKS!

		printf("  %sh -> +%sh  %s\n                     [%s]\n\n",
		       $event->{start},
		       $event->{duration},
		       $event->{title},
		       join (', ', @persons)
		    );
		$found++;
		
		if ($recurse) {
		    $offset = $offset + ttm($event->{duration});
		    search($saal, 0, $offset);
		}
	    }
	    
	}
	
    }

    return $found;
}

foreach my $saal ('Saal 1', 'Saal 4', 'Saal 6') {
    print "$saal:\n";

    foreach my $lookahead (qw(0 20 40 60 80 100 120 140 160 180)) {
	last if search($saal, 1, $lookahead);
    }
}
