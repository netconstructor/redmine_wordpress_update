class WordpressUpdateHooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
		if context[:controller] && context[:controller].is_a?(WordpressUpdateController)
	
			tags = [ (stylesheet_link_tag 'wordpress_update.css', :plugin => 'redmine_wordpress_update') ]
			
			jquery_included = begin
				ChiliProject::Compatibility && ChiliProject::Compatibility.using_jquery?
            rescue NameError
				false
            end
			unless jquery_included
				tags << javascript_include_tag ('jquery-1.7.2.min.js', :plugin => 'redmine_wordpress_update')
				tags << javascript_tag('jQuery.noConflict();')
			end
			
			tags << javascript_include_tag ('rails.js', :plugin => 'redmine_wordpress_update')
			
			return tags.join(' ')
		else 
			return ''
		end
    end
end
