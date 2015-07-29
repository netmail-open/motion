#!/usr/bin/perl

# run me with:
#     ./regex.pl
#
# configure me by creating a config:
#    curl -v -d "" localhost:30710/regex/
# and visiting the returned Location in a web browser
#
# post data to me through that same Location:
#    curl -v -d @regex-post.json localhost:30710/regex/...


use strict;
use warnings;
use JSON;
use HTTP::Daemon;
use HTTP::Status;
use CGI::Simple;


our $CFG = "regex-config.json";
our $CONFIG = from_json(read_file($CFG) || "{}", {utf8 => 1});
our $ENDPOINT = "/regex/";
our $SAVEPATH = "/regex/save/";
our $MANIFEST = {
	"name" => "regex match",
	"description" => "checks a message against a configured regular expression",
	"requires" => [ ],
	"requests" => [ "subject", "body" ],
	"modifies" => [ "regex-match" ],
	"endpoint" => $ENDPOINT
};


# when creating a new configuration, build a unique 8-letter random string
sub new_config {
	my @chars = ("A".."Z", "a".."z");
	my $string;
	$string .= $chars[rand @chars] for 1..8;
	if(exists($main::CONFIG->{$string})) {
		return new_config();
	}
	return $string;
}

sub read_file {
	my ($file) = @_;
	open my $in, "<:encoding(UTF-8)", $file or return "";
	local $/ = undef;
	my $all = <$in>;
	close $in;
	return $all;
}

sub write_file {
	my ($file, $content) = @_;
	open my $out, ">:encoding(UTF-8)", $file or die "Could not write '$file' $!";
	print $out $content;
	close $out;
	return;
}


# start up an HTTP daemon
my $SERVER = HTTP::Daemon->new(LocalPort => 30710) || die;
print "motion service 'regex' running at ", $SERVER->url, "\n";
while(my $c = $SERVER->accept) {
	while(my $r = $c->get_request) {
		if($r->uri->path eq "/") {
			# serve manifest
			my $response = HTTP::Response->new(200);
			$response->header("Content-Type" => "application/json");
			$response->content(to_json($MANIFEST, {utf8 => 1, pretty => 1}));
			$c->send_response($response);
		} elsif($r->uri->path eq $ENDPOINT) {
			# create new config and serve Location redirect
			if($r->method eq "POST") {
				my $newconf = new_config();
				$main::CONFIG->{$newconf} = {
					"regex" => ""
				};
				write_file($main::CFG, to_json($main::CONFIG,
											   {utf8 => 1, pretty => 1}));
				$c->send_redirect(join("", $ENDPOINT, $newconf));
			} else {
				$c->send_error(405);
			}
		} elsif($r->uri->path eq $SAVEPATH) {
			# handle config save
			my $cgi = CGI::Simple->new($r->content);
			my $conf = $cgi->param("config");
			my $regex = $cgi->param("regexp");
			if(exists($main::CONFIG->{$conf})) {
				$main::CONFIG->{$conf} = {
					"regex" => $regex
				};
				write_file($main::CFG, to_json($main::CONFIG,
											   {utf8 => 1, pretty => 1}));
				$c->send_redirect(join("", $ENDPOINT, $conf));
			} else {
				$c->send_error(403);
			}
		} else {
			# find config location
			my $conf = substr($r->uri->path, rindex($r->uri->path, "/") + 1);
			if(!exists($main::CONFIG->{$conf})) {
				$c->send_error(404);
				next;
			}
			my $regex = $main::CONFIG->{$conf}->{"regex"};
			if($r->method eq "POST") {
				# process message data on POST
				my $msg = from_json($r->content, {utf8 => 1});
				my $res = {
					"regex-match" => JSON::false
				};
				if($msg->{"subject"} =~ m/$regex/g) {
					$res->{"regex-match"} = JSON::true;
				}
				my $response = HTTP::Response->new(200);
				$response->header("Content-Type" => "application/json");
				$response->content(to_json($res, {utf8 => 1, pretty => 1}));
				$c->send_response($response);
			} elsif($r->method eq "GET") {
				# serve config form on GET
				my $form = read_file("regex-config.html");

				$form =~ s/\@CONFIG\@/$conf/g;
				$form =~ s/\@REGEX_VALUE\@/\Q$regex/g;

				my $response = HTTP::Response->new(200);
				$response->header("Content-Type" => "text/html");
				$response->content($form);
				$c->send_response($response);
			} else {
				$c->send_error(405);
			}
		}
	}
	$c->close;
	undef($c);
}
