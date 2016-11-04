class ActiveMetric < LiveMetric
  def self.tsdb_connection
    ActiveMetrics::Base.connection
  end

  def self.find(*args)
    byebug
    raw_query = args[0]
    processed = raw_query
    resource = nil # processed[:resource_type].nil? ? fetch_resource(processed[:resource_type], processed[:resource_id]): nil
    filtered_cols = raw_query[:select] || raw_query[:include].keys.map(&:to_s)
    filter_and_fetch_metrics(resource, filtered_cols, processed[:start_time],
                             processed[:end_time], processed[:interval_name])
  end


  def fetch_metrics_available
    # [{:id => metric.id, :name => @supported_metrics[metric.type_id], :type => metric.type, :unit => metric.unit}]
    # [{:id => 'cpu_used_delta_summation', :name => 'cpu_used_delta_summation', :type => Float, :unit => ''}]
    results = tsdb_connection.get_metrics
  end

  def self.filter_and_fetch_metrics(resource, filter, start_time, end_time, interval_name)
    # filtered = fetch_metrics_available
    filtered = filter.each_with_object([]) do |field, m| m.push(:id =>field, :name=>field, :type=>Float) end
    # if metrics.blank?
    #   filtered = filter.map { |m| {:name => m, :id => m, :type => Float} }
    # else
    #   filtered = metrics.select { |metric| filter.nil? || filter.include?(metric[:name]) }
    # end
    filtered.each { |metric| set_columns_hash(metric[:name] => :float) }
    fetch_live_metrics(resource, filtered, start_time, end_time, interval_name)
  end

  def self.process_conditions(conditions)
    parsed_conditions = parse_conditions(conditions.first)
    processed = {}
    parsed_conditions.each do |condition|
      case condition[:column]
        when "resource_type"         then processed[:resource_type] = condition[:value]
        when "resource_id"           then processed[:resource_id] = condition[:value]
        when "timestamp"             then process_timestamps(processed, condition)
        when "capture_interval_name" then processed[:interval_name] = condition[:value]
      end
    end
    validate_conditions(processed)
    processed
  end

  def self.parse_conditions(raw_conditions)
    if raw_conditions.index('or')
      _log.error("LiveMetric expression #{raw_conditions} must not contain 'or' operator.")
      raise LiveMetricError, "LiveMetric expression doesn't support 'or' operator"
    end
    raw_conditions.split('and').collect do |exp|
      parsed = exp.scan(/(.*)\s+(<=|=|>=|<|>|!=)\s+(.*)/)
      parse_condition(process_conditionsparsed[0][0], parsed[0][1], parsed[0][2])
    end
  end

  def self.parse_condition(column, op, value)
    value = value.strip
    value = value[1..value.length - 2] if value[0] == '\'' && value[value.length - 1] == '\''
    {:column => column.strip, :op => op.strip, :value => value}
  end

  def self.fetch_live_metrics(resource, metrics, start_time, end_time, interval_name)
    byebug
    interval = case interval_name
                 when "daily"  then 24 * 60 * 60
                 when "hourly" then 60 * 60
                 else 60
               end
    begin
      raw_metrics = collect_live_metrics(metrics, start_time, end_time, interval, resource)
      i = 0
      raw_metrics.collect do |ts, metric|
        processed_metric = ActiveMetric.new
        processed_metric.id = i
        i += 1
        processed_metric[:timestamp] = Time.at(ts).utc
        metric.each do |column, value|
          processed_metric[column] = value
        end
        processed_metric
      end
    rescue => err
      _log.error "An error occurred while connecting to #{resource}: #{err}"
    end
  end


  def self.fetch_metrics_available
    # [{:id => metric.id, :name => @supported_metrics[metric.type_id], :type => metric.type, :unit => metric.unit}]
    # [{:id => 'cpu_used_delta_summation', :name => 'cpu_used_delta_summation', :type => Float, :unit => ''}]
    results = tsdb_connection.get_metrics
  end

  def self.collect_live_metrics(metrics, start_time, end_time, interval, resource=nil)
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
        :resource   => resource
    )
  end
end