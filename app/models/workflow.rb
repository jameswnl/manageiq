class Workflow < ConfigurationScriptBase
  def self.base_model
    Workflow
  end
  has_many :workflow_nodes
  has_many :configuration_scripts, :through => :workflow_nodes
  belongs_to :manager, :class_name => "ExtManagementSystem"
end
