use strict;
use warnings;

package WebPowerControl::InputPin;

use RPi::WiringPi;
use RPi::Const qw(:all);

sub new
{
	my ($class, $config, $pin_key, $active_key) = @_;
	
	my $self = bless({}, $class);
	
	if($config->{$active_key} eq "high")
	{
		$self->{active_state} = 1;
	}
	elsif($config->{$active_key} eq "low")
	{
		$self->{active_state} = 0;
	}
	else{
		die "Invalid '$active_key' specified in configuration (must be 'high' or 'low')\n";
	}

	$self->{pin} = RPi::WiringPi->new()->pin($config->{$pin_key});
	$self->{pin}->mode(INPUT);
	
	if($self->{active_state})
	{
		$self->{pin}->pull(1); # PUD_DOWN
	}
	else{
		$self->{pin}->pull(2); # PUD_UP
	}
	
	return $self;
}

sub read
{
	my ($self) = @_;
	
	return !($self->{pin}->read()) eq !($self->{active_state});
}

1;
