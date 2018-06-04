class ManageIQ::Providers::AutomationManager::ConfigurationWorkflowNode < ::ConfigurationWorkflowNode
  belongs_to :manager, :class_name => "ManageIQ::Providers::AutomationManager", :inverse_of => :configuration_workflow_nodes
end
