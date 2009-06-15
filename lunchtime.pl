#!/usr/bin/env perl

use warnings;

use HTTP::Lite;
use Encode;
use POSIX;

%urls = (
  'http://www.finninn.com/finninn/dagens.html', \&finninn_day
  ,'http://www.gladimat.ideon.se/index.html', \&gladimat_day
  ,'http://www.cafebryggan.com/', \&bryggan_day
  ,'http://www.restaurant.ideon.se/', \&ideonalfa_day
  ,'http://sarimner.nu/veckomeny/veckomeny%20v%20YYYY-WW%20se%20hilda%20svensk.pdf', \&sarimner_day # sarimner
        );

@days_match = ("ndag", "Tisdag", "Onsdag", "Torsdag", "Fredag");
%days_print = ("ndag", "Måndag"
              ,"Tisdag", "Tisdag"
              ,"Onsdag", "Onsdag"
              ,"Torsdag", "Torsdag"
              ,"Fredag", "Fredag");

$ntime = time;
$weeknum = POSIX::strftime("%V", localtime($ntime));
$yearweek = POSIX::strftime("%Y-%V", localtime($ntime));
$weeknum = '25';
$yearweek = '2009-25';

foreach $url (keys %urls)
{
  $http = new HTTP::Lite;
  $url_req = $url;
  if ($url_req =~ /sarimner/)
  {
    # url for sarimner has week info in url which needs to be modified
    $url_req =~ s/YYYY-WW/$yearweek/;
    print "mod url: $url_req\n";
  }
  if ($req = $http->request($url_req))
  {
    if ($req eq "200")
    {
      $body = $http->body();
      if ($url =~ /pdf$/)
      {
        $pdffile = 'sarimner.pdf';
        open(PDF, ">$pdffile");
        print PDF $body;
        close PDF;
        my @textlist = qx(pdftohtml -noframes -stdout $pdffile);
        unlink $pdffile;
        #print @textlist;
        $body = join("<nl>", @textlist);
        #print $body;
      }
      foreach $day (@days_match)
      {
        $lunch = $urls{$url}($body, $day);
        #print "$lunch\n";
        $menu{$day} .= "$lunch\n";
      }
    }
    else
    {
      print "Request for $url failed ($req), ".$http->status_message()."...\n";
      next;
    }
  }
  else
  {
    print "request for url $url failed ($!)...\n";
    next;
  }
}

print "<html>\n";
print "<head>\n";
print "<meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">\n";
print "</head>\n";
print "<body>\n";
$timestamp = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($ntime));

$dayofweek = (localtime($ntime))[6];
$date_monday = POSIX::strftime("%Y-%m-%d", localtime($ntime - (($dayofweek - 1) * 24 * 60 * 60)));
$date_friday = POSIX::strftime("%m-%d", localtime($ntime + ((5 - $dayofweek) * 24 * 60 * 60)));

print "<h1>Meny vecka $weeknum ($date_monday &mdash; $date_friday)</h1>\n";
foreach $day (@days_match)
{
  print "<h2>$days_print{$day}</h2>\n";
  print "<table>\n";
  print $menu{$day};
  print "</table>\n";
}

print "<br><br>\n";
print "<hr size=\"0\">\n";
print "<font color=\"#B0B0B0\" size=\"1\">Generated at $timestamp by acatenango</font>\n";
print "</body>\n";
print "</html>\n";

sub sarimner_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<br>.*?$day(.*?)(<b>\d|<nl>Chefs)/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/Cross:\s*//; # choice separator
    $lunch =~ s/Husman:\s*/ :: /; # choice separator
    $lunch =~ s/Vegetariska:\s*/ :: /; # choice separator
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&amp;/o/g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    # remove any extra choice separators at the end
    $lunch =~ s/[: ]+$//;
  }
  else
  {
    $lunch = "No $day found";
  }
  return "<tr><td>Särimner&nbsp;Hilda</td><td>".$lunch."</td></tr>";
}

sub finninn_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<p>.*?$day(.*?)<\/td>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<\/p>/ :: /g; # choice separator
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&nbsp;//g;
    $lunch =~ s/&amp;/o/g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    # remove any extra choice separators at the end
    $lunch =~ s/[: ]+$//;
  }
  else
  {
    $lunch = "No $day found";
  }
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<tr><td>Finn Inn</td><td>".$lunch."</td></tr>";
}

sub gladimat_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<tr>.*?$day.*?<\/td>(.*?)<\/td>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<.*?>//g;
    #print "  LUNCH: $lunch\n";
    $lunch =~ s/&nbsp;//g;
    $lunch =~ s/&amp;/o/g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    #replace  - as separator between lunch choices, but first remove the first sep
    $lunch =~ s/^-\s+//;
    $lunch =~ s/ - / :: /g;
  }
  else
  {
    $lunch = "No $day found";
  }
  return "<tr><td>Glad i mat</td><td>".$lunch."</td></tr>";
}

sub bryggan_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.*?)<\/p>/is)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/\s+/ /g;
    #print "  LUNCH: $lunch\n";
    $lunch =~ s/<br \/>/ :: /g; # choice separator
    $lunch =~ s/Vegetariskt:\s*//;
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&nbsp;//g;

    $lunch =~ s/&amp;/o/g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
  }
  else
  {
    $lunch = "No $day found";
  }
  return "<tr><td>Bryggan</td><td>".$lunch."</td></tr>";
}
sub ideonalfa_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<b>.*?$day.*?<\/b>(.*?)<br><br>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/\s+/ /g;
    #print "  LUNCH: $lunch\n";
    $lunch =~ s/<br>/ - /g;
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&nbsp;//g;

    $lunch =~ s/&amp;/o/g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    #replace  - as separator between lunch choices, but first remove the first sep
    $lunch =~ s/^-\s+//;
    $lunch =~ s/ - / :: /g;
  }
  else
  {
    $lunch = "No $day found";
  }
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<tr><td>Ideon Alfa</td><td>".$lunch."</td></tr>";
}
