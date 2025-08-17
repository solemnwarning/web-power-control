# WebPowerControl
# Copyright (C) 2025 Daniel Collins <solemnwarning@solemnwarning.net>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

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
