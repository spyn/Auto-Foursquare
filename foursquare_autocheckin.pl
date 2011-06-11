#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  foursquare_autocheckin.pl
#
#        USAGE:  Run the script, it'll look forever. Ctrl-C to end.
#
#  DESCRIPTION:  $gbid is your google badge id
#                $fsid is the 
#
#         TODO:  Database instead of hash
#                Save the last location into the database also
#       AUTHOR:  Mattie Finch (spyn@iinet.net.au( 
#      VERSION:  0.1
#      CREATED:  09/06/11 16:55:53
#===============================================================================

use strict;
use warnings;

use Geo::Google::Latitude;
use IO::Socket;
use Data::Dumper;
use MIME::Base64;

# My google badge id
my $gbid = "GOOGLE BADGE ID HERE";
my $fsid = encode_base64('YOUR_USERNAME_HERE' . ':' . 'YOUR_PASSWORD_HERE');

my %hotspots = ( 'Test' =>  { "LatMin" => -31.94700,
                            "LatMax" => -31.94624,
                            "LonMin" => 115.8215,
                            "LonMax" => 115.8224,
                            "Foursquare" => "485857",
                           },
                       );  
#---------------------------------------------------------------------------------
# Magic below

my $place; # place name
my $value; # see above
my $clat; # current lat
my $clon; # current long
my $last_checkin = 0;

do {

    ($clat, $clon) = _get_current_location($gbid);

    print "You are here: $clat $clon\n";

    while (($place, $value) = each %hotspots) {
        foreach my $v ($value) {
            if(($clat < $v->{'LatMax'} && $clat > $v->{'LatMin'}) &&
               ($clon < $v->{'LonMax'} && $clon > $v->{'LonMin'}) &&
                $v->{'Foursquare'} != $last_checkin  ) {
                # I'm at the location 
                print "I've reached $place.\n";
                sleep(300); # wait 5 mins to confirm
                ($clat, $clon) = _get_current_location($gbid);
                if(($clat < $v->{'LatMax'} && $clat > $v->{'LatMin'}) &&
                   ($clon < $v->{'LonMax'} && $clon > $v->{'LonMin'})) {
                    print "Confirmed that I am at $place. Adding Foursquare\n";

                    # tell foursquare
                    _set_foursquare_location($v->{'Foursquare'}, $fsid, $clat, $clon);
                    $last_checkin = $v->{'Foursquare'};
                }
            }
        }
    }
 

    sleep(600); # 10 mins 
} while (1 == 1);
# loop FOREVER


sub _get_current_location {
    my $id = shift;
    my $gl=Geo::Google::Latitude->new;
    my $badge=$gl->get($id);
    my ($lat, $lon) = $badge->point->latlon;
    return ($lat, $lon);
}

sub _set_foursquare_location {
    (my $foursquare, my $fsid, my $lat, my $long) = @_;

    my $sock = IO::Socket::INET->new(PeerAddr=>'api.foursquare.com', PeerPort=>80,
                                 Proto =>'tcp', Type=>SOCK_STREAM) or die;
    my $str = "vid=$foursquare&private=0&geolat=$lat&geolong=$long";
    print $sock "POST /v1/checkin HTTP/1.1\r\nHost: api.foursquare.com\r\nUser-Agent:"
                ." Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ "
                ."(KHTML, like Gecko) Version/3.0 Mobile/1C10 Safari/419.3\r\nContent"
                ."-Type: application/x-www-form-urlencoded\r\nAuthorization: Basic "
                .$fsid."\r\nContent-length: ", length($str)+2, "\r\n\r\n$str\r\n";

}
