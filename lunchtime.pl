#!/usr/bin/env perl

use warnings;

use WWW::Curl::Easy;
use Encode;
use POSIX;
use Getopt::Std;


# options f  filter urls to only include matching restaurants
getopts('f:');

%urls = (
  'http://www.finninn.com/dagens.html', [\&finninn_day, \&weeknumtest, "Finn&nbsp;Inn"]
#,'http://www.restauranghojdpunkten.se/index.php?page=Meny', [\&hojdpunkten_day, \&weeknumtest, "Höjdpunkten"]
 ,'http://www.restaurant.ideon.se/', [\&ideonalfa_day, \&weeknumtest, "Ideon&nbsp;Alfa"]
 ,'http://www.yourvismawebsite.com/sarimner-restauranger-ab/restaurang-hilda/lunch-meny/svenska', [\&sarimner_day, \&weeknumtest, "Särimner&nbsp;Hilda"]
 ,'http://www.magnuskitchen.se/', [\&magnus_day, \&weeknumtest, "Magnus&nbsp;Kitchen"]
 ,'http://www.annaskok.se/', [\&annaskok_day, \&weeknumtest, "Annas&nbsp;Kök"]
 ,'http://www.amica.se/scotlandyard', [\&scotlandyard_day, \&weeknumtest_none, "Scotland&nbsp;Yard"]
 ,'http://www.italia-ilristorante.com/dagens-lunch/lund', [\&italia_day, \&weeknumtest, "Italia"]
 ,'http://delta.gastrogate.com/page/3', [\&ideondelta_day, \&weeknumtest_none, "Ideon&nbsp;Delta"]
 ,'http://www.thaiway.se/meny.html', [\&thaiway_day, \&weeknumtest, "Thai&nbsp;Way"]
 ,'http://bryggancafe.se/veckomeny.html', [\&bryggan_day, \&weeknumtest, "Cafe&nbsp;Bryggan"]
 ,'http://www.restaurangedison.se/Bizpart.aspx?tabId=191', [\&ideonedison_day, \&weeknumtest, "Ideon&nbsp;Edison"]
        );
sub urlsort {
  return $urls{$a}[2] cmp $urls{$b}[2];
}

@days_match = ('ndag', 'Tisdag', 'Onsdag', 'Torsdag', 'Fredag');
%days_match_short = ('ndag', 'Mån'
                    ,'Tisdag', 'Tis'
                    ,'Onsdag', 'Ons'
                    ,'Torsdag', 'Tor'
                    ,'Fredag', 'Fre');

%days_print = ('ndag', 'Måndag'
              ,'Tisdag', 'Tisdag'
              ,'Onsdag', 'Onsdag'
              ,'Torsdag', 'Torsdag'
              ,'Fredag', 'Fredag');

%days_ref = ('ndag', 'mandag'
            ,'Tisdag', 'tisdag'
            ,'Onsdag', 'onsdag'
            ,'Torsdag', 'torsdag'
            ,'Fredag', 'fredag');

$ntime = time;
$weeknum_pad = POSIX::strftime("%V", localtime($ntime));
$weeknum = $weeknum_pad;
$weeknum =~ s/^0//; # remove any 0 padding

$lb = "dark";
foreach $url (sort urlsort keys %urls)
{
  if ($opt_f)
  {
    next if ($url !~ /$opt_f/);
  }
  if ($lb eq "lght")
  {
    $lb = "dark";
  }
  else
  {
    $lb= "lght";
  }
  $url_req = $url;
  $body = '';
  $http = new WWW::Curl::Easy;
  $http->setopt(CURLOPT_HEADER, 1);
  $http->setopt(CURLOPT_URL, $url_req);
  $http->setopt(CURLOPT_WRITEDATA, \$body);
  if (not $req = $http->perform())
  {
    $req = $http->getinfo(CURLINFO_HTTP_CODE);
  }

  if ($req eq '200')
  {
    $body =~ s/\n/ /g; # replace all newlines to one space
    $body =~ s/\r/ /g; # replace all newlines to one space
    $body =~ s/&nbsp;/ /g; # all hard spaces to soft
    $body =~ s/&\#160;/ /g;
    $body =~ s/\xa0/ /g; # ascii hex a0 is 160 dec which is also a hard space
  }

  foreach $day (@days_match)
  {
    if ($req eq '200')
    {
      # check if we have menu for correct week
      if ($urls{$url}[1]->($body))
      {
        $lunch = $urls{$url}[0]->($body, $day);
      }
      else
      {
        $lunch = "<ul><li><em>Ingen meny för vecka $weeknum</em></li></ul>";
      }
    }
    else
    {
      $lunch = "<ul><li><em>Menylänk 'no workie' ($req)</em></li></ul>";
    }
    $menu{$day} .= "    <tr class=\"$lb\"><th><a href=\"".$url."\">".$urls{$url}[2]."</a></th><td>$lunch</td></tr>\n";
  }
}

