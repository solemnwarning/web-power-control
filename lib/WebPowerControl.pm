use strict;
use warnings;

package WebPowerControl;

use Dancer2;
use Time::HiRes;

use WebPowerControl::InputPin;
use WebPowerControl::OutputPin;
use WebPowerControl::Watcher;

my $power_button_pin;
my $reset_button_pin;
my $power_status_pin;

my $power_status_watcher;
my $last_status;

my @events;

get "/" => sub {
	template 'index' => {
		name => config->{"system-name"}
	};
};

post "/power-on" => sub
{
	process_watcher_events();
	
	if($power_status_pin->read())
	{
		status 409;
		return "The system is already powered on";
	}
	else{
		$power_button_pin->write(1);
		Time::HiRes::sleep(config->{"power-button-soft-time"});
		$power_button_pin->write(0);
		
		if($power_status_pin->read())
		{
			$last_status = 1; # Avoid duplicate "System powered on" message
			
			push(@events, [ (scalar @events), time(), "System powered on successfully" ]);
			return "The system is now powered on";
		}
		else{
			push(@events, [ (scalar @events), time(), "System failed to power on" ]);
			
			status 503;
			return "The system did not respond to the power button";
		}
	}
};

post "/soft-off" => sub
{
	process_watcher_events();
	
	if($power_status_pin->read())
	{
		$power_button_pin->write(1);
		Time::HiRes::sleep(config->{"power-button-soft-time"});
		$power_button_pin->write(0);
		
		push(@events, [ (scalar @events), time(), "System power off requested" ]);
		
		return "System power off requested";
	}
	else{
		status 409;
		return "The system is already powered off";
	}
};

post "/hard-off" => sub
{
	process_watcher_events();
	
	if($power_status_pin->read())
	{
		$power_button_pin->write(1);
		Time::HiRes::sleep(config->{"power-button-hard-time"});
		$power_button_pin->write(0);
		
		if($power_status_pin->read())
		{
			push(@events, [ (scalar @events), time(), "System failed to power off" ]);
			
			status 503;
			return "The system did not respond to the power button";
		}
		else{
			$last_status = 0; # Avoid duplicate "System powered off" message
			
			push(@events, [ (scalar @events), time(), "System powered off successfully" ]);
			
			return "The system is now powered off";
		}
	}
	else{
		status 409;
		return "System is already powered off";
	}
};

post "/reset" => sub
{
	process_watcher_events();
	
	if($power_status_pin->read())
	{
		$reset_button_pin->write(1);
		Time::HiRes::sleep(config->{"reset-button-time"});
		$reset_button_pin->write(0);
		
		push(@events, [ (scalar @events), time(), "System reset" ]);
		
		return "The reset button has been cycled";
	}
	else{
		status 409;
		return "The system is not powered on";
	}
};

post "/reset-hold" => sub
{
	process_watcher_events();
	
	if($power_status_pin->read())
	{
		$reset_button_pin->write(1);
		
		push(@events, [ (scalar @events), time(), "System entered reset" ]);
		
		return "The reset button is held down";
	}
	else{
		status 409;
		return "The system is not powered on";
	}
};

get "/status" => sub
{
	process_watcher_events();
	
	return encode_json({
		"power-on" => ($power_status_pin->read() ? JSON::true : JSON::false),
		"events" => \@events,
	});
};

sub process_watcher_events
{
	my @watcher_events = $power_status_watcher->read_events();
	
	foreach my $event(@watcher_events)
	{
		my ($timestamp, $on) = @$event;
		
		if(!$on ne !$last_status)
		{
			push(@events, [ (scalar @events), $timestamp, ($on ? "System powered on" : "System powered off") ]);
			$last_status = $on;
		}
	}
}

# Set up GPIO pins with correct mode and initial state.

$power_button_pin = WebPowerControl::OutputPin->new(config, "power-button-pin", "power-button-active");
$power_button_pin->write(0);

$reset_button_pin = WebPowerControl::OutputPin->new(config, "reset-button-pin", "reset-button-active");
$reset_button_pin->write(0);

$power_status_pin = WebPowerControl::InputPin->new(config, "power-status-pin", "power-status-active");

# I want to poll the power status pin between requests so that we can log *WHEN* the system powers
# on/off, but I can't figure out a way to get a periodic timer to fire under Dancer, so here we
# fork a new process which will poll the pin and write the status/timestamp to a pipe whenever it
# toggles so we can pick it up and add it to the event log on the next request.
#
# NOTE: This creates a new process which inherits some bits of Plackup state and ALSO shares the
# handle for GPIO access, both of which are probably UB however it seems to work well enough for
# my purposes...

$power_status_watcher = WebPowerControl::Watcher->new($power_status_pin);
$last_status = $power_status_pin->read();

true;
