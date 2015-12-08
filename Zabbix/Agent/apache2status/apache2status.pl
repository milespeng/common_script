#!/usr/bin/perl -w
#Created by william wu on Oct 15 2015
#Step1: Make sure to enable status module on Apache2
#Step2: Edit httpd.conf file on Apache2
# <Location /server-status>
# 	SetHandler server-status
# 	Order Deny,Allow
# 	Deny from all
# 	Allow from localhost
# </Location>
#Step3: Restart apache2 service

my $params = $ARGV[0];
my $host = "http://localhost";
my $cmd = 'curl -A "mozilla/4.0 (compatible; cURL 7.10.5-pre2; Linux 2.4.20)" -m 12 -s -L -k -b /tmp/bbapache_cookiejar.curl -c /tmp/bbapache_cookiejar.curl -H "Pragma: no-cache" -H "Cache-control: no-cache" -H "Connection: close" "'.$host.'/server-status?auto"';
my $server_status = qx($cmd);
my $result;
my($total_accesses,$total_kbytes,$cpuload,$uptime, $reqpersec,$bytespersec,$bytesperreq,$busyservers, $idleservers, $connstotal, $scoreboard);
#print $server_status;

if ($params =~/total_accesses|all/i){
	$total_accesses = $1 if ($server_status =~ /Total\ Accesses:\ ([\d|\.]+)/ig)||0;
	$result = $total_accesses;
}
if ($params =~/total_kbytes|all/i){
	$total_kbytes = $1 if ($server_status =~ /Total\ kBytes:\ ([\d|\.]+)/gi);
	$result = $total_kbytes;
}
if ($params =~/cpuload|all/i){
	$cpuload = $1 if ($server_status =~ /CPULoad:\ ([\d|\.]+)/gi);
	$result = $cpuload;
}
if ($params =~/uptime|all/i){
	$uptime = $1 if ($server_status =~ /Uptime:\ ([\d|\.]+)/gi);
	$result = $uptime;
}
if ($params =~/reqpersec|all/i){
	$reqpersec = $1 if ($server_status =~ /ReqPerSec:\ ([\d|\.]+)/gi);
	$result = $reqpersec;
}
if ($params =~/bytespersec|all/i){
	$bytespersec = $1 if ($server_status =~ /BytesPerSec:\ ([\d|\.]+)/gi);
	$result = $bytespersec;
}
if ($params =~/bytesperreq|all/i){
	$bytesperreq = $1 if ($server_status =~ /BytesPerReq:\ ([\d|\.]+)/gi);
	$result = $bytesperreq;
}
if ($params =~/busyservers|all/i){
	$busyservers = $1 if ($server_status =~ /BusyWorkers:\ ([\d|\.]+)/gi);
	$result = $busyservers;
}
if ($params =~/idleservers|all/i){
	$idleservers = $1 if ($server_status =~ /IdleWorkers:\ ([\d|\.]+)/gi);
	$result = $idleservers;
}
if ($params =~/connstotal|all/i){
	$connstotal = $1 if ($server_status =~ /ConnsTotal:\ ([\d|\.]+)/gi);
	$result = $connstotal;
}
if ($params =~/scoreboard|all/i){
	$scoreboard = $1 if ($server_status =~ /Scoreboard:\ ([A-Z_]+)/gi);
	$result = $scoreboard;
}

if ($params =~ /all/i){
	print "Total Accesses:$total_accesses Total kBytes:$total_kbytes CPULoad:$cpuload Uptime:$uptime ReqPerSec:$reqpersec BytesPerSec:$bytespersec BytesPerReq:$bytesperreq BusyWorkers:$busyservers IdleWorkers:$idleservers ConnsTotal:$connstotal\n";
}else{
	print "$result";
}
exit(0);

