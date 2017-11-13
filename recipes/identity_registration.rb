#
# Cookbook Name:: openstack-key-manager
# Recipe:: identity_registration
#
# Copyright 2017, x-ion
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

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

if node.chef_environment == '_default'
  execute 'add_controller_to_etc_hosts' do
    command "echo '#{node['openstack']['endpoints']['admin']['identity']['host']} controller' >> /etc/hosts"
    not_if 'grep controller /etc/hosts'
  end
end

identity_admin_endpoint = admin_endpoint 'identity'

auth_url = ::URI.decode identity_admin_endpoint.to_s

interfaces = {
  public: { url: public_endpoint('key-manager') },
  internal: { url: internal_endpoint('key-manager') },
  admin: { url: admin_endpoint('key-manager') },
}

admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', admin_user
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']

connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:  admin_domain,
}

service_user =
  node['openstack']['key-manager']['conf']['keystone_authtoken']['username']
service_pass = get_password 'service', 'openstack-key-manager'
service_project =
  node['openstack']['key-manager']['conf']['keystone_authtoken']['project_name']
service_domain_name =
  node['openstack']['key-manager']['conf']['keystone_authtoken']['user_domain_name']
service_role = node['openstack']['key-manager']['service_role']
region = node['openstack']['region']

# Register Key Manager Services
openstack_service 'barbican' do
  type 'key-manager'
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register NFV Orchestration Endpoints
  openstack_endpoint 'key-manager' do
    service_name 'barbican'
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Project
openstack_project service_project do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  project_name service_project
  password service_pass
  connection_params connection_params
end

# Grant Service role to Service User for Service Project
openstack_user service_user do
  role_name service_role
  project_name service_project
  connection_params connection_params
  action :grant_role
end

# Grant default domain to user with role of Service Project
openstack_user service_user do
  domain_name service_domain_name
  role_name service_role
  user_name service_user
  connection_params connection_params
  action :grant_domain
end
