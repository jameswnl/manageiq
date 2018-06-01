class ConfigurationScriptWorkflows < ApplicationRecord
  belongs_to :configuration_script
  belongs_to :workflow
end
