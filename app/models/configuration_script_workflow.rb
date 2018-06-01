class ConfigurationScriptWorkflow < ApplicationRecord
  # belongs_to :configuration_script, :foreign_key => "configuration_script_id"
  # belongs_to :workflow, :foreign_key => "workflow_id"

  belongs_to :workflow_node, :foreign_key => "configuration_script_id", :class_name => "ConfigurationScriptBase"
  belongs_to :workflow, :foreign_key => "workflow_id", :class_name => "ConfigurationScriptBase"
end
