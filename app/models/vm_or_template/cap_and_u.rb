module VmOrTemplate::CapAndU
  extend ActiveSupport::Concern

  include CapAndULiveMetricsMixin

  def metrics_capture
    self
  end

  def fetch_metrics_available
    # [{:id => metric.id, :name => @supported_metrics[metric.type_id], :type => metric.type, :unit => metric.unit}]
    [{:id => 'cpu_used_delta_summation', :name => 'cpu_used_delta_summation', :type => Float, :unit => ''}]
  end

  def collect_live_metrics(metrics, start_time, end_time, interval)
    results = tsdb_connection.read(metrics.pluck(:name), start_time, end_time, interval, 'VmOrTemplate', id)
    if results && results.length == 1  && results[0].try('values')
      return results[0]['values'].each_with_object({}) do |pt, m|
        m[pt.delete('time')] = pt
      end
    end
    []
  end

  def collect_stats_metric
    "test"
  end

end