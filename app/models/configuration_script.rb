class ConfigurationScript < ConfigurationScriptBase
  def self.base_model
    ConfigurationScript

    has_many :configuration_script_workflows
    has_many :workflows :through => :configuration_script_workflows
  end
end
