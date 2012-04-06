require 'digest/sha1'
require 'securerandom'
require_dependency 'wp_zip'

class WordpressUpdateController < ApplicationController
	unloadable

	before_filter :find_project_resource_and_repo, :except => [ :meta, :download ]
	before_filter :find_project_resource_and_repo_by_slug, :only => [ :meta, :download ]
	
	before_filter :authorize, :except => [ :meta, :download ]
	before_filter :authorize_annon, :only => [ :meta, :download ]
	before_filter :check_token, :only => [ :meta, :download ]

	def index
		update_cache if @resource.nil?
	
		if !params[:token_action].blank? && !params[:token_id].blank?
			t = DownloadToken.find_by_id_and_resource_id(params[:token_id], @resource.id)					
			flash[:notice] = 'Invalid Token Id' if t.nil?
			unless t.nil?
				t.destroy if params[:token_action] == 'delete'
				t.active = true if params[:token_action] == 'activate'
				t.active = false if params[:token_action] == 'deactivate'
				if (params[:token_action] == 'deactivate' || params[:token_action] == 'activate')
					flash[:notice] = 'Could Not Complete Token Action' unless t.save
				end
			end
		end
		
		@tokens = DownloadToken.find_all_by_resource_id(@resource.id)
		@token = DownloadToken.new
		@token.token = SecureRandom.hex(16)
		
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @tokens }
		end
	end
	
	def update
		@token = DownloadToken.new(params[:download_token])
		@token.resource_id = @resource.id
		@token.active = true
		
		respond_to do |format|
			if !params[:download_token].blank?
				if @token.save
					flash[:notice] = 'Token was successfully added.'
					format.js
					format.html { redirect_to :action => 'index' }
					format.xml  { render :xml => @token, :status => :created, :location => @token }
				else
					format.html { render :action => 'index' }
					format.xml  { render :xml => @token.errors, :status => :unprocessable_entity }
				end
			elsif !params[:resource].blank?
				update_cache
				if @resource.update_attributes(params[:resource])
					flash[:notice] = 'Resource and Cache was successfully updated.'
					format.js
					format.html { redirect_to :action => 'index' }
					format.xml  { render :xml => @resource, :status => :created, :location => @resource }
				else
					format.html { render :action => 'index' }
					format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
				end
			else
				format.html { redirect_to :action => 'index' }
			end
		end
	end
	
	@@plugin_regex = {
		:version => /^[\s\*]*version[\s]*:(.*)$/i,
		:plugin_name => /^[\s\*]*plugin name[\s]*:(.*)$/i,
	}
	
	@@theme_regex = {
		:version => /^[\s\*]*version[\s]*:(.*)$/i,
		:theme_name => /^[\s\*]*theme name[\s]*:(.*)$/i
	}
	
	def meta
		render :json => create_meta_hash
	end
	
	def download
		meta_hash = create_meta_hash;
		filename = @resource.slug + '_' + meta_hash[:version] + '.zip'
		
		@attachment = Attachment.find_by_container_id_and_container_type_and_filename(@project.id, 'Project', filename)
		if (@attachment.nil?)
			zip = WpZip.new
			zip_entries(zip, @repository.entries(nil, @repository.default_branch))
			@attachment = Attachment.new(:file => zip.finish)
			@attachment.container = @project
			@attachment.author = @project.users.first
			@attachment.filename = filename
			return render_unauthorized unless @attachment.save
		end
		
		@attachment.increment_download
		
		log = DownloadLog.new
		log.resource_id = @resource.id
		log.ip = request.remote_ip
		log.download_token_id = @token.id unless @token.nil?
		log.save
		
		send_file(@attachment.diskfile, 
			:filename => filename_for_content_disposition(@attachment.filename),
			:type => "application/zip", 
			:disposition => "attachment")
			
		ensure
			zip.close unless zip.nil?
	end

	private

	def	find_project_resource_and_repo
		@project = Project.find(params[:project_id])
		@resource = Resource.find_by_project_id(@project.id)
		@repository = Repository.find_by_project_id_and_is_default(@project.id, true)
	end
	
	def find_project_resource_and_repo_by_slug
		@resource = Resource.find_by_slug(params[:slug])
		return render_unauthorized if @resource.nil?
		@project = @resource.project
		@repository = Repository.find_by_project_id_and_is_default(@project.id, true)
	end
	
	def find_repository
		@repository.fetch_changesets
	end
	
	def authorize_annon
		return render_unauthorized unless @project.module_enabled?(:wordpress_update)
	end
	
	def check_token
		@valid_token = @resource.public;
		return if @valid_token
		return render_unauthorized if (params[:plain].blank? || params[:encrypted].blank?)
		
		@resource.download_tokens.each do |token|
			next unless token.active
			next unless Digest::SHA1.hexdigest(params[:plain] + token.token) == params[:encrypted]
			@valid_token = true
		end
		
		render_unauthorized unless @valid_token 
	end
	
	def render_unauthorized
		render :json => { :error => "Unauthorized" }, :status => :unauthorized
	end
	
	def update_cache
		@resource = Resource.new if @resource.nil?
		@resource.project_id = @project.id
		
		unless @repository.nil?
			@repository.fetch_changesets
			@resource.slug = @repository.name if @resource.slug.nil?
			
			entries = @repository.entries(nil, @repository.default_branch)
			entries.each do |entry|
				has_plugin_name = false;
				has_theme_name = false;
				has_version = false;
				unless entry.is_dir?
					ent_path = Redmine::CodesetUtil.replace_invalid_utf8(entry.path)
					if ent_path =~ /\.(php[4-5]{0,1}|css)$/i
						content = @repository.cat(ent_path, @repository.default_branch)
						unless content.nil?
							content.each_line do |line|
								if line =~ @@plugin_regex[:version]
									has_version = true;
								elsif line =~ @@plugin_regex[:plugin_name]
									has_plugin_name = true;
								elsif line =~ @@theme_regex[:theme_name]
									has_theme_name = true;
								end
							end
						end
					end
				end
				if has_plugin_name && has_version
					@resource.cached_type = 'plugin'
					@resource.cached_meta_file = ent_path
					break
				elsif has_theme_name && has_version
					@resource.cached_type = 'theme'
					@resource.cached_meta_file = ent_path
					break
				end
			end
		end
		
		@resource.save		
	end

	def create_meta_hash
		return render_unauthorized if @resource.nil?
		@repository.fetch_changesets
		meta_content = @repository.cat(@resource.cached_meta_file, @repository.default_branch)
		return render_unauthorized if meta_content.nil?
		
		hash = { :slug => @resource.slug }
		
		regexps = @@theme_regex;
		if @resource.cached_type == 'plugin'
			regexps = @@plugin_regex
		end
		
		meta_content.each_line do |line|
			regexps.each do |name, exp|
				match = value = exp.match(line)
				unless match.nil? || match.size < 1
					hash[name] = match[1].strip
				end
			end
		end
		
		hash[:download_url] = url_for :action => 'download', :slug => params[:slug]
		hash
	end
	
	def zip_entries(zip, entries)
		entries.each do |entry|
			if (entry.is_dir?)
				zip.add_folder(entry.path)
				zip_entries(zip, entries = @repository.entries(entry.path, @repository.default_branch))
			else
				zip.add_file(entry.path, @repository.cat(entry.path, @repository.default_branch))
			end
		end
		zip
	end
end