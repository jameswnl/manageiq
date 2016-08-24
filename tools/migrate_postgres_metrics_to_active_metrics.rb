def write_metrics_to_active_metrics(metrics)
  ActiveMetrics::Base.connection.write_points(
    metrics.map do |m|
      attrs    = m.attributes
      ts       = attrs["timestamp"]
      m_tags   = attrs.slice(*%w(capture_interval_name capture_interval resource_name))
      m_fields = attrs.except(*%w(capture_interval_name capture_interval resource_name timestamp instance_id class_name))

      m_fields.map do |k, v|
        {
          :timestamp   => ts,
          :metric_name => k,
          :value       => v,
          :resource    => self,
          :tags        => m_tags
        }
      end
    end
  )
end

Metric.find_in_batches(100_000) do |metrics|
  write_metrics_to_active_metrics(metrics)
end

MetricRollup.find_in_batches(100_000) do |metrics|
  write_metrics_to_active_metrics(metrics)
end
