class ConfigurationWorkflowNode < ApplicationRecord
  belongs_to :parent, :foreign_key => :parent_id, :class_name => "ConfigurationWorkflowNode", :inverse_of => :configuration_workflows
  belongs_to :configuration_script
  belongs_to :configuration_workflow
end
