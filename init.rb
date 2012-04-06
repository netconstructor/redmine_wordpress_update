require 'redmine'
require 'rubygems'

require_dependency 'wordpress_update_hooks'

Redmine::Plugin.register :redmine_wordpress_update do
	name 'Redmine Wordpress Update plugin'
	author 'Chris Roemmich'
	description 'Creates zip files and metadata to allow external wordpress plugin and theme updates.'
	version '0.9.0'
	
	project_module :wordpress_update do
		permission :wordpress_update, :wordpress_update => [ :index , :create, :update ]
	end
	
	menu :project_menu, :wordpress_update, {:controller => 'wordpress_update', :action => 'index'}, :caption => 'Wordpress Update', :param => :project_id
end