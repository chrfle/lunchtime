#!/usr/bin/env perl

use warnings;

use WWW::Curl::Easy;
use Encode;
use POSIX;
use JSON;
use Getopt::Std;


# options f  filter urls to only include matching restaurants
our($opt_d, $opt_f, $opt_w);
getopts('df:w:');

%urls = (
        'http://www.finninn.se/lunch-meny/', [\&finninn_day, \&weeknumtest_none, "Finn&nbsp;Inn"]
       ,'http://www.restauranghojdpunkten.se/index.php?page=Meny', [\&hojdpunkten_day, \&weeknumtest_none, "Höjdpunkten"]
       ,'http://www.ideon-restaurang.se', [\&ideonkryddhyllan_day, \&weeknumtest_none, "Kryddhyllan"]
       ,'https://eurest.mashie.com/public/menu/restaurang+hilda/8b31f89a', [\&hilda_day, \&weeknumtest, "Nya&nbsp;Hilda"]
       ,'http://magnuskitchen.se/veckans-lunch.aspx', [\&magnus_day, \&weeknumtest, "Magnus&nbsp;Kitchen"]
       ,'http://www.annaskok.se/', [\&annaskok_day, \&weeknumtest, "Annas&nbsp;Kök"]
       ,'https://www.fazerfoodco.se/restauranger/restauranger/scotland-yard/', [\&scotlandyard_day, \&weeknumtest_json, "Scotland&nbsp;Yard"]
      #,'http://www.italia-ilristorante.com/dagens-lunch', [\&italia_day, \&weeknumtest_none, "Italia"]
       ,'https://serviceportal.sodexo.se/sv/delta/Start/Lunchmeny/', [\&ideondelta_day, \&weeknumtest_none, "Ideon&nbsp;Delta"]
      #,'http://www.thaiway.se', [\&thaiway_day, \&weeknumtest, "Thai&nbsp;Way"]
       ,'http://www.bryggancafe.se/veckans-lunch/', [\&bryggan_day, \&weeknumtest, "Cafe&nbsp;Bryggan"]
       ,'http://restaurangedison.se/lunch', [\&ideonedison_day, \&weeknumtest, "Ideon&nbsp;Edison"]
       ,'http://www.mediconvillage.se/sv/hogt-i-tak', [\&mediconvillage_day, \&weeknumtest_none, "Medicon&nbsp;Village"]
      #,'http://www.matsalen.nu', [\&matsalen_day, \&weeknumtest_none, "Matsalen"]
       ,'http://brickseatery.se/lunch', [\&bricks_day, \&weeknumtest, "Bricks&nbsp;Eatery"]
       ,'https://www.elite.se/sv/hotell/lund/hotel-ideon/paolos/', [\&paolos_day, \&weeknumtest, "Paolos"]
       ,'http://www.linnersmat.se/category/veckomeny/', [\&linners_day, \&weeknumtest, "Linnérs Mat"]
       ,'http://aptiten.net/#page-menu', [\&aptiten_day, \&weeknumtest, "Aptiten"]
       );

sub urlsort
{
  return $urls{$a}[2] cmp $urls{$b}[2];
}

sub geturl
{
  my ($url) = shift @_;
  my $req;
  my $body = '';
  $http = new WWW::Curl::Easy;
  #$http->setopt(CURLOPT_HEADER, 1);
  $http->setopt(CURLOPT_FOLLOWLOCATION, 1);
  $http->setopt(CURLOPT_URL, $url_req);
  $http->setopt(CURLOPT_WRITEDATA, \$body);
  if (not $req = $http->perform())
  {
    $req = $http->getinfo(CURLINFO_HTTP_CODE);
  }
  return ($req, $body);
}


@days_match = ('ndag', 'Tisdag', 'Onsdag', 'Torsdag', 'Fredag');
#%days_match_english = ('ndag' => 'Monday',
#                       'Tisdag' => 'Tuesday',
#                       'Onsdag' => 'Wednesday',
#                       'Torsdag' => 'Thursday',
#                       'Fredag' => 'Friday');

