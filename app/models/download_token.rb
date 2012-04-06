class DownloadToken < ActiveRecord::Base
  set_table_name :wpup_download_tokens
  
  belongs_to :resource
  has_many :download_logs
  
  validates_presence_of :resource_id
  validates_presence_of :identifier
  validates_presence_of :token
  validates_uniqueness_of :token
  
  unloadable
end
