# from http://www.redmine.org/plugins/redmine_repository

require 'rubygems' 
require 'zip/zip'
require 'zip/zipfilesystem'

class WpZip
  
  attr_reader :file_count
  
  def initialize()
    @zip = Tempfile.new(["wpzip",".zip"])
    @zip_file = Zip::ZipOutputStream.new(@zip.path)
    @file_count = 0
  end
  
  def finish
    @zip_file.close unless @zip_file.nil?
    @zip
  end
  
  def close
    @zip_file.close unless @zip_file.nil?
    @zip.close unless @zip.nil?
  end
  
  def add_file(file, cat)
    @zip_file.put_next_entry(file)
    @zip_file.write(cat)
    @file_count += 1
  end
  
  def add_folder(folder)
    @zip_file.put_next_entry(folder + "/")
  end
  
end
