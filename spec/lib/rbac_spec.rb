describe Rbac do
  before { allow(User).to receive_messages(:server_timezone => "UTC") }

  describe ".resources_shared_with" do
    let(:user) do
      FactoryGirl.create(:user,
                         :role     => "user",
                         :tenant   => FactoryGirl.create(:tenant, :name => "Tenant under root"),
                         :features => user_allowed_feature)
    end
    let(:user_allowed_feature) { "service" }
    let(:resource_to_be_shared) { FactoryGirl.create(:vm_vmware, :tenant => user.current_tenant) }
    let(:tenants) { [sharee.current_tenant] }
    let(:features) { :all }
    let!(:share) do
      ResourceSharer.new(:user     => user,
                         :resource => resource_to_be_shared,
                         :tenants  => tenants,
                         :features => features)
    end
    let(:sharee) do
      FactoryGirl.create(:user,
                         :miq_groups => [FactoryGirl.create(:miq_group,
                                                            :tenant => FactoryGirl.create(:tenant, :name => "Sibling tenant"))])
    end

    before { Tenant.seed }

    context "with direct tenant" do
      it "works" do
        expect(Rbac.resources_shared_with(sharee)).to be_empty

        share.share
        expect(Rbac.resources_shared_with(sharee)).to include(resource_to_be_shared)

        user.owned_shares.destroy_all
        expect(Rbac.resources_shared_with(sharee)).to be_empty
      end
    end

    context "with tenant inheritance" do
      let(:sibling_tenant) { FactoryGirl.create(:tenant, :name => "Sibling tenant") }
      let(:siblings_child) { FactoryGirl.create(:tenant, :parent => sibling_tenant, :name => "Sibling's child tenant") }
      let(:sharee) do
        FactoryGirl.create(:user,
                           :miq_groups => [FactoryGirl.create(:miq_group,
                                                              :tenant => siblings_child)])
      end

      let(:tenants) { [sibling_tenant] }

      it "works" do
        expect(Rbac.resources_shared_with(sharee)).to be_empty

        share.share
        expect(Rbac.resources_shared_with(sharee)).to include(resource_to_be_shared)

        user.owned_shares.destroy_all
        expect(Rbac.resources_shared_with(sharee)).to be_empty
      end
    end
  end
end
