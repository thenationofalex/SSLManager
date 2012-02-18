package SSLManager;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::CAPTCHA;
use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::Redirect;
use CGI::Carp qw(fatalsToBrowser);
use Crypt::OpenSSL::RSA;
use MIME::Lite;
use Rose::DBx::Object::Renderer;

__PACKAGE__->tt_config(
    TEMPLATE_OPTIONS => {
        ABSOLUTE => 1,
        RELATIVE => 1,
    },
);

sub setup {
    my $self = shift;

my $renderer = Rose::DBx::Object::Renderer->new(
    config => {
     db => {
     type     => 'Pg',
     name     => 'ssl',
     username => 'username',
     password => 'password',
     host     => 'localhost',
     tables_are_singular => 1,
     table_suffex => 'ssl',
     table_prefix => 'ssl',
     },
	 template => {
	    path => '/var/www/template',
     },
   },
load => 1
);

$self->run_modes(
    'create'  => 'create',
    'view'    => 'view',
     );
     $self->start_mode('create');
     $self->tt_include_path(['/var/www/template']);
}

#SSL Form
sub create {
    my $self = shift;

    my $form = Ssl::Ssl->render_as_form(
	template    => 'form.tt',
    output      => 1,
	title       => 'Generate SSL Key & CSR',
	order       => ['ssl_domain_name','ssl_country_code','ssl_state','ssl_locality','ssl_organization_name','ssl_organizational_unit','ssl_email'],
	fields => {
		ssl_domain_name  => { validate => '/^([a-zA-Z0-9\*]+(\.[a-zA-Z0-9]+)+.*)$/', message => 'Domain Name Invalid, Please ensure you don\'t have http:// or https:// in the URL.'},
	    ssl_country_code => { validate => '/^\w{2}$/', required => 1},
    	ssl_state        => { validate => '/^[a-zA-Z ]+$/', message=> 'Only Letters are allowed', required => 1},
    	ssl_locality     => { validate => '/^[a-zA-Z ]+$/', message=> 'Only Letters are allowed', required => 1},
    	ssl_organization_name => { required => 1},
    	ssl_organizational_unit => { required => 1},
	},
	controller_order => ['Create'],
	controllers => {
            'Create' => {
                 create => 1,
                     callback => sub {
                     my $object = shift;
                     if (ref $object) {
						my $ssl_key = Crypt::OpenSSL::RSA->generate_key(2048)->get_private_key_string();
						$object->ssl_key($ssl_key);
						$object->save();
						my $country_code = $object->ssl_country_code;
						my $state        = $object->ssl_state;
						my $locality     = $object->ssl_locality;
						my $org_name     = $object->ssl_organization_name;
						my $org_unit     = $object->ssl_organizational_unit;
						my $common_name  = $object->ssl_domain_name;
						my $email        = $object->ssl_email;
						my $key_filename = '/tmp/temporary_ssl_key-DELETEME';
						open my $key_fh,'>',$key_filename || die "Cant write key file $!\n";
						print $key_fh $ssl_key || die "Cant write to key file\n";
						close $key_fh || die "Cant close key file\n";
						my $csr = `openssl req -new -key $key_filename -nodes -subj '\/C=$country_code\/ST=$state\/L=$locality\/O=$org_name\/OU=$org_unit\/CN=$common_name\/emailAddress=$email'`;
						$object->ssl_csr($csr);
						$object->save();
						unlink $key_filename || die "Cant delete the temporary key file. FIX IMMEDIATELY\n";
						my $msg = MIME::Lite->new(
							From    => 'ssladmin@sitesuite.com.au',
							To      => 'ssladmin@sitesuite.com.au',
							Subject => 'SSL Key and CSR for ' . $common_name,
							Data    => 'Country Code: ' . $country_code . "\n" .
								'State: ' . $state . "\n" .
								'Locality: ' . $locality . "\n" .
								'Organization Name: ' . $org_name . "\n" .
								'Organizational Unit: ' . $org_unit . "\n" .
								'Common Name: ' . $common_name . "\n" .
								'Email: ' . $email . "\n\n" .
								$ssl_key . "\n" .
								$csr,
						);
						$msg->send('smtp','bill.sitesuite.net',Timeout=>60,Debug => 1) || die "Error Cant Send Email";
						return $self->redirect('/template/thank.html');
                    }
                 }
             }
	}
    );

    return $self->tt_process('index.tt', {
	my_form => $form->{output},
    });
    return $self;
}

#SSL Table
sub view {
    my $self = shift;

    my $table = Ssl::Ssl::Manager->render_as_table(
	template => 'table.tt',
	output   => 1,
	searchable => ['ssl_domain_name','ssl_organization_name'],
    );

    return $self->tt_process('view.tt', {
	my_table => $table->{output},
    });
}