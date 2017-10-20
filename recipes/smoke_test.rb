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
#       time and not compile time (when nova does not yet exist).
ruby_block 'smoke_test_for_barbican_secrets' do
  block do
    begin
      env = openstack_command_env(admin_user, admin_project, 'Default', 'Default')
      # Create a named barbican secret.
      openstack_command('barbican', 'secret store --name chef_test_secret', env)

      # Get URI for secret.
      # This does not work:
      # all_fields = openstack_command('barbican', 'secret list', env, {'name': 'chef_test_secret', 'format': 'value'})
      #   -> barbican --name chef_test_secret --format value secret list

      # openstack_command splits -c"Secret href" on whitespace into two
      # arguments, so we can't get just the column of interest
      all_fields = openstack_command('barbican', 'secret list --name chef_test_secret -fvalue', env)
      sec_uri = all_fields.split[0]

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
