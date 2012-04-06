class DownloadLog < ActiveRecord::Base
  set_table_name :wpup_download_logs
  
  belongs_to :resource
  belongs_to :download_token
  
  validates_uniqueness_of :resource_id
  
  before_save :set_data
  
  unloadable
  
  private
  
  def set_data 
    self.accessed = Time.now
  end
end
