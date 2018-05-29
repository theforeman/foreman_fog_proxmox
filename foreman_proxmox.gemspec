
# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of Fog::Proxmox.

# Fog::Proxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Fog::Proxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Fog::Proxmox. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../lib/foreman_proxmox/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'foreman_proxmox'
  s.version     = ForemanProxmox::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Tristan Robert']
  s.email       = ['tristan.robert.44@gmail.com']
  s.homepage    = 'https://github.com/tristanrobert/foreman-proxmox'
  s.summary     = "Foreman plugin to support Proxmox VE"
  # also update locale/gemspec.rb
  s.description = 'This library can be used as a plugin for `foreman    `.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
