# ForemanPluginTemplate

This repo is an example plugin which you can use as a starting point for developing
your own Foreman plugins

## Getting Started

First, clone this repo to a directory named for your new plugin

    git clone https://github.com/theforeman/foreman_plugin_template foreman_my_plugin

Now use the provided script to rewrite all the files in the plugin

    cd foreman_my_plugin
    ./rename.rb foreman_my_plugin

The script will also output the required Bundler line to add the plugin to Foreman.
Apply this change, and restart Foreman

Once working, update the README with appropriate information, and publish your plugin!

## Out of the box functionality

This example plugin comes with:

* A model and helper concern
* An inherited controller
* A route/view which displays the plugin name
* A widget for the Dashboard
* A plugin registration block adding permissions/roles/menu entry
* A functioning example rake task
* A functioning example test and factory
* Functioning internationalization support

These examples show how to add to Foreman in various ways.

### Further examples

The [How to create a plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Create_a_Plugin)
wiki page contains a lot of information on supported plugin extension points in
Foreman and how to use them from a plugin.

### i18n

From your Foreman checkout, run `rake plugin:gettext[foreman_plugin_example]` to
extract the latest strings, and then inside the plugin checkout run `make -C locale
tx-update` to pull and merge in the latest translations.  Do this regularly and
before each release.

Have your .pot file published in Foreman's Transifex project by contacting the
development team below.

[Translating](http://projects.theforeman.org/projects/foreman/wiki/Translating#Translating-for-developers)
has more information about writing code with i18n support.

## Getting help

The Foreman developers IRC channel and mailing list are the best places to get help:

* Freenode: #theforeman-dev
* Google Groups: foreman-dev@googlegroups.com

## Copyright

Copyright (c) 2014 Red Hat

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
