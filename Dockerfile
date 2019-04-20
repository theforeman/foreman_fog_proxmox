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

FROM ruby:2.3.7
LABEL MAINTAINER="tristan.robert.44@gmail.com"
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libsystemd-dev libvirt-dev
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN mkdir /usr/local/foreman_fog_proxmox
WORKDIR /usr/local/foreman_fog_proxmox
ADD . /usr/local/foreman_fog_proxmox
WORKDIR /usr/local
RUN git clone https://github.com/fog/fog-proxmox.git
WORKDIR /usr/local
RUN git clone https://github.com/theforeman/foreman.git -b develop
WORKDIR /usr/local/foreman
RUN echo "gem 'foreman_fog_proxmox', :path => '/usr/local/foreman_fog_proxmox'\n" > /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN echo "gem 'fog-proxmox', :path => '/usr/local/fog-proxmox'\n" > /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN echo "gem 'simplecov'" >> /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN cp /usr/local/foreman/config/settings.yaml.example /usr/local/foreman/config/settings.yaml
RUN cp /usr/local/foreman/config/database.yml.example /usr/local/foreman/config/database.yml
RUN cp /usr/local/foreman/config/model.mappings.example /usr/local/foreman/config/model.mappings
RUN bundle install --jobs 20
RUN bundle exec bin/rake db:migrate
ENTRYPOINT ["bundle", "exec"]
CMD ["bin/rake", "test:foreman_fog_proxmox"]