class ConfigurationWorkflow < ConfigurationScriptBase
  def self.base_model
    ConfigurationWorkflow
  end
  has_many :configuration_workflow_nodes, :dependent => :destroy
  has_many :configuration_scripts, :through => :configuration_workflow_nodes
end
