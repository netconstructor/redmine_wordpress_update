class Resource < ActiveRecord::Base
  set_table_name :wpup_resources
  
  belongs_to :project
  
  has_many :download_tokens
  has_many :download_logs
  
  validates_presence_of :project_id
  validates_uniqueness_of :project_id
  validates_uniqueness_of :slug
  
  attr_accessible :public, :slug
  
  unloadable
end
