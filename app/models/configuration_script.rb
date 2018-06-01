class ConfigurationScript < ConfigurationScriptBase
  def self.base_model
    ConfigurationScript
  end

  has_many :workflow_nodes
  has_many :workflows, :through => :workflow_nodes
end
