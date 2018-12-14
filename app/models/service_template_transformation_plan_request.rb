class ServiceTemplateTransformationPlanRequest < ServiceTemplateProvisionRequest
  TASK_DESCRIPTION = 'VM Transformations'.freeze

  delegate :transformation_mapping, :vm_resources, :to => :source

  def requested_task_idx
    vm_resources.where(:status => ServiceResource::STATUS_APPROVED)
    #  ?? vm_resources.all # ignore approval?
  end

  def customize_request_task_attributes(req_task_attrs, vm_resource)
    req_task_attrs[:source] = vm_resource.resource
  end

  def source_vms
    vm_resources.where(:status => [ServiceResource::STATUS_QUEUED, ServiceResource::STATUS_FAILED]).pluck(:resource_id)
  end

  def validate_conversion_hosts
    transformation_mapping.transformation_mapping_items.select do |item|
      %w(EmsCluster CloudTenant).include?(item.source_type)
    end.all? do |item|
      item.destination.ext_management_system.conversion_hosts.present?
    end
  end

  def validate_vm(_vm_id)
    # TODO: enhance the logic to determine whether this VM can be included in this request
    true
  end

  def approve_vm(vm_id)
  # STATUS_ACTIVE    = 'Active'.freeze
  # STATUS_APPROVED  = 'Approved'.freeze
  # STATUS_COMPLETED = 'Completed'.freeze
  # STATUS_FAILED    = 'Failed'.freeze
  # STATUS_QUEUED    = 'Queued'.freeze
    vm_resources.find_by(:resource_id => vm_id).update_attributes!(:status => ServiceResource::STATUS_APPROVED)
  end

  def cancel
    update_attributes(:cancelation_status => MiqRequest::CANCEL_STATUS_REQUESTED)
    miq_request_tasks.each(&:cancel)
  end

  def update_request_status
    super
    if request_state == 'finished' && status == 'Ok'
      Notification.create(:type => "transformation_plan_request_succeeded", :options => {:plan_name => description})
    elsif request_state == 'finished' && status != 'Ok'
      Notification.create(:type => "transformation_plan_request_failed", :options => {:plan_name => description}, :subject => self)
    end
  end

  # def create_request_tasks
  #   if cancel_requested?
  #     do_cancel
  #     return
  #   end

  #   # Quota denial will result in automate_event_failed? being true
  #   # return if automate_event_failed?("request_starting")

  #   _log.info("Creating request task instances for: <#{description}>...")
  #   # Create a MiqRequestTask object for each requested item
  #   options[:delivered_on] = Time.now.utc
  #   update_attribute(:options, options)

  #   begin
  #     requested_tasks = requested_task_idx
  #     request_task_created = 0
  #     requested_tasks.each do |idx|
  #       req_task = create_request_task(idx)
  #       miq_request_tasks << req_task
  #       req_task.deliver_to_automate
  #       request_task_created += 1
  #     end
  #     update_request_status
  #     post_create_request_tasks
  #   rescue
  #     _log.log_backtrace($ERROR_INFO)
  #     request_state, status = request_task_created.zero? ? %w(finished Error) : %w(active Warn)
  #     update_attributes(:request_state => request_state, :status => status, :message => "Error: #{$ERROR_INFO}")
  #   end
  # end
end
