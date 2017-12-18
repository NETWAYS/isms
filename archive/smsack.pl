#!/usr/bin/perl -w

#
# smsack.pl - nagios addon
# 
#
# Copyright (C) 2004 Gerd Mueller / Netways GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


use strict;

my $object_cache = "/usr/local/nagios/var/objects.cache";
my $submit = "/usr/local/nagios/libexec/eventhandlers/submit_check_result";
my $nagios_cmd = "/usr/local/nagios/var/rw/nagios.cmd";

my $ok = "Antwort ist JA";
my $ack = "Antwort ist NEIN";

my $type=$ARGV[0];
my $file=$ARGV[1];

my $from;
my $sent;
my $received;

my $msg=0;
my $text;
my $status;

my $host="";
my $service="";

if($type =~ m/RECEIVED/) {
  
  open(SMS,"<".$file);
  while(<SMS>) {
    chomp();
    if(m/^FROM: (.*)/i) {
      $from=$1; 
    } elsif (m/^SENT: (.*)/i) {
      $sent=$1;
    } elsif (m/^RECEIVED: (.*)/i) {
      $received=$1;
    } elsif (m/^$/) {
      $msg=1;
    } 
   
    # check new status 
    if($msg) {
      if(m/$ok/) {
        $status="OK";
      } elsif(m/$ack/) {
        $status="ACK";
      } else {
        # store msg text
        $text.=$_;
      }
    }
  }
  $text =~ s/\n/ /g;
  close(SMS);

  my $found=0;
  open(NCFG,"<".$object_cache);
  while(<NCFG>) {
    if(m/pager\s+(\d+)/) {
      if($from eq $1) {
        # pager is ok
        $found=1;
        last;
      } 
    }
    
  }
  close(NCFG);

  # log new msg
  open(LOG,">>/var/log/sms-incoming.log");

  if($found) {

    # get service/host from msg
    $host = $1 if($text =~ m/ from Host (.*) with Address /);
    $service = $1 if($text =~ m/Service: (.*) from Host /);

    my $comment = " by $from at $sent";

    # set service OK
    if($status eq "OK") {

       my $statuscode=0;
       $comment="Reset".$comment;
       system($submit." \"$host\" \"$service\" $statuscode \"$comment\"");
       open(CMD,">>".$nagios_cmd);
       print CMD "[".time()."] ENABLE_SVC_NOTIFICATIONS;".$host.";".$service."\n";
       close(CMD);

    # aknowledge service
    } elsif($status eq "ACK") {
       $comment="Aknowledged".$comment;

       open(CMD,">>".$nagios_cmd);
       print CMD "[".time()."] ACKNOWLEDGE_SVC_PROBLEM;".$host.";".$service.";2;0;1;".$from.";".$comment."\n";
       print CMD "[".time()."] DISABLE_SVC_NOTIFICATIONS;".$host.";".$service."\n";
       close(CMD);

    } 
    print LOG "ACCEPTED: "; 
  } else {
    print LOG "NOT ACCEPTED: "; 
  }
  print LOG "From=$from Sent=$sent Received=$received Status=$status Host=$host Service=$service MSG=\"$text\"\n";
  close(LOG);
}

