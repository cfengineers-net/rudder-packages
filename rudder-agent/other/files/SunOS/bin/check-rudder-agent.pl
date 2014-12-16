: # *-*-perl-*-*
eval 'exec perl -w -S $0 ${1+"$@"}'
        if 0;

#####################################################################################
# Copyright 2013 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################
use strict;
use POSIX;

# Ensure our PATH includes Rudder's bin dir (for uuidgen on AIX in particular)
$ENV{PATH} = "/opt/rudder/bin/:$ENV{PATH}";

# Variables
my $BACKUP_DIR = "/var/backups/rudder/";
my $OS_FAMILY = (uname())[0];
my $CFENGINE_DB_EXT = "lmdb";

my $CP_A = "";
my $PS_OPTIONS = "";
if($OS_FAMILY eq "AIX"){
  $CP_A = "cp -hpPr";
  $PS_OPTIONS = "-ef";
}elsif($OS_FAMILY eq "SunOS"){
	$PS_OPTIONS="-ef";
	if(-x "/usr/bin/zonename"){
		my $zonename = `/usr/bin/zonename`;
		chomp($zonename);
		if($zonename eq "global"){
			$PS_OPTIONS="-f -z global"
		}	
	}
  $CP_A="cp -rp"
}elsif($OS_FAMILY eq "Linux"){
  $CP_A = "cp -a";
  $PS_OPTIONS = "-efww";
}else{
	print "ERROR: Unsupported OS $OS_FAMILY\n";
	exit(1);
}

# Default variables for CFEngine binaries and disable files
my $CFE_DIR = "/var/rudder/cfengine-community";
my $CFE_BIN_DIR = "${CFE_DIR}/bin";
my $CFE_DISABLE_FILE = "/opt/rudder/etc/disable-agent";

my $LAST_UPDATE_FILE="${CFE_DIR}/last_successful_inputs_update";

my $UUID_FILE = "/opt/rudder/etc/uuid.hive";

# Ensure script is executed by root

if(getuid() != 0) { 
	print "You must be root\n"; 
	exit(0);
}

# Launch each check with a certain order

check_and_fix_rudder_uuid();
check_and_fix_cfengine_processes();
check_and_fix_cf_lock();

# The following files are not present on AIX systems
if(${OS_FAMILY} eq "AIX") {
  check_and_fix_specific_rudder_agent_file("/etc/init.d/rudder-agent", "init");
  check_and_fix_specific_rudder_agent_file("/etc/default/rudder-agent", "default");
  check_and_fix_specific_rudder_agent_file("/etc/cron.d/rudder-agent", "cron");
}

sub clean_cf_lock_files {
	my $path = "${CFE_DIR}/state/cf_lock.${CFENGINE_DB_EXT}";
	foreach my $ext (("",".lock")) {
		if(-f "${path}${ext}") {
			unlink("${path}${ext}");
		}
	}
}

sub check_and_fix_cfengine_processes {

  # Detect the correct ps tool to use
  # Supported tools are ps, vzps, and the rudder supplied vzps.py
  my $PS = "ps";
  my $VZPS = "/bin/vzps";
  my $RUDDERPS = "/opt/rudder/bin/vzps.py";

  # Detect if we are a VZ host
  if(-e "/proc/bc/0") {
    if(-e ${VZPS}) { 
      $PS = "${VZPS} -E 0";
    }else{
      $PS="${RUDDERPS} -E 0";
		}
	}

  # If there are more than on cf-execd process, we must kill them
  # A standard kill won't kill them, so the -9 is necessary to make sure they are stopped
  # They will be restarted by the next check, if the disable file is not set
  # List the cf-execd processes running (without the path, they can be run manually)
	my @CF_EXECD_RUNNING = ();
	open(PS,"${PS} ${PS_OPTIONS} |") or die "$!\n";
	while(<PS>){
		if(/cf-execd/){
			push(@CF_EXECD_RUNNING,$_);
		}
	}
	close(PS);

	if(scalar @CF_EXECD_RUNNING > 1){
    print "WARNING: Too many instance of CFEngine cf-execd processes running. Killing them...";
		foreach(@CF_EXECD_RUNNING){
			my @PS_LINE = split(/\s+/,$_);
			kill('KILL',$PS_LINE[1]);
		}
    print " Done\n";
	}

	my @CF_PROCESS_RUNNING = ();
	open(PS,"${PS} ${PS_OPTIONS} |") or die "$!\n";
	while(<PS>){
		if(/cf-execd|cf-agent/){
			push(@CF_PROCESS_RUNNING, $_);
		}
	}
	close(PS);

	if(! -e ${CFE_DISABLE_FILE} && scalar @CF_PROCESS_RUNNING == 0 && -f "${CFE_DIR}/policy_server.dat"){
		print "WARNING: No disable file detected and no CFEngine process neither. Relaunching CFEngine processes...";
		system("${CFE_BIN_DIR}/cf-agent -f failsafe.cf >/dev/null 2>&1");
		system("${CFE_BIN_DIR}/cf-agent >/dev/null 2>&1");
    print " Done\n";
	}

	my $RUN_INTERVAL=5;
	if(-f "$CFE_DIR/inputs/run_interval"){
		open(F, "$CFE_DIR/inputs/run_interval") or die "$!\n";
		while(<F>){
			chomp;
			if(/^\d+$/){
				$RUN_INTERVAL = $_;
			}
		}
		close(F);
	}
  my $CHECK_INTERVAL = ${RUN_INTERVAL} * 2;
  if(! -e ${LAST_UPDATE_FILE} || -e ${CFE_DISABLE_FILE}) {
    # Either the file ${LAST_UPDATE_FILE} is not yet present, and this node is
    # probably not accepted yet, either the file ${CFE_DISABLE_FILE} is present, so
    # the agent won't update the ${LAST_UPDATE_FILE}.
    # In both case, do nothing
	}else{
		my $mtime = (stat("${LAST_UPDATE_FILE}"))[9];
		if($mtime <= (time() - 60 * $CHECK_INTERVAL)){
			print "WARNING: The file ${LAST_UPDATE_FILE} is older than ${CHECK_INTERVAL} minutes, the agent is probably stuck. Purging the CFEngine lock database...";
			clean_cf_lock_files();
			print " Done\n";
		}
	}
  if( scalar @CF_PROCESS_RUNNING > 8){
    print "WARNING: Too many instance of CFEngine processes running. Killing them, and purging the CFEngine lock database...";
		foreach(@CF_PROCESS_RUNNING){
			my @PS_LINE = split(/\s+/,$_);
			kill('KILL',$PS_LINE[1]);
		}
    if(${OS_FAMILY} eq "AIX") {
			system("/etc/init.d/rudder-agent forcestop > /dev/null 2>&1");
		}
		clean_cf_lock_files();
		print " Done\n";
	}
}


