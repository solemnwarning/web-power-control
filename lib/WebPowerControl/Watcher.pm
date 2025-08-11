use strict;
use warnings;

package WebPowerControl::Watcher;

use IO::Select;
use POSIX qw(:signal_h);

use WebPowerControl::InputPin;

sub new
{
	my ($class, $pin) = @_;
	
	my $self = bless({}, $class);
	
	my ($rpipe, $wpipe);
	pipe($rpipe, $wpipe) or die "pipe: $!\n";
	
	binmode($rpipe);
	binmode($wpipe);
	
	$self->{pid} = fork();
	die "fork: $!\n" if($self->{pid} == -1);
	
	if($self->{pid} == 0)
	{
		$self->{run} = 1;
		local $SIG{TERM} = sub
		{
			$self->{run} = 0;
		};
		
		$rpipe = undef;
		$self->{wpipe} = $wpipe;
		$self->{pin} = $pin;
		
		$self->_run();
		
		exit;
	}
	else{
		$self->{rpipe} = $rpipe;
		return $self;
	}
}

sub DESTROY
{
	my ($self) = @_;
	
	if($self->{pid} > 0)
	{
		kill(SIGTERM, $self->{pid});
	}
}

sub _run
{
	my ($self) = @_;
	
	my $last_status = $self->{pin}->read();
	
	while($self->{run})
	{
		my $new_status = $self->{pin}->read();
		
		if(!$new_status ne !$last_status)
		{
			if((syswrite($self->{wpipe}, pack("qC", time(), ($new_status ? 1 : 0))) // -1) != 9)
			{
				die "syswrite: $!\n";
			}
			
			$last_status = $new_status;
		}
		
		sleep(1);
	}
}

sub read_events
{
	my ($self) = @_;
	
	my @events = ();
	
	MESSAGE: while(IO::Select->new($self->{rpipe})->can_read(0))
	{
		my ($buf, $len);
		
		while($len < 9)
		{
			my $i = sysread($self->{rpipe}, $buf, (9 - $len), $len);
			if($i)
			{
				$len += $i;
			}
			else{
				last MESSAGE;
			}
		}
		
		push(@events, [ unpack("qC", $buf) ]);
	}
	
	return @events;
}

1;
