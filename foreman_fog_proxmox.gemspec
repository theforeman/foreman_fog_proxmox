# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('lib/foreman_fog_proxmox/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_fog_proxmox'
  s.version     = ForemanFogProxmox::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Tristan Robert', 'The Foreman Team']
  s.email       = ['tristan.robert.44@gmail.com', 'theforeman.rubygems@gmail.com']
  s.homepage    = 'https://github.com/theforeman/foreman_fog_proxmox'
  s.summary     = 'Foreman plugin that adds Proxmox VE compute resource using fog-proxmox'
  # also update locale/gemspec.rb
  s.description = 'Foreman plugin adds Proxmox VE compute resource using fog-proxmox. It is compatible with Foreman 1.22+'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'deface'
  s.add_dependency 'fog-proxmox', '~> 0.15'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'theforeman-rubocop', '~> 0.1'
end
