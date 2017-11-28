#
# Cookbook:: openstack-key-manager
# Attributes:: default
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

# Needed by openstack-ops-database for automatic DB creation
default['openstack']['common']['services']['key-manager'] = 'barbican'

default['openstack']['key-manager']['syslog']['use'] = false

# Versions for OpenStack release
# https://releases.openstack.org/teams/barbican.html
# Ocata:
# default['openstack-key-manager']['barbican_server_version'] = '4.0.0'
# Pike:
default['openstack-key-manager']['barbican_server_version'] = '5.0.0'

default['openstack']['key-manager']['service_role'] = 'service'

# ************** OpenStack Key Manager Endpoints ************************

# The OpenStack Key Manager (Barbican) endpoints
%w(public internal admin).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['key-manager']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['key-manager']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['key-manager']['path'] = ''
  default['openstack']['endpoints'][ep_type]['key-manager']['port'] = 9311
end

# Needed for haproxy
default['openstack']['bind_service']['all']['key-manager']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['key-manager']['port'] = 9311
