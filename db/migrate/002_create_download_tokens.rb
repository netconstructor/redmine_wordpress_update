class CreateDownloadTokens < ActiveRecord::Migration
  def self.up
    create_table :wpup_download_tokens do |t|
	  t.column :resource_id, :integer, :null => false
	  t.column :active, :boolean
      t.column :identifier, :string
      t.column :token, :string
    end
  end

  def self.down
    drop_table :wpup_download_tokens
  end
end
