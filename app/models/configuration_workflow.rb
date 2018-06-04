class ConfigurationWorkflow < ConfigurationScriptBase
  def self.base_model
    ConfigurationWorkflow
  end
  has_many :configuration_workflow_nodes
  has_many :configuration_scripts, :through => :configuration_workflow_nodes
  belongs_to :manager, :class_name => "ExtManagementSystem"
end