#%days_match_short = ('ndag' => 'Mån'
#                    ,'Tisdag' => 'Tis'
#                    ,'Onsdag' => 'Ons'
#                    ,'Torsdag' => 'Tors'
#                    ,'Fredag' => 'Fre');

%days_print = ('ndag' => 'Måndag'
              ,'Tisdag' => 'Tisdag'
              ,'Onsdag' => 'Onsdag'
              ,'Torsdag' => 'Torsdag'
              ,'Fredag' => 'Fredag');

%days_ref = ('ndag' => 'mandag'
            ,'Tisdag' => 'tisdag'
            ,'Onsdag' => 'onsdag'
            ,'Torsdag' => 'torsdag'
            ,'Fredag' => 'fredag');

%days_index = ('ndag' => 0
              ,'Tisdag' => 1
              ,'Onsdag' => 2
              ,'Torsdag' => 3
              ,'Fredag' => 4);

$ntime = time;
if ($opt_w)
{
  $weeknum_pad = $opt_w;
  if (length($weeknum_pad) < 2)
  {
    $weeknum_pad = ('0' x length($weeknum_pad)) . $weeknum_pad;
  }
}
else
{
  $weeknum_pad = POSIX::strftime("%V", localtime($ntime));
}
$weeknum = $weeknum_pad;
$weeknum =~ s/^0//; # remove any 0 padding
print STDERR "weeknum: $weeknum, pad $weeknum_pad\n" if $opt_d;

$lb = "dark";
foreach $url (sort urlsort keys %urls)
{
  print STDERR "considering url: $url\n" if $opt_d;
  if ($opt_f)
  {
    next if ($url !~ /$opt_f/);
  }
  print STDERR "handling url: $url\n" if $opt_d;
  if ($lb eq "lght")
  {
    $lb = "dark";
  }
  else
  {
    $lb= "lght";
  }
  $url_req = $url;
  # special url handling for delta
  if ($url =~ /delta/)
  {
    ($req, $body) = geturl($url_req);
    if ($req eq '200')
    {
      # <a href="/sv/delta/Start/Lunchmeny/LunchDelta5/">Lunchmeny 2018 v. 14</a>
      if ($body =~ /LunchDelta(\d+)\/.*Lunchmeny.*?v[\.\s]*$weeknum/m)
      {
        $url_req .= 'LunchDelta' . $1 . '/';
        print STDERR "adjusted url: $url_req\n" if $opt_d;
      }
      else
      {
        print STDERR "no adjustment found\n" if $opt_d;
      }
    }
    else
    {
      print STDERR "problem with adjusting url, err $req\n" if $opt_d;
    }
  }
  elsif ($url =~ /linnersmat/)
  {
    ($req, $body) = geturl($url_req);
    if ($req eq '200')
    {
      if ($body =~ /"(http:\/\/www.linnersmat.se.*?-v-$weeknum\/)"/)
      {
        $url_req = $1;
        print STDERR "adjusted url: $url_req\n" if $opt_d;
      }
      else
      {
        print STDERR "no adjustment found\n" if $opt_d;
      }
    }
    else
    {
      print STDERR "problem with adjusting url, err $req\n" if $opt_d;
    }
  }
  elsif ($url =~ /scotland/)
  {
    my $json_date = POSIX::strftime("%Y-%m-%d", localtime($ntime));
    $json_date =~ s/-0/-/g;
    $url_req = "http://www.fazerfoodco.se/api/restaurant/menu/week?language=sv&restaurantPageId=188211&weekDate=" . $json_date;
    print STDERR "adjusted url: $url_req\n" if $opt_d;
  }

  ($req, $body) = geturl($url_req);
  if ($req eq '200')
  {
    $body =~ s/\n/ /g; # replace all newlines to one space
    $body =~ s/\r/ /g; # replace all newlines to one space
    $body =~ s/&nbsp;/ /g; # all hard spaces to soft
    $body =~ s/&amp;nbsp;/ /g; # all hard spaces to soft
    $body =~ s/&\#160;/ /g;
    $body =~ s/\xa0/ /g; # ascii hex a0 is 160 dec which is also a hard space
    $body =~ s/\xc2/ /g; # convert to space, seems to maybe be part of unicode either 20c2 or c220.
    $body =~ s/&\#65279;/ /g; # BOM char should be ignored, like soft space
    $body =~ s/&lt;/</g;
    $body =~ s/&gt;/>/g;
    $body =~ s/\xbd/&frac12;/g;
  }
  print STDERR "MMM $body MMM\n" if $opt_d;

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
        print STDERR "NNN $body NNN\n" if $opt_d;
      }
    }
    else
    {
      $lunch = "<ul><li><em>Menylänk 'no workie' ($req)</em></li></ul>";
    }
    # replace & with &amp;
    $lunch =~ s/& /&amp; /g;
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
  <a href="https://validator.w3.org/check?uri=referer">
    <img src="https://www.w3.org/Icons/valid-xhtml11" alt="Valid XHTML 1.1" height="31" width="88" /></a>
  <a href="https://jigsaw.w3.org/css-validator/check/referer">
    <img src="https://jigsaw.w3.org/css-validator/images/vcss" alt="Valid CSS" height="31" width="88" /></a>
