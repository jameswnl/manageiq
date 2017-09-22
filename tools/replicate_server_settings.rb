#!/usr/bin/env ruby
require File.expand_path("../config/environment", __dir__)
$LOAD_PATH << Rails.root.join("tools")
require 'trollop'
require 'server_settings_replicator/server_settings_replicator'

opts = Trollop.options(ARGV) do
  banner "USAGE:   #{__FILE__} -s <server id> -p <path/to/the/settings> \n" \
         "Example: #{__FILE__} -d -s 1 -p ems/ems_amazon/additional_instance_types"

  opt :dry_run,  "Dry Run",                                                :short => "d"
  opt :serverid, "Replicating source server Id (default: current server)", :short => "s"
  opt :path,     "Replicating source path within advanced settings hash",  :short => "p", :default => ""
end

puts opts.inspect
Trollop.die :path, "is required" unless opts[:path_given]

server = opts[:serverid] ? MiqServer.find(opts[:serverid]) : MiqServer.my_server

# all servers except source
target_servers = MiqServer.where.not(:id => server.id)
puts "Replicating from server id=#{server.id}, path=#{opts[:path]} to #{target_servers.count} servers"
ServerSettingsReplicator.replicate(server, opts[:path], target_servers, opts[:dry_run])
puts "Done"
