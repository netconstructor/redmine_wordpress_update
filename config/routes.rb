if defined? map
	map.with_options :controller => 'wordpress_update' do |wp_routes|
		wp_routes.match ':wordpress_update/download/:slug', :action => 'download'
		wp_routes.match ':wordpress_update/meta/:slug', :action => 'meta'
		wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:get] }, :action => 'index'
		wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:post, :put] }, :action => 'update'
		wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:delete] }, :action => 'destroy'
	end
else
	ActionController::Routing::Routes.draw do |map|
		map.with_options :controller => 'wordpress_update' do |wp_routes|
			wp_routes.match ':wordpress_update/download/:slug', :action => 'download'
			wp_routes.match ':wordpress_update/meta/:slug', :action => 'meta'
			wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:get] }, :action => 'index'
			wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:post, :put] }, :action => 'update'
			wp_routes.connect 'projects/:project_id/wordpress_update', :conditions => { :method => [:delete] }, :action => 'destroy'
		end
	end
end
