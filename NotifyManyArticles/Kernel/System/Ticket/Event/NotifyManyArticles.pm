# --
# Kernel/System/Ticket/Event/NotifyManyArticles.pm - notify many articles event module
# Copyright (C) 2016 tuxwerk OHG, http://www.tuxwerk.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::NotifyManyArticles;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::User',
    'Kernel::System::Group',
    'Kernel::Config',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check needed stuff
    for (qw(Data Event Config)) {
        if ( !$Param{$_} ) {
            $LogObject->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }
    for (qw(TicketID)) {
        if ( !$Param{Data}->{$_} ) {
            $LogObject->Log( Priority => 'error', Message => "Need $_ in Data!" );
            return;
        }
    }
    if ( $Param{Event} ne 'ArticleCreate' ) {
        return 1;
    }

    if ($ConfigObject->Get('NotifyManyArticles::Enabled') != 1) {
        return 1;
    }

    if (!$ConfigObject->Get('NotifyManyArticles::Group')) {
        $LogObject->Log( Priority => 'error', Message => "Need NotifyManyArticles::Group" );
        return;
    }

    my $GroupID = $GroupObject->GroupLookup(Group => $ConfigObject->Get('NotifyManyArticles::Group'));

    if (!$ConfigObject->Get('NotifyManyArticles::Count')) {
        $LogObject->Log( Priority => 'error', Message => "Need NotifyManyArticles::Count" );
        return;
    }

    my @AllArticles = $TicketObject->ArticleIndex( TicketID => $Param{Data}->{TicketID} );
    if ($#AllArticles == $ConfigObject->Get('NotifyManyArticles::Count')) {

        my @UserIDs = $GroupObject->GroupMemberList(
            GroupID => $GroupID,
            Type    => 'ro',
            Result  => 'ID',
            );

        $LogObject->Log(
            Priority => 'notice',
            Message => "Article count reached:".$#AllArticles.", sending many articles notification!",
            );

        my %NotifyUser;
        foreach my $UserID (@UserIDs) {
            $TicketObject->SendAgentNotification(
                Type => 'ManyArticles',
                RecipientID => $UserID,
                CustomerMessageParams => \%Param,
                TicketID => $Param{Data}->{TicketID},
                UserID => $Param{UserID},
                );
        }
    }
    return 1;
}

1;