</div>
</body>
</html>
};

sub hilda_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  # get everything until 5 </div> with space between (which is too much)
  if ($htmlbody =~ /<span class="day">.*?$day.*?<\/span>.*?<section class="day-alternative">(.*?)<\/div>(?:\s*<\/div>){4}/i)
  {
    $lunch = $1;
    #print STDERR "LUNCH1: $lunch\n" if $opt_d;

    my $options = '';
    while ($lunch =~ /<strong.?>.+?<span>(.+?)<\/span>/gms) {
      $options .= "$1 :: ";
    }
    $lunch = substr $options, 0, -4;
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
  if ($htmlbody =~ /<strong.*?>.*?$day.*?<\/strong>.*?<\/p>(.*?)<\/p>/i)
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
  if ($htmlbody =~ /Veckans alternativ.*?<\/strong>.*?<p>(.*?)<\/p>/i)
  {
    $veckans = $1;
    $veckans =~ s/<.*?>//g; # remove all formatting
    $veckans =~ s/&amp;/&/g; # convert all &amp; to simple &
    $veckans =~ s/&/&amp;/g; # and back again to catch any unescaped simple &
    $veckans = ' :: Veckans: ' . $veckans; # add veckans to daily with separator
  }
  $lunch .= $veckans;
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub finninn_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /$day<\/div>.*?<strong>(.+?)<\/li>/)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<br>/ :: /g;
    # remove daily tags
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/Dagens[:\s]*//g;
    $lunch =~ s/Vegetarisk[:\s]*//g;
    $lunch =~ s/Sallad[:\s]*//g;

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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  #$lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub hojdpunkten_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /$day .*?<\/p>(.+?>)(?: <\/p>|<\/td>)/i)
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

    $lunch =~ s/ :: \d+\.\s*/ :: /g; # remove lunch alternative number
    $lunch =~ s/^\d+\.\s*//;         # remove lunch alternative number first
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
  my $lunch = '';
  if ($htmlbody =~ /<u>.*?$day:?(.+?<\/p>.*?)<\/p>/i)
  {
    $lunch = $1;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/\xc2//g; # remove garbage char

    $lunch =~ s/Dagens.*?://g; # remove the names Dagens whatever
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

sub ideonkryddhyllan_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h2 class="ppb_menu_title" >.*?$day.*?<\/h2>(.+?)<div class="menu_multiple_wrapper">/i)
  {
    $lunch = $1;
    # remove price
    $lunch =~ s/<span class="menu_price">.*?<\/span>//g;
    $lunch =~ s/<br class="clear"\/>/ :: /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;

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
  $lunch = encode("utf8", decode("utf8", $lunch));
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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub scotlandyard_day
{
  my ($jsonbody, $day) = @_;
  $jsonbody =~ s/\xb4/'/g;
  my $json = decode_json($jsonbody);
  my $lunch = '';
  $lunch = $json->{'LunchMenus'}[$days_index{$day}]{'Html'};
  if ($lunch)
  {
    $lunch =~ s/\n//g;  # remove newlines
    $lunch =~ s/<\/p><p>.*$//;  # skip last <p> - english
  }
  if ($lunch)
  {
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/<tr>/ :: /g;
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

sub italia_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.+?)(?:<h3>|<\/tr>)/i)
  {
    $lunch = $1;
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/<.*?>//g;
    #remove lunchtags
    $lunch =~ s/Dagens pasta://g;
    $lunch =~ s/Dagens rätt://g;

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
  #$lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub ideondelta_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<strong>.*?$day.*?<\/strong>(.*?)<\/table>/i)
  {
    $lunch = $1;
    #convert lunchtags to separators
    $lunch =~ s/<strong>\s*Traditionell\s*<\/strong>/ :: /g;
    $lunch =~ s/<strong>\s*Medveten\s*<\/strong>/ :: /g;
    $lunch =~ s/<strong>\s*Modern\s*<\/strong>/ :: /g;
    $lunch =~ s/<strong>\s*Vegetarisk\s*<\/strong>/ :: /g;
    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    # remove LF,GF and space
    $lunch =~ s/LF.GF\s+//g;
    $lunch =~ s/GF.LF\s+//g;
    $lunch =~ s/GF\s+//g;
    $lunch =~ s/LF\s+//g;


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
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.*?)<\/table>/i)
  {
    $lunch = $1;
    $lunch =~ s/<\/tr>/ :: /g;
    # remove types and price
    $lunch =~ s/<td class="course_type">.*?<\/td>//g;
    $lunch =~ s/<td class="course_price">.*?<\/td>//g;

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

sub mediconvillage_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  print STDERR "day: $day\n" if $opt_d;
  if ($htmlbody =~ /<h3 class=".*?">.*?$day<\/h3>(.*?)<\/div>\s*<\/div>/i)
  {
    $lunch = $1;

    my $options = '';
    while ($lunch =~ /<\/strong>(?!<)(.+?)<\/p>/gms) {
      if ($1 ne '') {
        $options .= "$1 :: ";
      }
    }
    $lunch = substr $options, 0, -4
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub matsalen_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<p.*?>.*?$day;*(.*?)<\/p>/i)
  {
    $lunch = $1;
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/<.*?>//g;
    #remove lunchtags
    $lunch =~ s/Dagens;//g;
    $lunch =~ s/Veckans alt;//gi;

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

sub bricks_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h3>.*?$day<\/h3>*(.*?)<\/table>/i)
  {
    $lunch = $1;
    # remove pricetags
    $lunch =~ s/<td>[\s\d\:\-]+<\/td><\/tr>/<\/tr>/gi;
    # remove lunchtags
    $lunch =~ s/<td>Local/<td>/g;
    $lunch =~ s/<td>Worldwide/<td>/gi;
    $lunch =~ s/<td>Green/<td>/gi;
    $lunch =~ s/<td>Pizza/<td>Pizza: /gi;
    $lunch =~ s/<tr><td>Café.*?<\/tr>//gi; # remove cafe option altogether

    $lunch =~ s/<\/tr>/ :: /g;
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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub paolos_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<strong>.{0,4}$day.*?<\/strong>(.*?)<strong>/i)
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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub linners_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<strong>.*?$day.*?<\/strong>(.*?)<\/p>/i)
  {
    $lunch = $1;
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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub aptiten_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h2>.*?$day\:?(.*?)<\/h2>/i)
  {
    $lunch = $1;
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
  $lunch = encode("utf8", decode("utf-8", $lunch));
  return "<ul><li>".$lunch."</li></ul>";
}

sub weeknumtest
{
  my ($body) = @_;
  # .? before space allows one garbage character (or . or :)
  return ($body =~ /vecka.?\s+$weeknum/i ||
	  $body =~ /vecka.?\s+$weeknum_pad/i ||
          $body =~ /vecka<\/div>\s*$weeknum/i ||
          $body =~ /<strong menu-week>\s*$weeknum/i ||
          $body =~ /v.?\s{0,3}$weeknum/i ||
          $body =~ /v.?$weeknum_pad/i);
}

sub weeknumtest_json
{
  my ($body) = @_;
  return ($body =~ /"WeekNumber": $weeknum/)
}

sub weeknumtest_none
{
  # no weekday test means always pass
  return 1;
}
