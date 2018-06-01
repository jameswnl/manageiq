class WorkflowNode < ApplicationRecord
  belongs_to :parent, :foreign_key => :parent_id, :class_name => "WorkflowNode"
  belongs_to :configuration_script
  belongs_to :workflow
  belongs_to :manager, :class_name => "ExtManagementSystem"
end
