# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

=pod

---+ package Foswiki::Plugins::HttpsRedirectPlugin

To interact with Foswiki use ONLY the official API functions
in the Foswiki::Func module. Do not reference any functions or
variables elsewhere in Foswiki, as these are subject to change
without prior warning, and your plugin may suddenly stop
working.

For increased performance, all handlers except initPlugin are
disabled below. *To enable a handler* remove the leading DISABLE_ from
the function name. For efficiency and clarity, you should comment out or
delete the whole of handlers you don't use before you release your
plugin.

__NOTE:__ When developing a plugin it is important to remember that
Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See [[%SYSTEMWEB%.Plugins#FAILEDPLUGINS]] for error messages.

__NOTE:__ Defining deprecated handlers will cause the handlers to be 
listed in [[%SYSTEMWEB%.Plugins#FAILEDPLUGINS]]. See
[[%SYSTEMWEB%.Plugins#Handlig_deprecated_functions]]
for information on regarding deprecated handlers that are defined for
compatibility with older Foswiki versions.

__NOTE:__ When writing handlers, keep in mind that these may be invoked
on included topics. For example, if a plugin generates links to the current
topic, these need to be generated before the afterCommonTagsHandler is run,
as at that point in the rendering loop we have lost the information that we
the text had been included from another topic.

=cut

package Foswiki::Plugins::HttpsRedirectPlugin;

# Always use strict to enforce variable scoping
use strict;

require Foswiki::Func;       # The plugins API
require Foswiki::Plugins;    # For the API version

our $VERSION = '1.2';
our $RELEASE = '19 Mar 2016';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION = 'Redirect authenticated users to HTTPS url.';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use preferences
# stored in the plugin topic. 
our $NO_PREFS_IN_TOPIC = 1;

# Name of this Plugin, only used in this module
our $pluginName = 'HttpsRedirectPlugin';

our $debug = 0;

=pod

---++ initPlugin($topic, $web, $user, $installWeb) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin is installed in

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 1.026 ) {
        Foswiki::Func::writeWarning(
            "Version mismatch between $pluginName and Plugins.pm");
        return 0;
    }

    # Example code of how to get a preference value, register a variable handler
    # and register a RESTHandler. (remove code you do not need)

    # Set plugin preferences in LocalSite.cfg, like this:
    # $Foswiki::cfg{Plugins}{HttpsRedirectPlugin}{ExampleSetting} = 1;
    # Always provide a default in case the setting is not defined in
    # LocalSite.cfg. See %SYSTEMWEB%.Plugins for help in adding your plugin
    # configuration to the =configure= interface.
    $debug = $Foswiki::cfg{Plugins}{HttpsRedirectPlugin}{Debug} || 0;

    if (Foswiki::Func::isGuest) {

        #If we are guest, force HTTPS on login
        if ( Foswiki::Func::getContext()
            ->{'login'} )    #If we are on the login script
        {

            #Build up our URL
            my $query = Foswiki::Func::getCgiQuery();
            my $url   = $query->url() . $query->path_info();
            if ( $query->query_string() ) {
                $url .= '?' . $query->query_string();
            }

            unless ( $url =~ /^https/ )    #Unless we are already using HTTPS
            {

                #Redirect to HTTPS URL and quite
                $url =~ s/^http/https/;
                Foswiki::Func::writeDebug("HTTPS redirect to: $url")
                  if ($debug);
                Foswiki::Func::redirectCgiQuery( $query, $url );

                #$Foswiki::Plugins::SESSION->finish();
                #exit(0);
            }
        }

    }
    else {

        #If the user is no guest always force HTTPS

        #Get our URL
        my $query = Foswiki::Func::getCgiQuery();
        my $url   = $query->url() . $query->path_info();
        if ( $query->query_string() ) {
            $url .= '?' . $query->query_string();
        }

        #Unless we are already using HTTPS, or running from CLI
        unless ( $url =~ /^https/
            or Foswiki::Func::getContext()->{'command_line'} )
        {

            #Redirect to HTTPS URL and quite
            $url =~ s/^http/https/;
            Foswiki::Func::writeDebug("HTTPS redirect to: $url") if ($debug);
            Foswiki::Func::redirectCgiQuery( $query, $url );

            #$Foswiki::Plugins::SESSION->finish();
            #exit(0);
        }
    }


    # Plugin correctly initialized
    return 1;
}

1;
