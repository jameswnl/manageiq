module CapAndULiveMetricsMixin
  include LiveMetricsMixin

  def tsdb_connection
    ActiveMetrics::Base.connection
  end
end