class ConfigurationWorkflowNode < ApplicationRecord
  belongs_to :parent, :foreign_key => :parent_id, :class_name => "ConfigurationWorkflowNode"
  belongs_to :configuration_script
  belongs_to :configuration_workflow
  belongs_to :manager, :class_name => "ExtManagementSystem"
end
