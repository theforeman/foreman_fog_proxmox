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

  def create_cloudinit_iso(vm_name, configs, ssh)
    iso = File.join(default_iso_path, "#{vm_name.tr('.', '_')}_cloudinit.iso")
    files = []
    wd = create_temp_directory(ssh)

    configs.each do |config|
      config_file = ssh.run("cat <<'EOF' > '#{wd}/#{config[0]}'\n#{config[1]}\nEOF")
      unless config_file.first.status.zero?
        delete_temp_dir(ssh, wd)
        raise ::Foreman::Exception, "Failed to create file #{config[0]}: #{config_file.first.stdout}"
      end
      files.append(File.join(wd, config[0]))
    end
    generated_iso = ssh.run(generate_iso_command(iso, files))
    unless generated_iso.first.status.zero?
      delete_temp_dir(ssh, wd)
      raise Foreman::Exception, N_("ISO build failed: #{generated_iso.first.stdout}")
    end
    delete_temp_dir(ssh, wd)
    iso
  end

  def generate_iso_command(iso_file, config_files)
    arguments = ["genisoimage", "-output #{iso_file}", '-volid', 'cidata', '-joliet', '-rock']
    iso_command = arguments.concat(config_files).join(' ')
    logger.debug("iso image generation args: #{iso_command}")
    iso_command
  end

  def create_temp_directory(ssh)
    res = ssh.run("mktemp -d")
    raise ::Foreman::Exception, "Could not create working directory to store cloudinit config data: #{res.first.stdout}." unless res.first.status.zero?
    res.first.stdout.chomp
  end

  def delete_temp_dir(ssh, working_dir)
    ssh.run("rm -rf #{working_dir}")
  rescue Foreman::Exception => e
    logger.warn("Could not delete directory for config files: #{e}. Please delete it manually at #{working_dir}")
  end

  def parse_cloudinit_config(args)
    filenames = ["meta-data"]
    config_data = ["instance-id: #{args[:name]}"]
    user_data = args.delete(:user_data)
    return args if user_data == ''
    check_template_format(user_data)
    ssh = vm_ssh

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

    iso = create_cloudinit_iso(args[:name], configs, ssh)
    args[:config_attributes]&.merge!(update_boot_order(args[:image_id]))
    args.merge!(attach_cloudinit_iso(args[:node_id], iso))
  end

  def attach_cloudinit_iso(node, iso)
    storage = storages(node, 'iso')[0]
    volume = storage.volumes.detect { |v| v.volid.include? File.basename(iso) }
    { ide2: "#{volume.volid},media=cdrom" }
  end

  def default_iso_path
    "/var/lib/vz/template/iso"
  end

  def update_boot_order(image_id)
    vm = find_vm_by_uuid(image_id)
    return if vm.disks.nil?
    disks = vm.disks.map { |disk| disk.split(":")[0] }.join(";")
    { boot: "order=" + disks }
  end

  def vm_ssh
    ssh = Fog::SSH.new(URI.parse(fog_credentials[:proxmox_url]).host, fog_credentials[:proxmox_username].split('@')[0], { password: fog_credentials[:proxmox_password] })
    ssh.run('ls') # test if ssh is successful
    ssh
  rescue StandardError => e
    raise ::Foreman::Exception, "Unable to ssh into proxmox server: #{e}"
  end

  def check_template_format(user_data)
    YAML.safe_load(user_data)
  rescue StandardError => e
    raise ::Foreman::Exception, "'User data kind' template provided could not be loaded, please check the format: #{e}"
  end
end
