ActiveMetrics::Base.establish_connection(
  :adapter  => "miq_postgres",
  # :adapter  => "influxdb",
  # :adapter  => "hawkular_metrics",

  :database => "vmdb_#{Rails.env.downcase}",
  # :host     => "localhost",
  # :username => "root",
  # :password => "smartvm",
)
