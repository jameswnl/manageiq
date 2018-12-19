class ManageIQ::Providers::InfraMigrationJob < Job
  POLL_CONVERSION_INTERVAL = 60

  def self.create_job(options, migrate_task_class, migrate_task_id)
    @conversion_polling_interval = POLL_CONVERSION_INTERVAL  # TODO: from settings
    options[:target_class] = migrate_task_class
    options[:target_id] = migrate_task_id
    super(name, options)
  end

  #
  # State-transition diagram:
  #                              :poll_native_task
  #    *                          /-------------\
  #    | :initialize              |             |
  #    v               :start     v             |
  # waiting_to_start --------> running ------------------------------> refreshing <---------\
  #                               |                     :refresh           |                |
  #                               |                                        |                |
  #                               |                                        |----------------/
  #                               v                                        |   :poll_refresh
  #                             error <------------------------------------|
  #                                                     :error             |
  #                                                                        |
  #       finished <---------- post_refreshing <---------------------------/
  #                   :finish                           :post_refresh
  #

  alias_method :initializing, :dispatch_start
  # alias_method :start,        :pre_conversion
  alias_method :finish,       :process_finished
  alias_method :abort_job,    :process_abort
  alias_method :cancel,       :process_cancel
  alias_method :error,        :process_error

  def load_transitions
    self.state ||= 'initialize'

    {
      :initializing     => {'initialize'       => 'waiting_to_start'},
      :start            => {'waiting_to_start' => 'running'},
      :pre_conversion   => {'running'          => 'running'},
      :run_conversion   => {'running'          => 'running'},
      :poll_conversion  => {'running'          => 'running'},
      :post_conversion  => {'running'          => 'running'},
      :refresh          => {'running'          => 'refreshing'},
      :finish           => {'*'                => 'finished'},
      :abort_job        => {'*'                => 'aborting'},
      :cancel           => {'*'                => 'canceling'},
      :error            => {'*'                => '*'}
    }
  end

  def start
    # TODO
    queue_signal(:run_conversion)
  end

  def run_conversion
    @migrate_task = target_entity
    begin
      @migrate_task.run_conversion  
    rescue => exception
      message = "Failed to start conversion: #{exception}"
      return queue_signal(:abort_job, message, 'error')
    end
    queue_signal(:poll_conversion, :deliver_on => Time.now.utc + @conversion_polling_interval)
  end

  def poll_conversion
    @migrate_task = target_entity
    begin
      @migrate_task.get_conversion_state # update task.options with updates
    rescue => exception
      return queue_signal(:abort_job, "Conversion error: #{exception}", 'error')
    end

    update_attribute(:updated_on, Time.now.utc) # update self.updated_on to prevent timing out
    case @migrate_task.options[:virtv2v_status]
    when 'succeeded'
      queue_signal(:post_conversion)
    when 'active'
      queue_signal(:poll_conversion, :deliver_on => Time.now.utc + @conversion_polling_interval)
    else
      message = "Unknown converstion status: #{@migrate_task.options[:virtv2v_status]}"
      queue_signal(:error, message, 'error')
    end
  end

  def post_conversion
    # TODO
    queue_signal(:finish)
  end

  def post_refresh
    # a step after the refresh, can be overwritten by a subclass
    queue_signal(:finish)
  end

  def refresh
    target = target_entity

    task_ids = EmsRefresh.queue_refresh_task(target)
    if task_ids.blank?
      process_error("Failed to queue refresh", "error")
      queue_signal(:error)
    else
      context[:refresh_task_ids] = task_ids
      update_attributes!(:context => context)

      queue_signal(:poll_refresh)
    end
  end

  def poll_refresh
    if refresh_finished?
      queue_signal(:post_refresh)
    else
      queue_signal(:poll_refresh, :deliver_on => Time.now.utc + 1.minute)
    end
  end

  def queue_signal(*args, deliver_on: nil)
    role     = options[:role] || "ems_operations"
    priority = options[:priority] || MiqQueue::NORMAL_PRIORITY

    MiqQueue.put(
      :class_name  => self.class.name,
      :method_name => "signal",
      :instance_id => id,
      :priority    => priority,
      :role        => role,
      :zone        => zone,
      :task_id     => guid,
      :args        => args,
      :deliver_on  => deliver_on
    )
  end

  def refresh_finished?
    context[:refresh_task_ids].each do |task_id|
      task = MiqTask.find(task_id)

      if task.status != MiqTask::STATUS_OK
        process_error("Refresh failed", "error")
      elsif task.state != MiqTask::STATE_FINISHED
        return false
      end
    end

    true
  end
end
