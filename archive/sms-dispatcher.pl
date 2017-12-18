#!/usr/bin/perl -w

#
# sms-dispatcher.pl - nagios addon
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
my $nagios_cmd = "/usr/local/nagios/var/rw/nagios.cmd";

my $type=$ARGV[0];
my $file=$ARGV[1];

my $from;
my $sent;
my $received;

my $msg=0;
my $text;
my $status;

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
      # store msg text
      $text.=$_;
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
    my ($cmd,$status)=split(/;/,$msg,2);

    my $comment = "Status changed by $from at $sent";       
        
    open(CMD,">".$nagios_cmd);
    if($cmd eq "PROCESS_SERVICE_CHECK_RESULT") {
      printf(CMD "[%ld] %s;%s;%s\n",$cmd,$status,$comment);
    }
    close (CMD);
    
    print LOG "ACCEPTED: "; 
    
  } else {
    print LOG "NOT ACCEPTED: "; 
  }
  print LOG "From=$from Sent=$sent Received=$received Status=$status MSG=\"$text\"\n";
  close(LOG);
}

