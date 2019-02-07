describe InfraConversionThrottler do
    let(:ems) { FactoryBot.create(:ext_management_system, :zone => FactoryBot.create(:zone)) }
    let(:host) { FactoryBot.create(:host, :ext_management_system => ems) }
    let(:vm)  { FactoryBot.create(:vm_or_template) }
    let(:conversion_host1) { FactoryBot.create(:conversion_host, :max_concurrent_tasks => 1, :resource => host) }
    let(:conversion_host2) { FactoryBot.create(:conversion_host, :max_concurrent_tasks => 1, :resource => vm) }
    let(:task) { FactoryBot.create(:service_template_transformation_plan_task, :source => vm) }
    let(:job) { FactoryBot.create(:infra_conversion_job, :state => 'waiting_to_start') }

    before do
        ems.miq_custom_set('Max Transformation Runners', 2)
        allow(conversion_host1).to receive(:active_tasks).and_return(1)
        allow(conversion_host2).to receive(:active_tasks).and_return(1)
        allow(task).to receive(:destination_ems).and_return(ems)
        allow(job).to receive(:migration_task).and_return(task)
        allow(described_class).to receive(:pending_conversion_jobs).and_return(ems => [job])
    end

    context '.start_conversions' do
        

        it 'will not start a job when ems limit hit' do
            described_class.start_conversions
            expect(job).not_to receive(:queue_signal)
        end

        it 'will not start a job when conversion_host limit hit' do
            byebug
            ems.miq_custom_set('Max Transformation Runners', 100)
            expect(conversion_host1).to receive(:active_tasks).and_return(2)
            expect(conversion_host2).to receive(:active_tasks).and_return(2)
            described_class.start_conversions
            expect(job).not_to receive(:queue_signal)
        end

        it 'will start a job when limits are not hit' do
            byebug
            expect(conversion_host1).to receive(:active_tasks).and_return(0)
            described_class.start_conversions
            expect(job).to receive(:queue_signal).with(:start)
        end
    end
end