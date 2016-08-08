require 'active_metrics/connection_adapters/abstract_adapter'

module ActiveMetrics
  module ConnectionAdapters
    class HawkularMetricsAdapter < AbstractAdapter
      def self.create_connection(config)
        db       = config[:database]
        hostname = config[:hostname] || "localhost"
        port     = (config[:port] || 8080).to_i

        require 'hawkular/hawkular_client'
        Hawkular::Metrics::Client.new(
          URI::HTTP.build(:host => hostname, :port => port).to_s,
          config.slice(:username, :password),
          :tenant => 'hawkular',
        )
      end

      def write_multiple(*metrics)
        metrics.flatten!

        metrics.group_by { |m| m[:metric_name] }.each do |metric_name, metrics_subset|
          points = metrics_subset.map { |metric| build_point(metric) }
          raw_connection.gauges.push_data(metric_name, points)
        end

        metrics
      end

      private

      def build_point(timestamp:, metric_name:, value:, resource: nil, resource_type: nil, resource_id: nil, tags: {})
        raise ArgumentError, "missing resource or resource_type/resource_id pair" if resource.nil? && (resource_type.nil? || resource_id.nil?)

        {
          :timestamp => (timestamp.to_f * 1000).to_i, # ms precision
          :value     => value,
          :tags      => tags.symbolize_keys.merge(
            :resource_type => resource ? resource.class.base_class.name : resource_type,
            :resource_id   => resource ? resource.id : resource_id
          ),
        }
      end
    end
  end
end
