module VmOrTemplate::CapAndU
  extend ActiveSupport::Concern

  include CapAndULiveMetricsMixin

  def metrics_capture
    self
  end

  def fetch_metrics_available
    # [{:id => metric.id, :name => @supported_metrics[metric.type_id], :type => metric.type, :unit => metric.unit}]
  end

  def collect_live_metrics(metrics, start_time, end_time, interval)
    tsdb_connection.read("select count(cpu_usage_rate_average) from metrics where resource_name = 'jwong-vc60'")
  end

  def collect_stats_metric
    "test"
  end

end