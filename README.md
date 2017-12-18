# iSMS Notifications

#### Table of Contents

1. [About](#about)
2. [License](#license)
3. [Support](#support)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [FAQ](#faq)

## About

This collection provides scripts for managing SMS notifications with Multitech iSMS (previously called SMSFinder).

The hardware can be obtained in the [NETWAYS shop](https://www.netways.de/hardware/alarmierung/multitech/isms/).

* Plugin `check_smsfinder.pl` which checks if iSMS is connected to the GSM network and its level of signal strength.
* Notification handler `sendsms.pl` to send an SMS via Multitech iSMS.
* Acknowledgement addon `smsack.cgi` and `email2sms.pl` to receive an SMS answer and set an acknowledgement in Icinga.

## License

These plugins are licensed under the terms of the GNU General Public License.
You will find a copy of this license in the COPYING file included in the source package.

## Support

Please head over to the [NETWAYS shop](https://www.netways.de/hardware/alarmierung/multitech/isms/).

## Requirements

* iSMS hardware
* Perl modules: `Getopt::Long`, `File::Basename`, `IO::Socket`, `XML::Simple`

## Installation

### RHEL/CentOS

```
install -d -o root -g root -m755 /usr/lib64/nagios/plugins/isms

install -o root -g root -m755 sendsms.pl /usr/lib64/nagios/plugins/isms
install -o root -g root -m755 smsfinder.pl /usr/lib64/nagios/plugins/isms
```

`email2sms.pl`, `smsack.cgi` and `check_smsfinder.pl` are implemented in the `smsfinder.pl` script.
Therefore symlinks need to be created.

```
cd /usr/lib64/nagios/plugins/isms
ln -s smsfinder.pl check_smsfinder.pl
ln -s smsfinder.pl smsack.cgi
ln -s smsfinder.pl email2sms.pl
```

## Debian/SUSE

```
install -d -o root -g root -m755 /usr/lib/nagios/plugins/isms

install -o root -g root -m755 sendsms.pl /usr/lib/nagios/plugins/isms
install -o root -g root -m755 smsfinder.pl /usr/lib/nagios/plugins/isms
```

`email2sms.pl`, `smsack.cgi` and `check_smsfinder.pl` are implemented in the `smsfinder.pl` script.
Therefore symlinks need to be created.

```
cd /usr/lib/nagios/plugins/isms
ln -s smsfinder.pl check_smsfinder.pl
ln -s smsfinder.pl smsack.cgi
ln -s smsfinder.pl email2sms.pl
```


## Configuration

### Icinga 2

#### Check Plugin

Add a new CheckCommand definition:

```
object CheckCommand "smsfinder" {
	import "ipv4-or-ipv6"

	command = [ PluginDir + "/isms/check_smsfinder.pl" ]

	arguments = {
		"-H" = {
			value = "$smsfinder_address$"
			description = "Hostaddress of the SMSFinder"
		}
		"--user" = {
			value = "$smsfinder_user$"
			description = "The user to login to the SMS Finder"
		}
		"--password" = {
			value = "$smsfinder_password$"
			description = "The password for the specified SMS Finder user"
		}
		"--warning" = {
			value = "$smsfinder_warning$"
			description = "Warning level for signal strength in procent. (Default = 40)"
		}
		"--critical" = {
			value = "$smsfinder_critical$"
			description = "Critical level for signal strength in procent. (Default = 20)"
		}
		"--timeout" = {
			value = "$smsfinder_timeout$"
			description = "Time in seconds to wait before script stops."
		}
	}

	vars.smsfinder_address = "$check_address$"
}
```

Add a new Host definition:

```
object Host "smsfinder" {
	import "generic-host"
	address = "192.168.2.1"

	vars.smsfinder_user = "admin"
	vars.smsfinder_password = "admin"
	vars.smsfinder_warning = 40
	vars.smsfinder_critical = 20
	vars.smsfinder_timeout = 5
}
```

Add a Service apply rule:

```
apply Service "smsfinder_status" {
	import "generic-service"
	check_command = "smsfinder"
	assign where host.vars.smsfinder_user
}
```

#### Notification Script

Add a new NotificationCommand definition for hosts and services:

```
object NotificationCommand "isms-host-notification" {

	command = [ PluginDir + "/isms/sendsms.pl" ]

	arguments = {
		"-H" = {
			value = "$isms_address$"
			description = "Hostaddress of the SMSFinder"
		}
		"--user" = {
			value = "$isms_user$"
			description = "The user to login to the SMS Finder"
		}
		"--password" = {
			value = "$isms_password$"
			description = "The password for the specified SMS Finder user"
		}
		"-n" = {
			value = "$isms_pager$"
			description = "Telephone number of the SMS recipient"
		}
		"-m" = {
			value = "$isms_message$"
			description = "SMS message text"
		}
		"--hostname" = {
			value = "$isms_hostname$"
			description = "Name of the host (used for DB checks)"
		}
		"--type" = {
			value = "$isms_type$"
			description = "The type of alert (PROBLEM, RECOVERY, ACKNOWLEDGEMENT). If this is given, the message will be prefixed with *ACK* or *REC* depending on the type. Be aware that the extra field will cause problems with acknowledgements if you use the suggested notification command. Corresponds to $notification.type$"
		}
		"--use-db" = {
			set_if = "$isms_use_db$"
			description = "IDO switch - retrieve details from the IDO Database"
		}
	}

	vars.isms_pager = "$user.pager$"
	/* Keep the format intact for acknowledgement SMS parsing. */
	vars.isms_message = "$notification.type$ $host.display_name$> is $host.state$ $icinga.long_date_time$ $host.output$"
	vars.isms_hostname = "$host.display_name$"
	vars.isms_type = "$notification.type$"
	vars.isms_use_db = true
}

object NotificationCommand "isms-service-notification" {

	command = [ PluginDir + "/isms/sendsms.pl" ]

	arguments = {
		"-H" = {
			value = "$isms_address$"
			description = "Hostaddress of the SMSFinder"
		}
		"--user" = {
			value = "$isms_user$"
			description = "The user to login to the SMS Finder"
		}
		"--password" = {
			value = "$isms_password$"
			description = "The password for the specified SMS Finder user"
		}
		"-n" = {
			value = "$isms_pager$"
			description = "Telephone number of the SMS recipient"
		}
		"-m" = {
			value = "$isms_message$"
			description = "SMS message text"
		}
		"--hostname" = {
			value = "$isms_hostname$"
			description = "Name of the host (used for DB checks)"
		}
		"--type" = {
			value = "$isms_type$"
			description = "The type of alert (PROBLEM, RECOVERY, ACKNOWLEDGEMENT). If this is given, the message will be prefixed with *ACK* or *REC* depending on the type. Be aware that the extra field will cause problems with acknowledgements if you use the suggested notification command. Corresponds to $notification.type$"
		}
		"--use-db" = {
			set_if = "$isms_use_db$"
			description = "IDO switch - retrieve details from the IDO Database"
		}
	}

	vars.isms_pager = "$user.pager$"
	/* Keep the format intact for acknowledgement SMS parsing. */
	vars.isms_message = "$notification.type$ $host.display_name$,$service.name$> is $service.state$ $icinga.long_date_time$ $service.output$"
	vars.isms_hostname = "$host.display_name$"
	vars.isms_type = "$notification.type$"
	vars.isms_use_db = true
}
```

Add User and UserGroup objects:

```
object User "smsuser" {
	import "generic-user"
	display_name = "SMS Users"
	groups = [ "smsusers" ]

	pager = "0049123456789"
}

object UserGroup "smsusers" {
	display_name = "Icinga 2 SMS Group"
}
```

Add Notification templates:

```
template Notification "isms-host-notification" {
	command = "isms-host-notification"
	states = [ Up, Down ]
	types = [ Problem, Acknowledgement, Recovery, Custom,
		FlappingStart, FlappingEnd,
		DowntimeStart, DowntimeEnd, DowntimeRemoved ]
	period = "24x7"
}

template Notification "isms-service-notification" {
	command = "isms-service-notification"

	states = [ OK, Warning, Critical, Unknown ]
	types = [ Problem, Acknowledgement, Recovery, Custom,
		FlappingStart, FlappingEnd,
		DowntimeStart, DowntimeEnd, DowntimeRemoved ]
	period = "24x7"
}
```

Add Notification apply rules:

```
apply Notification "isms-alerts" to Host {
	import "isms-host-notification"

	user_groups = host.vars.notification.sms.groups

	vars.sms_serveraddress = "192.168.2.1:[port]"
	vars.sms_user = "admin"
	vars.sms_password = "admin"
	assign where host.vars.notification.sms
}

apply Notification "isms-alerts" to Service {
	import "isms-service-notification"

	user_groups = host.vars.notification.sms.groups

	vars.sms_serveraddress = "192.168.2.1:[port]"
	vars.sms_user = "admin"
	vars.sms_password = "admin"
	assign where host.vars.notification.sms
}
```

Add host details for notification apply rules:

```
object Host "host_with_sms_notification" {
  import "generic-host"
  address = "127.0.0.1"

  /* Define notification sms attributes */
  vars.notification["sms"] = {
    groups = [ "smsusers" ]
  }
}
```


## FAQ

### IDO Database Usage for Acknowledgements

You need to edit the connection details in the `smsfinder.pl` and `sendsms.pl` scripts.

Start below this block:

```
# configure here to match your system setup
```


