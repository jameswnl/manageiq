module ConversionHost::Operations
  extend ActiveSupport::Concern
  module ClassMethods
    DEFAULT_EMS_MAX_RUNNERS = 10
    def refresh_tasks
      ConversionHost.all.flat_map(&:active_tasks).each do |task|
        begin
          task.get_conversion_state
        rescue StandardError => error
          _log.error(error)
          # notify_task_status('conversion', false, "name=#{task.source.name}, id=#{task.source.id}")
          # TODO: raise Automate event to flag statemachine failure?
        ensure
          task.save
        end
      end
    end

    def assign_to_tasks
      pending_tasks = ServiceTemplateTransformationPlanTask.where(:state => 'active', :conversion_host => nil)
      return if pending_tasks.empty?
      by_ems = pending_tasks.sort_by(&:created_on).each_with_object({}) do |task, hash|
        hash[task.destination_ems] = hash[task.destination_ems] || []
        hash[task.destination_ems].append(task)
      end
      by_ems.each do |ems, tasks|
        running_num = ems.conversion_hosts.inject(0) { |sum, ch| sum + ch.active_tasks.size }
        slots = (ems.miq_custom_get('Max Transformation Runners') || DEFAULT_EMS_MAX_RUNNERS) - running_num
        tasks.each do |task|
          eligible_hosts = ems.conversion_hosts.select(&:eligible?).sort_by { |ch| ch.active_tasks.size }
          break if slots <= 0 || eligible_hosts.empty?
          task.conversion_host = eligible_hosts.first
          task.save
          slots -= 1
        end
      end
    end

    def notify_task_status(op, success, source_info)
      Notification.create(
        :type    => success ? :transformation_task_success : :transformation_task_failure,
        :options => {
          :op_name => op,
          :op_arg  => source_info,
        }
      )
    end
  end
end
