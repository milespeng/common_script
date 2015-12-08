#!/usr/bin/perl -w

use strict;
use Config::Tiny;

our ($section,$conf,$service_url,$service_name,$result,@result,$file_log,$reponse,$cmd,$value_expected,@section_tmp,@section);

open DATE,"date +%Y-%m-%d-%H:%M|" or die "can'n pipe from date:$!";
our $time_date=<DATE>;
chomp $time_date;

sub readConf(){
	our $conf = Config::Tiny->read("/home/aspect/tools/script/Monitor3rdService.ini") || die "monitor\_service.ini, ERROR:$!\n";

	if($service_name =~ /\Aall\z/){
		@section_tmp = sort keys %{$conf};
		foreach (@section_tmp){
			push (@section,"$_");
		}
	}else{
		@section = split(/,/,$service_name);
	}
}

sub url_request(){
	my $section = shift;
	$cmd = "/usr/bin/curl -I $service_url";
#	print "\$cmd=$cmd\n";
	@result = `/usr/bin/curl -I $service_url`;
	sleep 2;
	foreach(@result){
		if($_ =~ /HTTP/){
			if($_ =~ /$value_expected/){
				`echo "$time_date [SUCCESS] $section request success" >> $file_log`;
			}else{
				chomp($_);
				`echo "$time_date [ERROR] $section $_" >> $file_log`;
			}
		}
	}
}

sub help(){
        print "############ Help ############\n";
        print "Usage: ./Monitor3rdService.pl {service_name}\n";
        print "eg.: ./Monitor3rdService.pl agls,poc,qiniu\n";
        print "eg.: ./Monitor3rdService.pl agls,poc\n";
        print "eg.: ./Monitor3rdService.pl qiniu\n";
        print "##############################\n";
}

################################### Main Program #################################
$service_name = $ARGV[0];
if (scalar(@ARGV) != 1){
        &help();
        exit 1;
}

&readConf();
foreach $section (@section){
	$service_url = $conf->{$section}->{service_url};
	$value_expected = $conf->{$section}->{value_expected};
	$file_log = "/home/aspect/tools/logs/Monitor3rdService.log";

	&url_request($section);
}
