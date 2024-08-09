# frozen_string_literal: true

ProvisioningTemplate.without_auditing do
  SeedHelper.import_templates(
    Dir[File.join("#{ForemanFogProxmox::Engine.root}/app/views/templates/provisioning/**/*.erb")]
  )
end
