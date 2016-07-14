class CreateJoinTableStorageProfileStorage < ActiveRecord::Migration[5.0]
  def change
    create_table :storage_profile_storages do |t|
      t.bigint  :storage_profile_id
      t.bigint  :storage_id
      t.index [:storage_id, :storage_profile_id], :name => 'storage_to_profile'
      t.index [:storage_profile_id, :storage_id], :name => 'profile_to_storage'
    end
  end
end
