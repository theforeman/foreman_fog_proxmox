FROM ruby:2.3.7
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libsystemd-dev libvirt-dev git curl
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN mkdir /foreman_proxmox
WORKDIR /foreman_proxmox
ADD . /foreman_proxmox
RUN mkdir /foreman
WORKDIR /foreman
RUN git clone https://github.com/theforeman/foreman.git
RUN echo "gem 'foreman_proxmox', :path => '/foreman_proxmox'" > /foreman/foreman/bundler.d/Gemfile.local.rb
WORKDIR /foreman/foreman
RUN cp /foreman/foreman/config/settings.yaml.example /foreman/foreman/config/settings.yaml
RUN cp /foreman/foreman/config/database.yml.example /foreman/foreman/config/database.yml
RUN bundle install --jobs 20
RUN npm install
ENTRYPOINT ["bundle", "exec"]
RUN bundle exec bin/rake db:migrate
RUN bundle exec bin/rake db:seed
ENV BIND=0.0.0.0
EXPOSE 3808
CMD ["foreman", "start"]