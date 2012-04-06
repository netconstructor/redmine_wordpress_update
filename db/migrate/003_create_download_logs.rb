class CreateDownloadLogs < ActiveRecord::Migration
  def self.up
    create_table :wpup_download_logs do |t|
	  t.column :resource_id, :integer
      t.column :download_token_id, :integer
	  t.column :accessed, :timestamp
	  t.column :ip, :string
    end
  end

  def self.down
    drop_table :wpup_download_logs
  end
end
