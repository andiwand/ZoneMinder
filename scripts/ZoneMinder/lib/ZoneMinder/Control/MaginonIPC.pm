# ==========================================================================
#
# ZoneMinder Maginon IPC-* IP Control Protocol Module, $Date$, $Revision$
# Copyright (C) 2016 Andreas Stefl
# Modified version of the FI8908W module by Philip Coombes and Dave Harris.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# ==========================================================================
#
package ZoneMinder::Control::MaginonIPC;

use 5.006;
use strict;
use warnings;

require ZoneMinder::Base;
require ZoneMinder::Control;

our @ISA = qw(ZoneMinder::Control);

# ==========================================================================
#
# Maginon IPC IP Control Protocol
#
# ==========================================================================

use ZoneMinder::Logger qw(:all);
use ZoneMinder::Config qw(:all);

use Time::HiRes qw( usleep );

sub new
{
    my $class = shift;
    my $id = shift;
    my $self = ZoneMinder::Control->new( $id );
    bless( $self, $class );
    srand( time() );
    return $self;
}

our $AUTOLOAD;

sub AUTOLOAD
{
    my $self = shift;
    my $class = ref($self) || croak( "$self not object" );
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    if ( exists($self->{$name}) )
    {
        return( $self->{$name} );
    }
    Fatal( "Can't access $name member of object of class $class" );
}

sub open
{
    my $self = shift;

    $self->loadMonitor();

    use LWP::UserAgent;
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent( "ZoneMinder Control Agent/".ZoneMinder::Base::ZM_VERSION );

    $self->{state} = "open";
}

sub close
{ 
    my $self = shift;
    $self->{state} = "closed";
}

sub printMsg
{
    my $self = shift;
    my $msg = shift;
    my $msg_len = length($msg);

    Debug( $msg."[".$msg_len."]" );
}

sub sendCmd
{
    my $self = shift;
    my $cmd = shift;
    my $result = undef;
    printMsg( $cmd, "Tx" );

    # Control device needs to be of format user=xxx&pwd=yyy
    my $req = HTTP::Request->new( GET=>"http://".$self->{Monitor}->{ControlAddress}."/$cmd"."&".$self->{Monitor}->{ControlDevice});
    print ("Sending $req\n");
    my $res = $self->{ua}->request($req);

    if ( $res->is_success )
    {
        $result = !undef;
    }
    else
    {
        Error( "Error REALLY check failed:'".$res->status_line()."'" );
        Error ("Cmd:".$req);
    }

    return( $result );
}

sub reset
{
    my $self = shift;
    Debug( "Camera Reset" );
    $self->sendCmd( 'reboot.cgi?' );
}

#Up Arrow
sub moveConUp
{
    my $self = shift;
    Debug( "Move Up" );
    $self->sendCmd( 'decoder_control.cgi?command=0' );
}

#Down Arrow
sub moveConDown
{
    my $self = shift;
    Debug( "Move Down" );
    $self->sendCmd( 'decoder_control.cgi?command=2' );
}

#Left Arrow
sub moveConLeft
{
    my $self = shift;
    Debug( "Move Left" );
    $self->sendCmd( 'decoder_control.cgi?command=4' );
}

#Right Arrow
sub moveConRight
{
    my $self = shift;
    Debug( "Move Right" );
    $self->sendCmd( 'decoder_control.cgi?command=6' );
}

#Diagonally Up Right Arrow
sub moveConUpRight
{
    my $self = shift;
    Debug( "Move Diagonally Up Right" );
    $self->sendCmd( 'decoder_control.cgi?command=91' );
}

#Diagonally Down Right Arrow
sub moveConDownRight
{
    my $self = shift;
    Debug( "Move Diagonally Down Right" );
    $self->sendCmd( 'decoder_control.cgi?command=93' );
}

#Diagonally Up Left Arrow
sub moveConUpLeft
{
    my $self = shift;
    Debug( "Move Diagonally Up Left" );
    $self->sendCmd( 'decoder_control.cgi?command=90' );
}

#Diagonally Down Left Arrow
sub moveConDownLeft
{
    my $self = shift;
    Debug( "Move Diagonally Down Left" );
    $self->sendCmd( 'decoder_control.cgi?command=92' );
}

#Stop
sub moveStop
{
    my $self = shift;
    Debug( "Move Stop" );
    $self->sendCmd( 'decoder_control.cgi?command=1' );
}

#Move Camera to Home Position
sub presetHome
{
    my $self = shift;
    Debug( "Home Preset" );
    $self->sendCmd( 'decoder_control.cgi?command=25' );
}

sub autoStop
{
    my $self = shift;
    my $autostop = shift;
    if( $autostop )
    {
       Debug( "Auto Stop" );
       usleep( $autostop );
       $self->sendCmd( 'decoder_control.cgi?command=1' );
    }
}

#Set preset
sub presetSet
{
    my $self = shift;
    my $params = shift;
    my $preset = $self->getParam( $params, 'preset' );
    my $presetCmd = 30 + ($preset*2);
    Debug( "Set Preset $preset with cmd $presetCmd" );
    $self->sendCmd( 'decoder_control.cgi?command=$presetCmd' );
}

#Goto preset
sub presetGoto
{
    my $self = shift;
    my $params = shift;
    my $preset = $self->getParam( $params, 'preset' );
    my $presetCmd = 31 + ($preset*2);
    Debug( "Goto Preset $preset with cmd $presetCmd" );
    $self->sendCmd( 'decoder_control.cgi?command=$presetCmd' );
}

#Turn IR on
sub wake
{
    my $self = shift;
    Debug( "Wake - IR on" );
    $self->sendCmd( 'decoder_control.cgi?command=95' );
}

#Turn IR off
sub sleep
{
    my $self = shift;
    Debug( "Sleep - IR off" );
    $self->sendCmd( 'decoder_control.cgi?command=94' );
}

1;

__END__

=head1 NAME

ZoneMinder::Control::MaginonIPC - Maginon IPC-* camera control

=head1 DESCRIPTION

This module contains the implementation of the Maginon IPC-* IP camera
control protocol.

You need to set "user=xxx&pwd=yyy" in the ControlDevice field of the
control tab for that monitor.
Auto TimeOut should be 1. Don't set it too small, or the processe starts
crashing.

=head1 AUTHOR

Andreas Stefl

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016  Andreas Stefl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

