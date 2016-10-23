module VmOrTemplate::CapAndU
  extend ActiveSupport::Concern

  include CapAndULiveMetricsMixin

  def metrics_capture
    self
  end

  def fetch_metrics_available
    # [{:id => metric.id, :name => @supported_metrics[metric.type_id], :type => metric.type, :unit => metric.unit}]
    # [{:id => 'cpu_used_delta_summation', :name => 'cpu_used_delta_summation', :type => Float, :unit => ''}]
  end

  def collect_live_metrics(metrics, start_time, end_time, interval)
    # TODO: this is a hack. need to generalize this for cross TSDB and aggregate methods
    r = metrics.pluck(:name).map{ |name| name.start_with?('max_') ? "max(#{name[4..-1]}) as #{name}" : name }
    r2 = r.map{ |name| name.start_with?('min_') ? "min(#{name[4..-1]}) as #{name}" : name }
    r3 = r2.map{ |name| name.start_with?('v_pct_') ? "mean(#{name[6..-1]}) as #{name}" : name }
    r4 = r3.map{ |name| name.start_with?('v_derived_')  ? "sum(#{name['v_derived_'.length..-1]}) as #{name}" : name }
    # metric_names = metrics.pluck(:name).map{ |name| "mean(#{name}) as #{name}" }
    metric_names = r4
    results = tsdb_connection.read(
        :metrics    => metric_names,
        :start_time => start_time,
        :end_time   => end_time,
        :bucket_sec => interval,
        :resource   => self
    )
  end

  def collect_stats_metric
    "test"
  end

end