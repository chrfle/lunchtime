#!/usr/bin/env perl

use warnings;

use HTTP::Lite;
use Encode;
use POSIX;

$version = "1.0.0";

%urls = (
 'http://www.finninn.com/finninn/dagens.html', [\&finninn_day, \&weeknumtest, "Finn&nbsp;Inn"]
,'http://www.restauranghojdpunkten.se/Meny', [\&hojdpunkten_day, \&weeknumtest, "Höjdpunkten"]
,'http://www.cafebryggan.com/', [\&bryggan_day, \&weeknumtest, "Cafe&nbsp;Bryggan"]
,'http://www.restaurant.ideon.se/', [\&ideonalfa_day, \&weeknumtest, "Ideon&nbsp;Alfa"]
,'http://sarimner.nu/veckomeny/veckomeny%20v%20YYYY-WW%20se%20hilda%20svensk.pdf', [\&sarimner_day, \&weeknumtest, "Särimner&nbsp;Hilda"]
,'http://www.annaskok.se/Lunchmeny/tabid/130/language/en-US/Default.aspx', [\&annaskok_day, \&weeknumtest, "Annas&nbsp;Kök"]
,'http://www.fazeramica.se/templates/Fazer_RestaurantMenuPage.aspx?id=85572&epslanguage=SV', [\&scotlandyard_day, \&weeknumtest_none, "Scotland&nbsp;Yard"]
        );

@days_match = ("ndag", "Tisdag", "Onsdag", "Torsdag", "Fredag");
%days_print = ("ndag", "Måndag"
              ,"Tisdag", "Tisdag"
              ,"Onsdag", "Onsdag"
              ,"Torsdag", "Torsdag"
              ,"Fredag", "Fredag");

%days_ref = ("ndag", "mandag"
            ,"Tisdag", "tisdag"
            ,"Onsdag", "onsdag"
            ,"Torsdag", "torsdag"
            ,"Fredag", "fredag");

$ntime = time;
$weeknum_pad = POSIX::strftime("%V", localtime($ntime));
$weeknum = $weeknum_pad;
$weeknum =~ s/^0//; # remove any 0 padding
$yearweek = POSIX::strftime("%Y-", localtime($ntime)).$weeknum;

$lb = "dark";
foreach $url (keys %urls)
{
  if ($lb eq "lght")
  {
    $lb = "dark";
  }
  else
  {
    $lb= "lght";
  }
  $http = new HTTP::Lite;
  $url_req = $url;
  if ($url_req =~ /sarimner/)
  {
    # url for sarimner has week info in url which needs to be modified
    $url_req =~ s/YYYY-WW/$yearweek/;
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
      }
      else
      {
        $body =~ s/\n/ /g; # convert all newlines to one space
      }
      #print $body;
    }
    else
    {
      print "<!-- Request for $url_req failed ($req) -->\n";
    }
    foreach $day (@days_match)
    {
      if ($req eq "200")
      {
        # check if we have menu for correct week
        if ($urls{$url}[1]->($body))
        {
          $lunch = $urls{$url}[0]->($body, $day);
          #print "$lunch\n";
        }
        else
        {
          open(F, ">>lunchtime_fail.log");
          print F "-- start ---------- $url -- $day -------------\n";
          print F $body;
          print F "-- end -- --------- $url -- $day -------------\n";
          close F;
          $lunch = "<ul><li><em>Ingen meny för vecka $weeknum</em></li></ul>";
        }
      } 
      else
      {
        $lunch = "<ul><li><em>Menylänk 'no workie' ($req)</em></li></ul>";
      }
      $menu{$day} .= "    <tr class=\"$lb\"><th>".$urls{$url}[2]."</th><td>$lunch</td></tr>\n";
    }
  }
  else
  {
    print "request for url $url failed ($!)...\n";
  }
}

#print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML Basic 1.0//EN\" \"http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd\">\n";
print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n";
print "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n";
print "<head>\n";
print "  <title>Lunch time</title>\n";
print "  <link rel=\"stylesheet\" type=\"text/css\" href=\"static/lunchtime.css\" />\n";
print "  <meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\" />\n";
print "</head>\n";
print "<body>\n";
$timestamp = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($ntime));

$dayofweek = (localtime($ntime))[6];
$date_monday = POSIX::strftime("%Y-%m-%d", localtime($ntime - (($dayofweek - 1) * 24 * 60 * 60)));
$date_friday = POSIX::strftime("%m-%d", localtime($ntime + ((5 - $dayofweek) * 24 * 60 * 60)));

print "<h1>Meny vecka $weeknum ($date_monday &mdash; $date_friday)</h1>\n";
foreach $day (@days_match)
{
  print "<h2><a id=\"$days_ref{$day}\">$days_print{$day}</a></h2>\n";
  print "<table class=\"lm\">\n";
  print "  <tbody>\n";
  print $menu{$day};
  print "  </tbody>\n";
  print "</table>\n";
}

