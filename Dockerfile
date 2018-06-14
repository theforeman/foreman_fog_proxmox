# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

FROM ruby:2.3.7
LABEL MAINTAINER="tristan.robert.44@gmail.com"
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libsystemd-dev libvirt-dev
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN mkdir /usr/local/foreman_proxmox
WORKDIR /usr/local/foreman_proxmox
ADD . /usr/local/foreman_proxmox
WORKDIR /usr/local
RUN git clone https://github.com/theforeman/foreman.git
WORKDIR /usr/local/foreman
RUN git checkout tags/1.17.1
RUN echo "gem 'foreman_proxmox', :path => '/usr/local/foreman_proxmox'\n" > /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN echo "gem 'fog-proxmox', :git => 'https://github.com/fog/fog-proxmox.git'\n" >> /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN echo "gem 'simplecov'" >> /usr/local/foreman/bundler.d/Gemfile.local.rb
RUN cp /usr/local/foreman/config/settings.yaml.example /usr/local/foreman/config/settings.yaml
RUN cp /usr/local/foreman/config/database.yml.example /usr/local/foreman/config/database.yml
RUN bundle install --jobs 20
ENTRYPOINT ["bundle", "exec"]
RUN bundle exec bin/rake db:migrate
CMD ["bin/rake", "test:foreman_proxmox"]