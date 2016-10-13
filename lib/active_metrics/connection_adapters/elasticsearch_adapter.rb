require 'active_metrics/connection_adapters/abstract_adapter'

module ActiveMetrics
  module ConnectionAdapters
    class ElasticsearchAdapter < AbstractAdapter
      INDEX = "miq".freeze
      TYPE  = "c_and_u".freeze

      def self.create_connection(config)
        db = config[:database]

        require 'elasticsearch'
        Elasticsearch::Client.new
      end

      def write_multiple(*metrics)
        metrics.flatten!
        points = metrics.map do |metric|
          {
              index: {
                  data: build_point(metric)
              }
          }
        end
        raw_connection.bulk(index: INDEX, type: TYPE, body: points)
        metrics
      end

      private

      def build_point(timestamp:, metric_name:, value:, resource: nil, resource_type: nil, resource_id: nil, tags: {})
        raise ArgumentError, "missing resource or resource_type/resource_id pair" if resource.nil? && (resource_type.nil? || resource_id.nil?)

        {
            metric_name     => value,
            :timestamp      => (timestamp.to_f * 1000).to_i, # ms precision
            :tags           => tags.symbolize_keys.merge(
                :resource_type => resource ? resource.class.base_class.name : resource_type,
                :resource_id   => resource ? resource.id : resource_id
            )
        }
      end
    end
  end
end
