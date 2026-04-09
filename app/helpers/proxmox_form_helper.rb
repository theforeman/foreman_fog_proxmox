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

module ProxmoxFormHelper
  include ProxmoxVMInterfacesHelper

  def proxmox_vm_type_and_node_id(host, form_object, params)
    compute_attributes = form_object.compute_attributes || {}
    host_compute_attrs = host.respond_to?(:compute_attributes) ? (host.compute_attributes || {}) : {}
    host_vm_type = extract_attr(host_compute_attrs, :type)

    profile_attrs = profile_compute_attributes(host)
    profile_vm_type = extract_attr(profile_attrs, :type)

    vm_type = [
      params.dig(:host, :compute_attributes, :type).presence,
      params.dig(:compute_attribute, :vm_attrs, :type).presence,
      host_vm_type,
      profile_vm_type,
      'qemu',
    ].find(&:present?)

    compute_attributes = proxmox_default_interface_compute_attributes(host, vm_type) unless proxmox_valid_interface_compute_attributes?(compute_attributes, vm_type)

    compute_node_id = extract_attr(compute_attributes, :node_id)
    object_node_id = form_object.respond_to?(:node_id) ? form_object.node_id : nil
    host_node_id = extract_attr(host_compute_attrs, :node_id)
    profile_node_id = extract_attr(profile_attrs, :node_id)

    node_id = [
      params.dig(:host, :compute_attributes, :node_id).presence,
      params.dig(:compute_attribute, :vm_attrs, :node_id).presence,
      object_node_id,
      compute_node_id,
      host_node_id,
      profile_node_id,
    ].find(&:present?)

    {
      compute_attributes: compute_attributes,
      vm_type: vm_type,
      node_id: node_id,
    }
  end

  def password_proxmox_f(f, attr, options = {})
    unset_button = options.delete(:unset)
    value = f.object[attr] if options.delete(:keep_value)
    password_field_tag(:fakepassword, value, :style => 'display: none', :autocomplete => 'new-password-fake') +
      field(f, attr, options) do
        options[:autocomplete]   ||= 'new-password'
        options[:placeholder]    ||= password_proxmox_placeholder(f.object, attr)
        options[:disabled] = true if unset_button
        options[:value] = value if value.present?
        addClass options, 'form-control'
        pass = f.password_field(attr, options) +
               tag(:span, '', class: 'glyphicon glyphicon-warning-sign input-addon', title: 'Caps lock ON',
                 style: 'display:none')
        if unset_button
          button = link_to_function(icon_text('edit', '', :kind => 'pficon'), 'toggle_input_group(this)',
            :id => 'disable-pass-btn', :class => 'btn btn-default', :title => _('Change the password'))
          input_group(pass, input_group_btn(button))
        else
          pass
        end
      end
  end

  def password_proxmox_placeholder(obj, attr = nil)
    pass = obj.attributes.key?(attr)
    pass ? '********' : ''
  end

  def new_child_fields_template_typed(form_builder, association, options = {})
    if options[:object].blank?
      association_object = form_builder.object.class.reflect_on_association(association)
      options[:object] = association_object.klass.new(association_object.foreign_key => form_builder.object.id)
    end
    options[:partial]            ||= association.to_s.singularize
    options[:form_builder_local] ||= :f
    options[:form_builder_attrs] ||= {}

    content_tag(:div, :class => "#{options[:type]}_#{association}_fields_template form_template",
      :style => 'display: none;') do
      form_builder.fields_for(association, options[:object],
        :child_index => "new_#{options[:type]}_#{association}") do |f|
        render(:partial => options[:partial], :layout => options[:layout],
          :locals => { options[:form_builder_local] => f }.merge(options[:form_builder_attrs]))
      end
    end
  end

  def add_child_link_typed(name, association, type, opts = {})
    opts[:class] = [opts[:class], 'add_nested_fields btn btn-primary'].compact.join(' ')
    opts[:"data-association"] = (type + '_' + association.to_s).to_sym
    hide = ''
    hide += '$("[data-association=' + type + '_volumes]").hide();' unless ['hard_disk', 'mp'].include?(type)
    link_to_function(name.to_s, 'add_child_node(this);' + hide, opts)
  end

  def remove_child_link_typed(name, f, type, opts = {})
    opts[:class] = [opts[:class], 'remove_nested_fields'].compact.join(' ')
    hide = ''
    hide += '$("[data-association=' + type + '_volumes]").show();' unless ['hard_disk', 'mp'].include?(type)
    f.hidden_field(opts[:method] || :_destroy) + link_to_function(name, 'remove_child_node(this);' + hide, opts)
  end

  private

  def proxmox_default_interface_compute_attributes(host, vm_type)
    host.compute_resource.interface_typed_defaults(vm_type).fetch(:compute_attributes).deep_dup
  end

  def proxmox_valid_interface_compute_attributes?(compute_attributes, vm_type)
    return false unless compute_attributes.respond_to?(:keys)

    valid_keys = interface_compute_attributes_typed_keys(vm_type)
    compute_attributes.keys.map(&:to_s).all? { |key| valid_keys.include?(key) }
  end

  def extract_attr(attrs, key)
    return unless attrs.respond_to?(:[])

    attrs[key.to_s] || attrs[key.to_sym]
  end

  def profile_compute_attributes(host)
    inherited_profile_id = host.respond_to?(:hostgroup) ? host.hostgroup&.inherited_compute_profile_id : nil
    profile_id = host.compute_profile_id || inherited_profile_id

    return {} if profile_id.blank?

    host.compute_resource.compute_profile_attributes_for(profile_id) || {}
  end
end
