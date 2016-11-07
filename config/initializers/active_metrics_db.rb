ActiveMetrics::Base.establish_connection(
  # :adapter  => "miq_postgres",
  :adapter  => "influxdb",
  # :adapter  => "hawkular_metrics",

  :database => "vmdb_#{Rails.env.downcase}",
  :host     => "192.168.99.100",
  # :username => "root",
  # :password => "smartvm",
)