# Check the size of the cf_lock file
sub check_and_fix_cf_lock {
  my $MAX_CF_LOCK_SIZE=10485760;
  if(-e "${CFE_DIR}/state/cf_lock.${CFENGINE_DB_EXT}"){
		my $CF_LOCK_SIZE = (stat("${CFE_DIR}/state/cf_lock.${CFENGINE_DB_EXT}"))[7];
    if(${CF_LOCK_SIZE} >= ${MAX_CF_LOCK_SIZE}){
      print "WARNING: The file ${CFE_DIR}/state/cf_lock.${CFENGINE_DB_EXT} is too big (${CF_LOCK_SIZE} bytes), purging it...";
      clean_cf_lock_files();
      print " Done\n";
		}
	}
}

sub check_and_fix_rudder_uuid {

	# Default variable about UUID backup
	my $LATEST_BACKUPED_UUID="";
	# Generate a UUID if we don't have one yet
	if(! -e ${UUID_FILE}){
		if(-d ${BACKUP_DIR}){
			my @UUID_FILES = ();
			open(LS,"ls -1tr ${BACKUP_DIR}uuid-*.hive |");
			@UUID_FILES = <LS>;	
			chomp(@UUID_FILES);
			close(LS);
			my $LATEST_BACKUPED_UUID = $UUID_FILES[$#UUID_FILES];
		}
		if(${LATEST_BACKUPED_UUID} =~/\S+/){
			print "WARNING: The UUID of the node does not exist. The lastest backup (${LATEST_BACKUPED_UUID}) will be recovered...";
			system("${CP_A} ${LATEST_BACKUPED_UUID} ${UUID_FILE} >/dev/null 2>&1");
			print " Done\n";
		}else{
			print "WARNING: The UUID of the node does not exist and no backup exist. A new one will be generated...";
			system("uuidgen > ${UUID_FILE}");
			print " Done\n";
		}
	} else {
		open(F,${UUID_FILE}) or die "$!\n";	
		my @UUID_FILE_LINES = <F>; 
		chomp(@UUID_FILE_LINES);
		close(F);
		my $CHECK_UUID = $UUID_FILE_LINES[0];
		if($CHECK_UUID !~ /^([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}|root)$/){
			print "INFO: Creating a new UUID for Rudder as the existing one is invalid...";
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
			my $date = ($year + 1900)."".($mon + 1)."$mday";
			system("mkdir -p ${BACKUP_DIR}");
			system("cp -f ${UUID_FILE} ${BACKUP_DIR}/uuid-$date.hive");
			system("uuidgen > ${UUID_FILE}");
			print " Done.\n";
		}
	}
}

sub check_and_fix_specific_rudder_agent_file {

	my $FILE_TO_RESTORE = shift; 
	my $FILE_TYPE = shift;
	my $LATEST_BACKUPED_FILES="";

	if(! -e ${FILE_TO_RESTORE}) {
		if(-d ${BACKUP_DIR}) {
			my @BACKEDUP_FILES = ();
			open(LS,"ls -1tr ${BACKUP_DIR}rudder-agent.${FILE_TYPE}-* |") or die "$!";
			@BACKEDUP_FILES = <LS>;	
			chomp(@BACKEDUP_FILES);
			close(LS);
			my $LATEST_BACKUPED_UUID = $BACKEDUP_FILES[$#BACKEDUP_FILES];
		}
		if(${LATEST_BACKUPED_FILES} =~/\S+/){
			print "WARNING: The file ${FILE_TO_RESTORE} does not exist. The lastest backup (${LATEST_BACKUPED_FILES}) will be recovered...";
			system("${CP_A} ${LATEST_BACKUPED_FILES} ${FILE_TO_RESTORE} >/dev/null 2>&1");
			print " Done\n";
		}else{
			print "ERROR: The file ${FILE_TO_RESTORE} does not exist and no backup exist. Please reinstall the rudder-agent package\n";
		}
	}
}