#print "<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">\n";
print qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>Lunch time</title>
<link rel="stylesheet" type="text/css" href="static/lt.css" />
<meta http-equiv="content-type" content="text/html;charset=utf-8" />
<meta name="viewport" content="initial-scale=1.0,width=device-width" />
<link href="/food/favicon.png" rel="icon" type="image/x-icon" />
<script type="text/javascript">
<!--  
  function ld() {
    if (window.location.hash != '') {
      return;
    }
    var daymap = ["sondag","mandag","tisdag","onsdag","torsdag","fredag","lordag"];
    var d = new Date();
    var today = d.getDay();
    if (today > 1 && today <= 5) {
      document.getElementById(daymap[today]).scrollIntoView();
    }
  }
  window.onload = ld;
// -->  
</script>
</head>
<body>
};
$timestamp = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($ntime));

$dayofweek = (localtime($ntime))[6];
$date_monday = POSIX::strftime("%Y-%m-%d", localtime($ntime - (($dayofweek - 1) * 24 * 60 * 60)));
$date_friday = POSIX::strftime("%m-%d", localtime($ntime + ((5 - $dayofweek) * 24 * 60 * 60)));

print "<h1 onclick=\"ld()\">Meny vecka $weeknum ($date_monday &mdash; $date_friday)</h1>\n";
# I <3 bacon
foreach $day (@days_match)
{
  if ($menu{$day} =~ /bacon/i)
  {
    print "<div><img src=\"static/iheartbacon.gif\" alt=\"I heart bacon\" /></div>\n";
    last;
  }
}

foreach $day (@days_match)
{
  print "<h2><a id=\"$days_ref{$day}\">$days_print{$day}</a></h2>\n";
  print "<table class=\"lm\">\n";
  print "  <tbody>\n";
  print $menu{$day};
  print "  </tbody>\n";
  print "</table>\n";
}

print qq{<div class="footer">
  <p>Generated at $timestamp by cotopaxi</p>
  <a href="http://validator.w3.org/check?uri=referer">
    <img src="http://www.w3.org/Icons/valid-xhtml11" alt="Valid XHTML 1.1" height="31" width="88" /></a>
  <a href="http://jigsaw.w3.org/css-validator/check/referer">
    <img src="http://jigsaw.w3.org/css-validator/images/vcss" alt="Valid CSS" height="31" width="88" /></a>
</div>
</body>
</html>
};

