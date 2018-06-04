class ConfigurationScript < ConfigurationScriptBase
  def self.base_model
    ConfigurationScript
  end

  has_many :configuration_workflow_nodes, :dependent => :destroy
  has_many :configuration_workflows, :through => :configuration_workflow_nodes
end
