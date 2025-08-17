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
