name 'openstack-key-manager'
maintainer 'Roger Luethi'
maintainer_email 'r.luethi@x-ion.de'
license 'Apache 2.0'
description 'Installs/Configures OpenStack Barbican'
long_description 'Installs/Configures OpenStack Barbican'
version '0.1.0'
supports         'ubuntu'
chef_version '>= 12.1' if respond_to?(:chef_version)
issues_url       'https://github.com/x-ion-de/cookbook-openstack-key-manager/issues'
source_url       'https://github.com/x-ion-de/cookbook-openstack-key-manager.git'

depends 'docker', '>= 2.5.0'
depends 'openstack-common' # address_for, openstack_common_database
depends 'openstack-identity', '>= 14.0.0'
depends 'openstackclient'
depends 'apache2', '~> 3.2'