print "<div class=\"footer\">\n";
print "  <p>Generated at $timestamp by lunchtime $version on acatenango</p>\n";
print "  <a href=\"http://validator.w3.org/check?uri=referer\">\n";
print "    <img src=\"http://www.w3.org/Icons/valid-xhtml11\"\n";
print "         alt=\"Valid XHTML 1.1\" height=\"31\" width=\"88\" /></a>\n";

print "</div>\n";
print "</body>\n";
print "</html>\n";

sub sarimner_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  #print "BODY\n$htmlbody\n";
  if ($htmlbody =~ /<br>.*?$day(.+?)(<br*>\d|<nl>Chefs)/s)
  {
    $lunch = $1;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/Cross:\s*//; # choice separator
    $lunch =~ s/Husman:\s*/ :: /; # choice separator
    $lunch =~ s/Vegetariska.*?:\s*/ :: /; # choice separator
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/[:\s]+$//; # remove any extra choice separators (and space) at the end
    $lunch =~ s/^[:\s]+//; # and beginning
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/\s+::\s+/<\/li><li>/g; # change separator to html list
  return "<ul><li>".$lunch."</li></ul>";
}

sub finninn_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<p>.*?$day(.+?)<\/td>/)
  {
    $lunch = $1;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<\/p>/ :: /g; # choice separator
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/[:\s]+$//; # remove any extra choice separators (and space) at the end
    $lunch =~ s/^[:\s]+//; # and beginning
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
  # Finding a days choice is tricky, cut out everything between the day we are after and the next
  # day (or h2). We only look for 'dag' in the next day, so we have to also have in a strong tag.
  # However there may be <br /> before or after the day. Also there may be strongs in the day choice.
  # Usually empty strongs, but we still need to take them into account.
  if ($htmlbody =~ /<strong>.*?$day.*?<\/strong>(.+?)(<strong>[<br \/>]*?\w+dag.*?<\/strong>|<h2>)/)
  {
    $lunch = $1;
    $lunch =~ s/<span style="color: #c0c0c0[^:]*?<\/span>//g; # remove english versions, but not any separators which might be in a grey span
    $lunch =~ s/<span style="color: #888888[^:]*?<\/span>//g; # another shade of grey
    # removing english above must be done before we convert linebreaks to :: else we trip ourselves up
    $lunch =~ s/<br \/>/ :: /g;
    $lunch =~ s/>&nbsp;<\/p>/> :: /g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<.*?>//g;
    $lunch =~ s/[:\s]+$//; # remove any extra choice separators (and space) at the end
    $lunch =~ s/^[:\s]+//; # and beginning
    $lunch =~ s/\s*::\s+::\s*/ :: /g; # remove double sep
    $lunch =~ s/[: ]+ Sallad.*//g; # and remove Sallad which is always included
    $lunch =~ s/::\s+::/::/g;
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
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.+?)<\/p>/i)
  {
    $lunch = $1;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<br \/>/ :: /g; # choice separator
    $lunch =~ s/Vegetariskt:\s*//;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/[:\s]+$//; # remove any extra choice separators (and space) at the end
    $lunch =~ s/^[:\s]+//; # and beginning
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
  if ($htmlbody =~ /<b>.*?$day.*?<\/b>(.+?)<br><br>/)
  {
    $lunch = $1;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<br>/ - /g;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    #replace  - as separator between lunch choices, but first remove the first sep
    $lunch =~ s/^-\s+//;
    $lunch =~ s/ - / :: /g;
    $lunch =~ s/Dagens.*?://g; # remove the names Dagens whatever
    $lunch =~ s/::\s+::/::/g;
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
  if ($htmlbody =~ /<strong>.*?$day.*?<\/strong>:* (.+?)<\/font>/is)
  {
    $lunch = $1;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<br \/>/ :: /g; # choice separator
    $lunch =~ s/Vegetariskt:\s*//;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/[:\s]+$//; # remove any extra choice separators (and space) at the end
    $lunch =~ s/^[:\s]+//; # and beginning
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
  if ($htmlbody =~ /menufactstext.*?<p>.*?$day.*?<br \/>(.+?)<\/p>/)
  {
    $lunch = $1;
    $lunch =~ s/<br \/>/<\/li><li>/g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  return "<ul><li>".$lunch."</li></ul>";
}

sub weeknumtest
{
  my ($body) = @_;
  return ($body =~ /v\.&\#160;$weeknum/i || #only annas uses short week indicator (but uses &#160; for space
          $body =~ /vecka\D*$weeknum/i ||
	  $body =~ /vecka\D*$weeknum_pad/i);
}

sub weeknumtest_none
{
  # no weekday test means always pass
  return 1;
}
