class Workflow < ConfigurationScriptBase
  def self.base_model
    Workflow

    has_many :configuration_script_workflows
    has_many :configuration_scripts :through => :configuration_script_workflows
  end
end
