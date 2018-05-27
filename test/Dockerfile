FROM ruby:2.3.7
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs git
RUN mkdir /foreman_proxmox
WORKDIR /foreman_proxmox
ADD . /foreman_proxmox
RUN mkdir /foreman
WORKDIR /foreman
RUN git clone https://github.com/theforeman/foreman.git
RUN echo "gem 'foreman_proxmox', :path => '/foreman_proxmox'" > /foreman/foreman/bundler.d/Gemfile.local.rb
WORKDIR /foreman/foreman
RUN bundle install --without libvirt postgresql
RUN npm install
RUN bundle exec bin/rake db:migrate
RUN bundle exec bin/rake db:seed
CMD bundle exec foreman start