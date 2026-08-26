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

require 'fog/proxmox/helpers/disk_helper'
require 'fog/proxmox/helpers/nic_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'
require 'fileutils'
require 'open3'
require 'tmpdir'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVMCloudinitHelper
  def parse_server_cloudinit(args)
    cloudinit_h = {}
    cloudinit = args['cloudinit']
    unless ['none'].include? cloudinit
      volid = args['volid']
      storage = args['storage']
      cloudinit_volid = volid if volid
      cloudinit_volid ||= "#{storage}:cloudinit" if storage
      controller = args['controller']
      device = args['device']
      id = "#{controller}#{device}" if controller && device
      cloudinit_h.store(:id, id.to_sym) if id
      cloudinit_h.store(:volid, cloudinit_volid) if cloudinit_volid
      cloudinit_h.store(:media, 'cdrom')
    end
    cloudinit_h
  end

  def create_cloudinit_iso(vm_name, configs)
    wd = create_temp_directory
    iso = File.join(wd, "#{vm_name.tr('.', '_')}_cloudinit.iso")
    files = []

    configs.each do |config|
      config_file = File.join(wd, config[0])
      File.write(config_file, config[1])
      files.append(config_file)
    end
    logger.debug("Generating cloud-init ISO at #{iso}")
    stdout, stderr, status = Open3.capture3(*generate_iso_command(iso, files))
    raise Foreman::Exception, N_("ISO build failed: #{stderr.presence || stdout}") unless status.success?

    yield iso
  ensure
    delete_temp_dir(wd) if wd && Dir.exist?(wd)
  end

  def generate_iso_command(iso_file, config_files)
    arguments = ["genisoimage", '-output', iso_file, '-volid', 'cidata', '-joliet', '-rock']
    arguments.concat(config_files)
    logger.debug("iso image generation args: #{arguments.join(' ')}")
    arguments
  end

  def create_temp_directory
    Dir.mktmpdir
  rescue StandardError => e
    raise ::Foreman::Exception, "Could not create working directory to store cloudinit config data: #{e}."
  end

  def delete_temp_dir(working_dir)
    FileUtils.remove_entry(working_dir)
  rescue StandardError => e
    logger.warn("Could not delete directory for config files: #{e}. Please delete it manually at #{working_dir}")
  end

  def cloudinit_clone_args(args, vm_instance)
    return args unless args[:user_data]

    actual_node = vm_instance.node_id
    logger.info("Cloud-init ISO storage will be validated for cloned VM node #{actual_node} instead of selected node #{args[:node_id]}") if args[:node_id] != actual_node

    parse_cloudinit_config(args, vm_node: actual_node)
  end

  def parse_cloudinit_config(args, vm_node: args[:node_id])
    filenames = ["meta-data"]
    config_data = ["instance-id: #{args[:name]}"]
    user_data = args.delete(:user_data)
    return args if user_data == ''
    check_template_format(user_data)

    if user_data.include?('#network-config') && user_data.include?('#cloud-config')
      config_data.concat(user_data.split('#network-config'))
      filenames.concat(['user-data', 'network-config'])
    elsif user_data.include?('#network-config') && !user_data.include?('#cloud-config')
      config_data.append(user_data.split('#network-config')[1])
      filenames.append("network-config")
    elsif !user_data.include?('#network-config') && user_data.include?('#cloud-config')
      config_data.append(user_data)
      filenames.append("user-data")
    end

    return args if config_data.length == 1
    configs = filenames.zip(config_data).to_h

    create_cloudinit_iso(args[:name], configs) do |iso|
      storage = upload_iso(args[:node_id], args[:iso_upload_storage], iso, vm_node: vm_node)
      args.merge!(attach_cloudinit_iso(vm_node, storage, iso))
    end
  end

  def upload_iso(node, storage_id, iso, vm_node: node)
    raise ::Foreman::Exception, _('ISO upload storage must be selected') if storage_id.blank?

    iso_storages = storages(node, 'iso')
    storage = iso_storages.find { |s| s.identity == storage_id }
    raise ::Foreman::Exception, "Could not find selected ISO upload storage #{storage_id} for node #{node}" unless storage

    if node != vm_node
      vm_storage = storages(vm_node, 'iso').find { |s| s.identity == storage_id }
      raise ::Foreman::Exception, "Selected ISO upload storage #{storage_id} is not accessible from cloned VM node #{vm_node}" unless vm_storage

      storage = vm_storage
    end

    storage.upload_iso(iso)
    storage.identity
  end

  def attach_cloudinit_iso(node, storage_id, iso)
    storage = client.nodes.get(node).storages.get(storage_id)
    volume = storage&.volumes&.all&.detect do |v|
      File.basename(v.volid) == File.basename(iso)
    end

    raise ::Foreman::Exception, "Could not find generated cloud-init ISO #{File.basename(iso)} on storage #{storage_id} for node #{node}" unless volume

    { ide2: "#{volume.volid},media=cdrom" }
  end

  def check_template_format(user_data)
    YAML.safe_load(user_data)
  rescue StandardError => e
    raise ::Foreman::Exception, "'User data kind' template provided could not be loaded, please check the format: #{e}"
  end
end
