require 'active_metrics/connection_adapters/abstract_adapter'

module ActiveMetrics
  module ConnectionAdapters
    class InfluxdbAdapter < AbstractAdapter
      SERIES    = "metrics".freeze
      PRECISION = "ms".freeze

      def self.ts_precision(time_obj)
        case PRECISION
          when "ms" then (time_obj.to_f * 1000).to_i
          when "ns" then (time_obj.to_f * 1000000).to_i
        end
      end

      def self.create_connection(config)
        db = config[:database]
        _log.info "creating InfluxdbAdapter connection"

        require 'influxdb'
        InfluxDB::Client.new(db, :time_precision => PRECISION, :retry => 10).tap do |client|
          client.create_database(db) unless client.list_databases.include?(db)
        end
      end

      def write_multiple(*metrics)
        metrics.flatten!
        points = metrics.map { |metric| build_point(metric) }
        raw_connection.write_points(points)
        metrics
      end

      def read(parm={})
        metrics = parm[:metrics] ? parm[:metrics].join(',') : '*'
        resource = parm[:resource]?
            "resource_type='#{parm[:resource].class.base_class.name}' and resource_id='#{parm[:resource].id}'": nil
        # where with time range is a must for group by time, so we always set it
        from = "time >= #{((parm[:start_time] || 0).to_f * 1000000000).to_i}"
        to   = "time <= #{((parm[:end_time] || Time.now).to_f * 1000000000).to_i}"
        where_clause = "WHERE #{[resource, from, to].compact.join(' and ')}"
        group_by_time = parm[:bucket_sec] ? "GROUP BY time(#{parm[:bucket_sec]}s)": ""
        group_by_time = parm[:metrics].any? { |m| !m.include?('(') } ? '': group_by_time

        query = "select #{metrics} from #{SERIES} #{where_clause} #{group_by_time} fill(0)"
        raw_connection.query(query, epoch: PRECISION) do |name, tags, points|

          return (points || []).each_with_object({}) do |pt, m|
            m[pt.delete('time')] = pt
          end
        end
      end

      def get_metrics
        # [{:id => 'cpu_used_delta_summation', :name => 'cpu_used_delta_summation', :type => Float, :unit => ''}]
        raw_connection.query("show field keys") do |name, tags, field_keys|
          return (field_keys || []).each_with_object([]) do |field, m|
            m.push(
              :id => field['fieldKey'],
              :name => field['fieldKey'],
              :type => field['fieldType'].capitalize.constantize,
            )
          end
        end
      end

      private

      def build_point(timestamp:, metric_name:, value:, resource: nil, resource_type: nil, resource_id: nil, tags: {})
        raise ArgumentError, "missing resource or resource_type/resource_id pair" if resource.nil? && (resource_type.nil? || resource_id.nil?)

        {
          :series    => SERIES,
          :timestamp => self.class.ts_precision(timestamp), # ms precision
          :values    => { metric_name.to_sym => value },
          :tags      => tags.symbolize_keys.merge(
            :resource_type => resource ? resource.class.base_class.name : resource_type,
            :resource_id   => resource ? resource.id : resource_id
          ),
        }
      end
    end
  end
end
