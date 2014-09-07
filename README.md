isms
====

- check plugin, 
- notification handler / sendSMS and 
- ACKnowledgement addon / CGI handler for the MultitechSMSFinder

http://www.netways.de/en/de/services_expertise/monitoring_hardware/alerting/

- Checks a Multitech SMSFinder and returns if it is connected to the GSM Network and the level of signal strength.
- send an SMS via a Multitech SMSFinder
- handles a received SMS and sets the Acknowledgement in Icinga

### Installation 

*THIS script should be symlinked/copied according to your needs*
If you symlink it, make the CGI handler the original. Your http
server may not accept symlinked CGIs.
So once more - this script is all three in one.

    
### Usage

    check_smsfinder.pl
         -H hostaddress
         [-t|--timeout=<timeout in seconds>]
         [-v|--verbose]
         [-h|--help] [-V|--version]
         [-u|--user=<user>]
         [-p|--password=<password>]

    sendsms.pl
         -H hostaddress
         [-t|--timeout=<timeout in seconds>]
         [-v|--verbose]
         [-h|--help] [-V|--version]
         [-u|--user=<user>]
         [-p|--password=<password>]
         [-s|--splitmax=<number>]
         -n|--number=<telephone number of the recipient>
         -m|--message=<message text>

    smsack.cgi
         [-v|--verbose]
         [-h|--help] [-V|--version]
         CONTENT_LENGTH via ENVIRONMENT
         SMS data       via STDIN (from http post)

    email2sms.pl
         -H hostaddress
         [-t|--timeout=<timeout in seconds>]
         [-v|--verbose]
         [-h|--help] [-V|--version]
         [-u|--user=<user>]
         [-p|--password=<password>]
         [-s|--splitmax=<number>]
         -n|--number=<telephone number of the recipient>
         -m|--message=<message text>

Options:

    -H <hostaddress>
        Hostaddress of the SMSFinder

    -t|--timeout=<timeout in seconds>
        Time in seconds to wait before script stops.

    -v|--verbose
        Enable verbose mode and show whats going on.

    -V|--version
        Print version an exit.

    -h|--help
        Print help message and exit.

    -n|--number
        Telephone number of the SMS recipient

    -m|--message
        SMS message text

    -w|--warning
        Warning level for signal strength in procent. (Default = 40)

    -c|--critical
        Critical level for signal strength in procent. (Default = 20)

    --noma
        NoMa switch - try to check if the send SMS is send, not just queued.

    --use-db
        NDO switch - retrieve details from the NDO Database

    --hostname
        Name of the host (used for DB checks)

    --service
        Service description (used for DB checks)

    --lastchange
        The time that the problem started (in unix time) If this value is
        less than 24 hours old show in HH:MM format, otherwise show in HH:MM
        dd.mm.YYYY format.

        Corresponds to $LASTSERVICESTATECHANGE$

    --type
        The type of alert (PROBLEM, RECOVERY, ACKNOWLEDGEMENT). If this is
        given, the message will be prefixed with *ACK* or *REC* depending on
        the type. Be aware that the extra field will cause problems with
        acknowledgements if you use the suggested notification command.

        Corresponds to $NOTIFICATIONTYPE$



