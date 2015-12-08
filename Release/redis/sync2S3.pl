#!/usr/bin/perl -w
#use strict;
our $project = $ARGV[0];
our $period = $ARGV[1];

our $backupPath="/srv/redisbackup";
our $expire4hour=24; #unit: 24 hours
our $expire4day=7;    #unit: 7 days

sub cp2Backup(){
    my $time;
    my $name;
    my @files=glob("/srv/redisdump/*");
    if ($period=~/hourly/i){
        $time = `date +%Y-%m-%d-%H-%M`;
    }elsif($period=~/daily/i){
        $time = `date +%Y-%m-%d`;
    }
    chomp($time);
    foreach(@files){
        print "file:$_\n";
        #if($_=~/(appendonly-.*)\.aof/i){
        #    $name=$1;
        #    system("cp -f $_ $backupPath/$period/$name-$time.aof");
        #    next;            
        #}
		system("mkdir -p $backupPath/$period") unless (-e "$backupPath/$period");
        if ($_=~/(dump-.*)\.rdb/i){
            $name=$1;
            system("cp -f $_ $backupPath/$period/$name-$time.rdb");
            next;
        }
    }
}
sub delFiles(){
    my @files = glob("$backupPath/$period/*");
    my $expire;
    if ($period=~/hourly/i){
        $expire = $expire4hour*60*60
    }elsif($period=~/daily/i){
        $expire = $expire4day*24*60*60 
    }
    foreach(@files){
        if(time()-(stat($_))[9]>$expire){
            print "Delete file $_\n";
            unlink($_);
        }
    }
}


################################ Main Program ####################

cp2Backup();
delFiles();
system("s3cmd --delete-removed sync $backupPath/$period/ s3://aspectgaming-databackup/redis/$project/$period/");   



