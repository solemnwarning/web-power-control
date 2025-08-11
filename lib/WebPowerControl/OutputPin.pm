use strict;
use warnings;

package WebPowerControl::OutputPin;

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
	$self->{pin}->mode(OUTPUT);
	
	return $self;
}

sub write
{
	my ($self, $enable) = @_;
	
	if($enable)
	{
		$self->{pin}->write($self->{active_state} ? HIGH : LOW);
	}
	else{
		$self->{pin}->write($self->{active_state} ? LOW : HIGH);
	}
}

1;
