class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :wpup_resources do |t|
	  t.column :project_id, :integer, :null => false
	  t.column :cached_type, :string
	  t.column :cached_meta_file, :string
      t.column :slug, :string
	  t.column :public, :boolean, :default => false
    end
  end

  def self.down
    drop_table :wpup_resources
  end
end
