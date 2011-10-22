package Dancer::Plugin::Meta;

use strict;
use Dancer qw(:syntax);
use Dancer::Plugin;
use Dancer::Plugin::REST;
use XML::Simple;

prepare_serializer_for_format;

=head1 NAME

Dancer::Plugin::Meta - It tells you all about "it."

=head1 VERSION

Version 0.01

=cut

our $VERSION     = '0.01';
my  $OMIT_ROUTES = []; 

# Add syntactic sugar for omitting routes.
register 'ignore_resources' => sub {
    $Dancer::Plugin::Meta::OMIT_ROUTES = \@_;
};

# Add this plugin to Dancer
register_plugin;

get '/meta/resources.:format' => sub {
    my $format = param 'format';
	_serial_meta($format);
};

get '/meta/resources' => sub {
    _html_meta();
};

get '/meta/sitemap' => sub {
    _xml_sitemap
};

get '/meta/version.:format' => sub {
	return to_json {version => setting 'appversion'};
};

get '/meta/license.:format' => sub {
	return to_json {license => setting 'applicense'}
};

get '/meta/author.:format' => sub {
	return to_json {author => [
		{name => setting 'appauthor'},
		{email => setting 'appauthoremail'}
	]};
};

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Meta;

Yup, its that simple. Optionally you can omit routes:
    
    ignore_resources ('ignore/this/route', 'orthese/.*');

=head1 DESCRIPTION

Plugin module for the Dancer web framwork that automagically adds a few standard resources as well as all the existing app resources (aka routes) to the webapp in the 'meta' namespace.

Using the module is literally that simple... 'use' it and your app will inherit the meta resources.

The HTML site map list can be styled throught the CSS class 'sitemap'

Added additional functionality in 0.06 as follows: 

Firstly, fixed the route selector so the sitemap doesn't show the "or not" operator ('?'), any route defined with a ':variable' in the path or a pure regexp as thats just dirty.

More importantly, I came across the requirement to not have a few admin pages listed in the sitemap, so I've added the ability to tell the plugin to ignore certain routes via the sitemap_ignore keyword.

=cut

# The action handler for the automagic /sitemap route. Uses the list of URLs from _retreive_get_urls and outputs a basic HTML template to the browser using the standard layout if one is defined.
sub _html_meta {
    my @urls = _retreive_routes();

    my $content = qq[ <h2> Resources </h2>\n<ul class="sitemap">\n ];
    for my $url (@urls) {
        $content .= qq[ <li><a href="$url">$url</a></li>\n ];
    }
    $content .= qq[ </ul>\n ];

    return engine('template')->apply_layout($content);
};

sub _serial_meta {
    my ($format) = @_;
    
    my @urls = _retreive_routes();
    my @sitemap_urls;

    for my $url (@urls) {
        push @sitemap_urls, { resource => [ $url ] };
    }

    return {resources => \@sitemap_urls};
};

sub _xml_meta_orig {
    my @urls = _retreive_routes();
    my @sitemap_urls;

    # add the "loc" key to each url so XML::Simple creates <loc></loc> tags.
    for my $url (@urls) {
        push @sitemap_urls, { loc => [ $url ] };
    }

    # create a hash for XML::Simple to turn into XML.
    my %urlset = (
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
        url   => \@sitemap_urls
    );

    my $xs  = new XML::Simple( KeepRoot   => 1,
                               ForceArray => 0,
                               KeyAttr    => {urlset => 'xmlns'},
                               XMLDecl    => '<?xml version="1.0" encoding="UTF-8"?>' );
    my $xml = $xs->XMLout( { urlset => \%urlset } );

    content_type "text/xml";
    return $xml;
};

# Obtains the list of URLs from Dancers Route Registry.
sub _retreive_routes {
    my ($route, @urls);

    for my $app ( Dancer::App->applications ) {
        my $routes = $app->{registry}->{routes};
        
        # push the static get routes into an array.
        ROUTE:
        for my $route ( @{ $routes->{get} } ) {
            if (ref($route->{pattern}) !~ m/HASH/i) {
                
                # If the pattern is a true comprehensive regexp or the route
                # has a :variable element to it, then omit it.
                #next ROUTE if ($get_route->{pattern} =~ m/[()[\]|]|:\w/);
              
                # If there is a wildcard modifier, then drop it and have the 
                # full route.
                #$get_route->{pattern} =~ s/\?//g;

                # Other than that, its cool to be added.
                push @$Dancer::Plugin::Meta::OMIT_ROUTES, '/meta';
                push @$Dancer::Plugin::Meta::OMIT_ROUTES, '/meta.json';
                if ($route->{pattern} =~ /^\/(\w+)\.:format$/) {
					push @urls, {$1 => $route->{pattern}};
				}
				#push (@urls, $get_route->{pattern}) 
                #    if ! grep { $get_route->{pattern} =~ m/$_/i } 
                #              @$Dancer::Plugin::Meta::OMIT_ROUTES; 
            }
        }
    }

    return sort(@urls);
};


=head1 AUTHOR

Puneet Kishor C<< <punkish at eidesis.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-sitemap at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Meta>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Meta


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Meta>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Meta>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Meta>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Meta/>

=back


=head1 LICENSE AND COPYRIGHT

This program is released under a CC0 license waiver. No rights to this program are reserved by the author. You may do as you please with it. It would be nice if you acknowledge the author, but you are under no obligation to do so.

See http://creativecommons.org/licenses for more information.


=cut

1; # End of Dancer::Plugin::Meta
