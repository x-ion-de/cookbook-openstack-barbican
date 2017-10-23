#
# Cookbook:: openstack-key-manager
# Recipe:: barbican-server
#
# Copyright 2017, x-ion GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ::Chef::Recipe
  include ::Openstack # address_for, get_password
end

db_user = node['openstack']['db']['key-manager']['username']
db_pass = get_password('db', 'barbican')
#------------------------------------------------------------------------------
# Install barbican
apt_update ''

package 'barbican-api'
package 'barbican-worker'
package 'barbican-keystone-listener'
#------------------------------------------------------------------------------
# barbican uses DEFAULT/sql_connection instead of database/connection
node.default['openstack']['key-manager']['conf_secrets']
.[]('DEFAULT')['sql_connection'] =
  db_uri('key-manager', db_user, db_pass)

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['key-manager']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'key-manager'
end

node.default['openstack']['key-manager']['conf_secrets']
.[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-key-manager'

identity_endpoint = public_endpoint 'identity'

auth_url = auth_uri_transform identity_endpoint.to_s, node['openstack']['api']['auth']['version']

node.default['openstack']['key-manager']['conf'].tap do |conf|
  conf['keystone_authtoken']['auth_url'] = auth_url
end

#------------------------------------------------------------------------------
# Config file

barbican_conf = merge_config_options 'key-manager'

template '/etc/barbican/barbican.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  mode 00644
  variables(
    service_config: barbican_conf
  )
end

service 'barbican-worker' do
  # supports status: true, restart: true
  action [:enable, :start]
end

service 'barbican-keystone-listener' do
  # supports status: true, restart: true
  action [:enable, :start]
end
#------------------------------------------------------------------------------
