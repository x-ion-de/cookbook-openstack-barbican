#
# Cookbook Name:: openstack-key-manager
# Recipe:: smoke_test
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

class Chef::Resource::RubyBlock
  include ::Openstack
end

#------------------------------------------------------------------------------
# Install barbican client
apt_update ''

package 'python-barbicanclient'
#------------------------------------------------------------------------------
admin_user = node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']

# NOTE: This has to be done in a ruby_block so it gets executed at execution
#       time and not compile time (when barbican does not yet exist).
# Ignore FC014 (we don't want to extract this long ruby_block to a library)
ruby_block 'smoke_test_for_barbican_secrets' do # ~FC014
  block do
    begin
      env = openstack_command_env(admin_user, admin_project, 'Default', 'Default')
      # Create a named barbican secret.
      openstack_command('barbican', 'secret store --name chef_test_secret', env)

      # Get URI for secret.
      sec_uri = openstack_command('barbican', ['secret', 'list', '--name',
                                               'chef_test_secret', '-fvalue',
                                               '-cSecret href'], env)

      # Write payload.
      openstack_command('barbican', "secret update #{sec_uri} my_payload", env)

      # Check payload.
      payload = openstack_command('barbican', "secret get #{sec_uri} --payload -fvalue", env)
      payload.chomp!

      raise 'Failed to get payload back.' unless payload == 'my_payload'

      # Delete secret.
      openstack_command('barbican', "secret delete #{sec_uri}", env)
    end
  end
end
