class ConfigurationScriptNode < ApplicationRecord
  self.table_name = 'configuration_script_base_configuration_script_bases'
  belongs_to :child,  :foreign_key => "child_id",  :class_name => "ConfigurationScriptBase"
  belongs_to :parent, :foreign_key => "parent_id", :class_name => "ConfigurationScriptBase"
end
