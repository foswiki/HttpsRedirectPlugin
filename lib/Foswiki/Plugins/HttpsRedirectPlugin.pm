# See bottom of file for notices

=pod

---+ package Foswiki::Plugins::HttpsRedirectPlugin

Intercept any http: requests that should be done over https
and redirect the requests to an https: URL
   * Any request to login
   * Requests to any script in the ={AuthScripts}= list
   * Any request that triggers a forceAuthentication event.

=cut

package Foswiki::Plugins::HttpsRedirectPlugin;

use strict;
use warnings;

use Foswiki::Func;       # The plugins API
use Foswiki::Plugins;    # For the API version

our $VERSION = '1.3';
our $RELEASE = '26 Mar 2017';

our $SHORTDESCRIPTION  = 'Redirect authenticated users to HTTPS url.';
our $NO_PREFS_IN_TOPIC = 1;

# Name of this Plugin, only used in this module
our $pluginName = 'HttpsRedirectPlugin';

our $debug = 0;

=pod

---++ earlyInitPlugin

Determines if TemplateLogin is in use.  If it is, enable a hook that
monkey-patches TemplateLogin::forceAuthentication. This hook will force
a redirect to https if any page is accessed that would require authentication.

=cut

sub earlyInitPlugin {
    return if !$Foswiki::cfg{Plugins}{HttpsRedirectPlugin}{Enabled};
    return undef
      unless (
        $Foswiki::cfg{LoginManager} eq 'Foswiki::LoginManager::TemplateLogin' );
    require Foswiki::Plugins::HttpsRedirectPlugin::CoreHooks;
    Foswiki::Plugins::HttpsRedirectPlugin::CoreHooks::hook();
    return undef;
}

=pod

---++ initPlugin($topic, $web, $user, $installWeb) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin is installed in

Redirects requests to https:
   * Any request to login
   * Requests to any ={AuthScripts}=
   * Any authenticated requests.

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 1.026 ) {
        Foswiki::Func::writeWarning(
            "Version mismatch between $pluginName and Plugins.pm");
        return 0;
    }

    $debug = $Foswiki::cfg{Plugins}{HttpsRedirectPlugin}{Debug} || 0;

    my $query = Foswiki::Func::getCgiQuery();

    return 1 if $query->secure();    # Nothing needed if already secure
    return 1
      if Foswiki::Func::getContext()->{'command_line'};    #Not needed for CLI

    if (Foswiki::Func::isGuest) {

        my $actionRegex =
          '\b' . Foswiki::Func::getRequestObject()->action() . '\b';

#If we are guest, force HTTPS on login, or any script that requires authentication.
        if (
            Foswiki::Func::getContext()
            ->{'login'}    #If we are on the login script
            || $Foswiki::cfg{AuthScripts} =~ m/$actionRegex/
          )
        {
            _redirectRequest($query);
        }
    }
    else {
        # Force redirect on all requests
        _redirectRequest($query);

    }

    # Plugin correctly initialized
    return 1;
}

=pod
---++ Private _redirectRequest($query)

Convert the URL to https: and redirect.

=cut

sub _redirectRequest {
    my $query = shift;

    #Get our URL
    my $url = $query->url() . $query->path_info();
    if ( $query->query_string() ) {
        $url .= '?' . $query->query_string();
    }

    #Redirect to HTTPS URL
    $url =~ s/^http/https/;
    $url = Foswiki::decode_utf8($url) if $Foswiki::UNICODE;
    Foswiki::Func::writeDebug("HTTPS redirect to: $url") if ($debug);
    Foswiki::Func::redirectCgiQuery( $query, $url );
}

1;
__END__

Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights may apply to some or all of the code in this
file as follows:

Copyright (C) 2013 Modell Aachen GmbH, http://modell-aachen.de
Author: Jan Krueger

Copyright (C) 1999-2007 Peter Thoeny, peter@thoeny.org
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details, published at
http://www.gnu.org/copyleft/gpl.html