sub sarimner_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  # always three alternatives
  if ($htmlbody =~ /<p>.*?$day.*?<\/p>(.+?<\/p>.+?<\/p>.+?<\/p>)/)
  {
    $lunch = $1;
    # remove any single colons after tag
    $lunch =~ s/>: />/g;
    $lunch =~ s/>Dagens.*?:/> :: /g;
    $lunch =~ s/>Vegetarisk.*?:/> :: /;
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub magnus_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  my $veckans = '';
  if ($htmlbody =~ />.*?$day\s*<\/(?:span>|strong>)(.*?)<\/tr>/i)
  {
    $lunch = $1;
    $lunch =~ s/<.*?>//g; # remove all formatting
    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g; # remove double sep
  }
  else
  {
    $lunch = "&mdash;";
  }
  if ($htmlbody =~ /Veckans alternativ.*?<\/span>.*?<\/td>(.*?)<\/tr>/i)
  {
    $veckans = $1;
    $veckans =~ s/<.*?>//g; # remove all formatting
    $veckans =~ s/&amp;/&/g; # convert all &amp; to simple &
    $veckans =~ s/&/&amp;/g; # and back again to catch any unescaped simple &
    $veckans = ' :: Veckans: ' . $veckans; # add veckans to daily with separator
  }
  $lunch .= $veckans;
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub finninn_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h2>.*?$day.*?(?:<p>|<td .*?>)(.+?)<\/td>/)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/(<\/p>|<br>)/ :: /g; # choice separator
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub hojdpunkten_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /$day\s*?<\/span>(.+?)(?:<span style="color: #|<\/td>)/)
  {
    $lunch = $1;
    $lunch =~ s/<\/p>/ :: /g;
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;

    $lunch =~ s/ :: \d+\. / :: /g; # remove lunch alternative number
    $lunch =~ s/^\d+\. //;         # remove lunch alternative number first
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub bryggan_day
{
  my ($htmlbody, $day) = @_;
  my $day_short = $days_match_short{$day};
  my $lunch = '';
  if ($htmlbody =~ /<strong>$day_short:\s*<\/strong>(.+?)(?:<\/p>|<br \/>)/i)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub ideonalfa_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<span style.*$day.*?<\/span>(.+?Veg[ae]tarisk.+?)<\/p>/i)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<p>/ - /g;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    #replace  - as separator between lunch choices, but first remove the first sep
    $lunch =~ s/^[- ]+//;
    # and remove any stray separators (and space) at end
    $lunch =~ s/[- ]+$//;
    $lunch =~ s/ - / :: /g;
    $lunch =~ s/Dagens.*?://g; # remove the names Dagens whatever
    $lunch =~ s/Vegatarisk/Vegetarisk/g; # sometimes it's hard to 

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub annaskok_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h6>.*?$day:*<\/h6>(.+?)<\//i)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub scotlandyard_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<td><strong>.*?$day<\/strong><\/td>(.+?)(?:<strong>|<\/table>)/)
  {
    $lunch = $1;
    $lunch =~ s/<\/td>/ :: /g;
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub italia_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.+?)(?:<h3>|<\/tr>)/i)
  {
    $lunch = $1;
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub ideondelta_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ />.*?$day.*?<\/li>(.*?<\/table>.*?<\/table>.*?<\/table>)/i)
  {
    $lunch = $1;
    $lunch =~ s/>\d+:-</></g; # remove price
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &
    #convert lunchtags to separators
    $lunch =~ s/Traditionell:/ :: /g;
    $lunch =~ s/Medveten:/ :: /g;
    $lunch =~ s/Vegetarisk:/ :: /g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub thaiway_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /Meny start-->(.*)<\/P>.*?<!--Meny end-->/i)
  {
    $lunch = $1;
    $lunch =~ s/<P class=subhead_meny>/ :: /g;
    if ($day eq 'ndag')
    {
      $lunch =~ s/<DIV class=text_meny>/: /g;
    }
    else
    {
      $lunch =~ s/<DIV class=text_meny>.*?<\/DIV>//g;
    }

    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub ideonedison_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<strong>.*?$day\s*<\/strong>(.*?)<br \/>\s*<br \/>/i)
  {
    $lunch = $1;
    $lunch =~ s/<br \/>/ :: /g;
    # remove daily tags
    $lunch =~ s/Local://g;
    $lunch =~ s/World Wide://g;
    $lunch =~ s/Green://g;

    $lunch =~ s/<.*?>//g;

    # remove any extra choice separator and space at either end
    # remove double sep
    $lunch =~ s/[:\s]+$//;
    $lunch =~ s/^[:\s]+//;
    $lunch =~ s/\s::(?:\s+::)+\s/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub weeknumtest
{
  my ($body) = @_;
  return ($body =~ /v\D*$weeknum/i || # only annas uses short week indicator
          $body =~ /vecka\D*$weeknum/i ||
	  $body =~ /vecka\D*$weeknum_pad/i);
}

sub weeknumtest_none
{
  # no weekday test means always pass
  return 1;
}
