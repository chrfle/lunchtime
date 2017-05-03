#!/usr/bin/env perl

use warnings;

my %day_key = ('mandag'  => 'mon'
               ,'tisdag'  => 'tue'
               ,'onsdag'  => 'wed'
               ,'torsdag' => 'thu'
               ,'fredag'  => 'fri'
               );
my $first_site = 1;
print "{\n";
while (<>)
{
  chomp;
  if (/Meny vecka (\d+) \(([\d-]+) &mdash; ([\d-]+)/)
  {
    my $week_num = $1;
    my $start_date = $2;
    my $end_date = $3;
    $end_date = substr($start_date, 0, 5) . $end_date;
    print "  \"week\" : \"$week_num\",\n";
    print "  \"start\" : \"$start_date\",\n";
    print "  \"end\" : \"$end_date\"";
  }
  elsif (/<h2><a id="(\w+)"/) # new day
  {
    $first_site = 1;
    my $day = $day_key{$1};
    print ",\n";
    print "  \"$day\" : [\n";
  }
  elsif (/<\/table>/)
  {
    print "\n  ]";
  }
  elsif (/<tr class="\w+"><th>(.*?)<\/th>.*?<li>(.*)<\/li><\/ul>/)
  {
    my $site = $1;
    my $lunch = $2;
    $site =~ s/&nbsp;/ /g;
    if (not $first_site)
    {
      print ",\n";
    }
    else
    {
      $first_site = 0;
    }
    $site =~ /<a href="(.*?)">(.*?)<\/a>/;
    print "    {\n";
    print "      \"name\" : \"$2\",\n";
    print "      \"link\" : \"$1\",\n";

    my @lunch_list = split(/<\/li><li>/, $lunch);
    foreach (@lunch_list) # using default $_ works since this is last in while loop
    {
      s/[\s]{2,}/ /g; # remove multi spaces
      s/&amp;/&/g;
      s/&#180;/´/g;
      s/&ouml;/ö/g;
      s/&#246;/ö/g;
      s/&Ouml;/Ö/g;
      s/&#214;/Ö/g;
      s/&auml;/ä/g;
      s/&#228;/ä/g;
      s/&Auml;/Ä/g;
      s/&#196;/Ä/g;
      s/&aring;/å/g;
      s/&#229;/å/g;
      s/&Aring;/Å/g;
      s/&#197;/Å/g;
      s/&agrave;/a/g;
      s/&#224;/a/g;
      s/\xef\xbf\xbd/a/g;
      s/&#232;/è/g;
      s/&eacute;/é/g;
      s/&#233;/é/g;
      # quotes in all forms should be converted to single quote to not mess up json
      s/"/'/g;
      s/&quot;/'/g;
      s/&ldquo;/'/g;
      s/&rdquo;/'/g;
      s/&lsquo;/'/g;
      s/&rsquo;/'/g;

      s/<em>/_/g;
      s/<\/em>/_/g;
    }
    @lunch_list = grep { $_ !~ /(no workie|^&mdash;|Ingen meny)/ } @lunch_list;
    print "      \"menu\" : [ " . join(', ', map { '"' . $_ . '"'} @lunch_list) . " ]\n";
    print "    }";
  }
}
print "\n";
print "}\n";
