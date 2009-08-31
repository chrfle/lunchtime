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
  ,'http://www.annaskok.se/Lunchmeny/tabid/130/language/en-US/Default.aspx', \&annaskok_day
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
        #print $body;
      }
      foreach $day (@days_match)
      {
        $lunch = $urls{$url}($body, $day);
        #print "$lunch\n";
  
        $menu{$day} .= "    <tr class=\"$lb\">$lunch</tr>\n";
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
print "<table class=\"lm\">\n";
foreach $day (@days_match)
{
  print "  <tr><th colspan=2>$days_print{$day}</th></tr>\n";
  print $menu{$day};
}
print "</table>\n";

print "<div class=\"footer\">\n";
print "  <p>Generated at $timestamp by acatenango</p>\n";
print "  <a href=\"http://validator.w3.org/check?uri=referer\">\n";
print "    <img src=\"http://www.w3.org/Icons/valid-xhtmlbasic10\"\n";
print "         alt=\"Valid XHTML Basic 1.0\" height=\"31\" width=\"88\" /></a>\n";
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
  if ($htmlbody =~ /<br>.*?$day(.*?)(<br*>\d|<nl>Chefs)/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/Cross:\s*//; # choice separator
    $lunch =~ s/Husman:\s*/ :: /; # choice separator
    $lunch =~ s/Vegetariska.*?:\s*/ :: /; # choice separator
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    # remove any extra choice separators at the end
    $lunch =~ s/[: ]+$//;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  return "<td>Särimner&nbsp;Hilda</td><td><ul><li>".$lunch."</li></ul></td>";
}

sub finninn_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<p>.*?$day(.*?)<\/td>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<\/p>/ :: /g; # choice separator
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    # remove any extra choice separators at the end
    $lunch =~ s/[: ]+$//;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<td>Finn Inn</td><td><ul><li>".$lunch."</li></ul></td>";
}

sub gladimat_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<tr>.*?$day.*?<\/td>(.*?)<\/td>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;

    $lunch =~ s/<.*?>//g;
    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
    #replace  - as separator between lunch choices, but first remove the first sep
    $lunch =~ s/^-\s*//;
    $lunch =~ s/\s+-\s*/ :: /g;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  # add list tags before fiddling with lowcase/upcase, it is easier to find first char in every dish then
  $lunch =~ tr/[A-Z]ÅÄÖ/[a-z]åäö/; # lowercase everything
  $lunch = "<ul><li>".$lunch."</li></ul>";
  # uppercase first char after >
  while ($lunch =~ />([a-z])/)
  {
    my $lch = $1;
    my $uch = uc($lch);
    $lunch =~ s/>$lch/>$uch/g;
  }
  return "<td>Glad i mat</td><td>".$lunch."</td>";
}

sub bryggan_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<h3>.*?$day.*?<\/h3>(.*?)<\/p>/is)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<br \/>/ :: /g; # choice separator
    $lunch =~ s/Vegetariskt:\s*//;
    $lunch =~ s/<.*?>//g;

    #$lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    #$lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  return "<td>Bryggan</td><td><ul><li>".$lunch."</li></ul></td>";
}

sub ideonalfa_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<b>.*?$day.*?<\/b>(.*?)<br><br>/s)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
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
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  $lunch = encode("utf8", decode("iso-8859-1", $lunch));
  return "<td>Ideon Alfa</td><td><ul><li>".$lunch."</li></ul></td>";
}

sub annaskok_day
{
  my ($htmlbody, $day) = @_;
  my $lunch = '';
  if ($htmlbody =~ /<strong>.*?$day.*?<\/strong>:* (.*?)<\/font>/is)
  {
    $lunch = $1;
    $lunch =~ s/\n//g;
    $lunch =~ s/&nbsp;/ /g;
    $lunch =~ s/\s+/ /g;
    $lunch =~ s/<br \/>/ :: /g; # choice separator
    $lunch =~ s/Vegetariskt:\s*//;
    $lunch =~ s/<.*?>//g;

    $lunch =~ s/&amp;/&/g; # convert all &amp; to simple &
    $lunch =~ s/&/&amp;/g; # and back again to catch any unescaped simple &

    $lunch =~ s/^\s+//;
    $lunch =~ s/\s+$//;
  }
  else
  {
    $lunch = "&mdash;";
  }
  $lunch =~ s/ :: /<\/li><li>/g; # change separator to html list
  return "<td>Annas Kök</td><td><ul><li>".$lunch."</li></ul></td>";
}
