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

To interact with TWiki use ONLY the official API functions
in the Foswiki::Func module. Do not reference any functions or
variables elsewhere in TWiki, as these are subject to change
without prior warning, and your plugin may suddenly stop
working.

For increased performance, all handlers except initPlugin are
disabled below. *To enable a handler* remove the leading DISABLE_ from
the function name. For efficiency and clarity, you should comment out or
delete the whole of handlers you don't use before you release your
plugin.

__NOTE:__ When developing a plugin it is important to remember that
TWiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See [[%SYSTEMWEB%.Plugins#FAILEDPLUGINS]] for error messages.

__NOTE:__ Defining deprecated handlers will cause the handlers to be 
listed in [[%SYSTEMWEB%.Plugins#FAILEDPLUGINS]]. See
[[%SYSTEMWEB%.Plugins#Handlig_deprecated_functions]]
for information on regarding deprecated handlers that are defined for
compatibility with older TWiki versions.

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

# $VERSION is referred to by TWiki, and is the only global variable that
# *must* exist in this package.
#use vars qw( $VERSION $RELEASE $SHORTDESCRIPTION $debug $pluginName $NO_PREFS_IN_TOPIC );

# This should always be $Rev$ so that TWiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
our $VERSION = '$Rev$ (2011-03-28)';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
our $RELEASE = '1.1';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION = 'Redirect authenticated users to HTTPS url.';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use preferences
# stored in the plugin topic. This default is required for compatibility with
# older plugins, but imposes a significant performance penalty, and
# is not recommended. Instead, use $Foswiki::cfg entries set in LocalSite.cfg, or
# if you want the users to be able to change settings, then use standard TWiki
# preferences that can be defined in your %USERSWEB%.SitePreferences and overridden
# at the web and topic level.
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

REQUIRED

Called to initialise the plugin. If everything is OK, should return
a non-zero value. On non-fatal failure, should write a message
using Foswiki::Func::writeWarning and return 0. In this case
%FAILEDPLUGINS% will indicate which plugins failed.

In the case of a catastrophic failure that will prevent the whole
installation from working safely, this handler may use 'die', which
will be trapped and reported in the browser.

You may also call =Foswiki::Func::registerTagHandler= here to register
a function to handle variables that have standard TWiki syntax - for example,
=%MYTAG{"my param" myarg="My Arg"}%. You can also override internal
TWiki variable handling functions this way, though this practice is unsupported
and highly dangerous!

__Note:__ Please align variables names with the Plugin name, e.g. if 
your Plugin is called FooBarPlugin, name variables FOOBAR and/or 
FOOBARSOMETHING. This avoids namespace issues.


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

    # register the _EXAMPLETAG function to handle %EXAMPLETAG{...}%
    # This will be called whenever %EXAMPLETAG% or %EXAMPLETAG{...}% is
    # seen in the topic text.
    #Foswiki::Func::registerTagHandler( 'EXAMPLETAG', \&_EXAMPLETAG );

    # Allow a sub to be called from the REST interface
    # using the provided alias
    #Foswiki::Func::registerRESTHandler('example', \&restExample);

    # Plugin correctly initialized
    return 1;
}

1;
