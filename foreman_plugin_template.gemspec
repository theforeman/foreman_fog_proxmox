require File.expand_path('../lib/foreman_plugin_template/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "foreman_plugin_template"
  s.version     = ForemanPluginTemplate::VERSION
  s.date        = Date.today.to_s
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ForemanPluginTemplate."
  s.description = "TODO: Description of ForemanPluginTemplate."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "deface"
  #s.add_development_dependency "sqlite3"
end
