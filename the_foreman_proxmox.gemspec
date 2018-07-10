
# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of TheForemanProxmox.

# TheForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# TheForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with TheForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('lib/the_foreman_proxmox/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'the_foreman_proxmox'
  s.version     = TheForemanProxmox::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Tristan Robert']
  s.email       = ['tristan.robert.44@gmail.com']
  s.homepage    = 'https://github.com/tristanrobert/foreman_proxmox'
  s.summary     = 'Foreman plugin that adds Proxmox VE compute resource using fog-proxmox'
  # also update locale/gemspec.rb
  s.description = 'Foreman plugin adds Proxmox VE compute resource using fog-proxmox. It is compatible with Foreman 1.17'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'fog-proxmox', '~> 0.4'
  s.add_development_dependency 'rdoc', '~> 6.0'
  s.add_development_dependency 'rubocop', '~> 0.58'
  s.add_development_dependency 'simplecov', '~> 0.16'
end
