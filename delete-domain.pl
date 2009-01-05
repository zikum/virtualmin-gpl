#!/usr/local/bin/perl

=head1 delete-domain.pl

Delete one or more virtual servers.

To delete one or many servers (and all of their sub-servers and alias domains)
from the system, use this program. The domains to remove can be specified with
the C<--domain> flag, must can be given multiple times. Alternately, you can
select virtual servers by username, using the C<--user> flag.

The C<--only> option can be used to not actually delete the servers, but
instead simply remove them from the control of Virtualmin.

Be careful with this program, as unlike the server deletion function in the
Virtualmin web interface, it will NOT prompt for confirmation!

=cut

package virtual_server;
if (!$module_name) {
	$main::no_acl_check++;
	$ENV{'WEBMIN_CONFIG'} ||= "/etc/webmin";
	$ENV{'WEBMIN_VAR'} ||= "/var/webmin";
	if ($0 =~ /^(.*\/)[^\/]+$/) {
		chdir($1);
		}
	chop($pwd = `pwd`);
	$0 = "$pwd/delete-domain.pl";
	require './virtual-server-lib.pl';
	$< == 0 || die "delete-domain.pl must be run as root";
	}
@OLDARGV = @ARGV;

&set_all_text_print();

# Parse command-line args
while(@ARGV > 0) {
	local $a = shift(@ARGV);
	if ($a eq "--domain") {
		push(@domains, shift(@ARGV));
		}
	elsif ($a eq "--user") {
		push(@users, shift(@ARGV));
		}
	elsif ($a eq "--only") {
		$only = 1;
		}
	elsif ($a eq "--pre-command") {
		$precommand = shift(@ARGV);
		}
	elsif ($a eq "--post-command") {
		$postcommand = shift(@ARGV);
		}
	else {
		&usage("Unknown option $a");
		}
	}

# Find the domains, minus any sub-domains of already selected parents
@domains || @users || usage();
@doms = &get_domains_by_names_users(\@domains, \@users, \&usage);
foreach $d (@doms) {
	$idmap{$d->{'id'}} = $d;
	}
@doms = grep { !$_->{'parent'} || !$idmap{$_->{'parent'}} } @doms;

# Kill them
$config{'pre_command'} = $precommand if ($precommand);
$config{'post_command'} = $postcommand if ($postcommand);
foreach $d (@doms) {
	print "Deleting virtual server $d->{'dom'} ..\n";
	&$indent_print();
	$err = &delete_virtual_server($d, $only);
	&$outdent_print();
	if ($err) {
		print "$err\n";
		exit 1;
		}
	print ".. deleted\n\n";
	}
&virtualmin_api_log(\@OLDARGV, $doms[0]);

sub usage
{
print $_[0],"\n\n" if ($_[0]);
print "Deletes an existing Virtualmin virtual server and all sub-servers,\n";
print "mailboxes and alias domains.\n";
print "\n";
print "usage: delete-domain.pl  [--domain domain.name]*\n";
print "                         [--user username]*\n";
print "                         [--only]\n";
exit(1);
}


