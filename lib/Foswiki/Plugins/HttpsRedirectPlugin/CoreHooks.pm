# See bottom of file for notices

package Foswiki::Plugins::HttpsRedirectPlugin::CoreHooks;

use strict;
use warnings;
use Assert;
use Foswiki::Plugins::HttpsRedirectPlugin;

my $hooked;
my $oldforceAuthentication;

sub hook {

    # Prevent nasties on FastCGI/mod_perl
    # If the hooks were applied twice, the $old... variables would end up
    # containing the hooks themselves and we'd get ourselves stuck in an
    # infinite loop...
    return if defined $hooked;

    # Overwrite the normal Foswiki functions for adding zones.
    # This is, sadly, necessary if we want to have the ability to
    # magically let through all zone code added directly by plugins
    # (e.g. JQueryPlugin's prefs object).

    $oldforceAuthentication =
      \&Foswiki::LoginManager::TemplateLogin::forceAuthentication;
    undef *Foswiki::LoginManager::TemplateLogin::forceAuthentication;
    *Foswiki::LoginManager::TemplateLogin::forceAuthentication =
      \&Foswiki::Plugins::HttpsRedirectPlugin::CoreHooks::forceAuthentication;

    $hooked = 1;
    return;
}

sub forceAuthentication {

    my $query = Foswiki::Func::getCgiQuery();

    # No need to redirect if already a secure request.
    return $oldforceAuthentication->(@_) if $query->secure();

    Foswiki::Plugins::HttpsRedirectPlugin::_redirectRequest($query);
}

1;
__DATA__

Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights may apply to some or all of the code in this
file as follows:

Copyright (C) 2013 Modell Aachen GmbH, http://modell-aachen.de
Author: Jan Krueger

Copyright (C) 1999-2007 Peter Thoeny, peter@thoeny.org
and TWiki Contributors. All Rights Reserved. TWiki Contributors
are listed in the AUTHORS file in the root of this distribution.
Based on parts of Ward Cunninghams original Wiki and JosWiki.
Copyright (C) 1998 Markus Peter - SPiN GmbH (warpi@spin.de)
Some changes by Dave Harris (drh@bhresearch.co.uk) incorporated

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
