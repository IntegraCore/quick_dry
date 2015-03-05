require_dependency "quick_dry/application_controller"
require 'json'

module QuickDry
	class QuickDryController < ApplicationController
		protect_from_forgery #unless Rails.env = "development"
		before_action :instantiate_paths
		
		# nasty hack until I can get an answer on the official way to remove the instance root keys in a list
		def serialize stuff
			if stuff.is_a? Array or stuff.is_a? ActiveRecord::Relation
				json = render_to_string json:QuickDryArraySerializer.new(stuff, root:get_model.model_name.route_key )
				hash = JSON.parse(json)
				temp = []
				if hash[get_model.model_name.route_key].first.has_key? get_model.model_name.route_key
					hash[get_model.model_name.route_key].each{|x| temp << x[get_model.model_name.route_key]}
					hash[get_model.model_name.route_key] = temp
					return hash.to_json
				end
				return json
			elsif stuff.is_a? get_model
			end
		end

		# GET /table_name
		# GET /table_name.json
		def index
			# results = get_paged_search_results(params,user:current_user)
			# params = results[:params]
			#puts params.inspect
			#turn param_name:begin and param_name:end into a range
			
			params.keys.select{|x| x =~ /^(.*)\:(.*)$/}.each do |x|
				key = x.split(":").first
				op = x.split(":").last
				params[key] = [params["#{key}:begin"]..params["#{key}:end"]] if(op=="begin" && params["#{key}:end"])
			end

			#turn parameter ending in ! to a not statement
			select_me_not = {}
			params.keys.select{|x| x =~ /\!$/}.each do |param|
				key = param.split("!").first
				select_me_not[key] = params[param]
			end
			
			#only include search params that are columns in the model
			search_params = params.select{|x| get_model.column_names.index x}
			likes = {}

			#if the parameter value has one or more of the % character, make it a LIKE search
			search_params.keys.select{|x| search_params[x].is_a?(String) && search_params[x] =~ /\%/}.each do |key|
				likes[key] = search_params[key]
				search_params.delete(key)
			end
			likes_array = likes.size > 0 ? [likes.keys.join(" like ? and ")+" like ?"] + likes.values : []
			#puts likes_array.inspect


			#puts params.inspect
			#if(search_params.size > 0)
			if params['_limit'].to_i < 1
				@instances = get_model.where(search_params).where(likes_array).where.not(select_me_not)
			else
				@instances = get_model.where(search_params).where(likes_array).where.not(select_me_not).limit(params['_limit'].to_i)
			end
			#else 
				#@instances = get_model.where.not(select_me_not)
			#end
			# render 'quick_dry/index'
			respond_to do |format|
				# format.json { render body:@instances.to_json, content_type:'application/json'} # using the json parameter nests objects inside of quick_dry keys
				format.json { render json:serialize(@instances)}#, each_serializer: QuickDrySerializer}# serializer:QuickDryArraySerializer}
				format.html { render 'quick_dry/index'}
			end
		end

		# GET /table_name/new
		def new
			@instance = get_model.new
			render 'quick_dry/new'
		end

		# GET /table_name/1
		# GET /table_name/1.json
		def show
			@instance = get_model.find(params[:id])

			respond_to do |format|
				format.json { 
					render json:@instance, root:get_model.model_name.route_key}
				format.html { render 'quick_dry/show'}
			end
		end

		# POST /table_name
		# POST /table_name.json
		def create
			@instance = get_model.new(instance_params)

			respond_to do |format|
				if @instance.save
					flash[:notice] = "#{get_model.name} was successfully created."
					format.html { render 'quick_dry/show' }
					format.json { render json:@instance, status: :created, location: get_url }
				else
					format.html { render 'quick_dry/new' }
					format.json { render json:@instance.errors, status: :unprocessable_entity }
				end
			end
		end

		# GET /table_name/1/edit
		def edit
			@instance = get_model.find(params[:id])
			render 'quick_dry/edit'
		end

		# PATCH/PUT /table_name/1
		# PATCH/PUT /table_name/1.json
		def update
			@instance = get_model.find(params[:id])

			respond_to do |format|
				if @instance.update(instance_params)
					flash[:notice] = "#{get_model.name} was successfully updated."
					format.html { render 'quick_dry/show' }
					format.json { render json:@instance, status: :ok, location: get_url}
				else
					format.html { render 'quick_dry/edit' }
					format.json { render json: @instance.errors, status: :unprocessable_entity}
				end
			end
		end

		# DELETE /table_name/1
		# DELETE /table_name/1.json
		def destroy
			get_model.destroy(params[:id])
			respond_to do |format|
				format.html { redirect_to "/#{get_model.model_name.route_key}", notice: "#{get_model.name} was successfully destroyed." }
				format.json { head :no_content }
			end
		end

		def get_url target:@instance
			target_url = "/unknown_route"
			return target_url = "#{get_model.model_name.route_key}" if target.is_a? ActiveRecord::Relation
			return target_url = "#{get_model.model_name.route_key}/#{target.id}" if target.is_a? ActiveRecord::Base
			return target_url
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def instance_params
			model = get_model
			# get all params except for id, and the standard dates
			respond_to do |format|
				format.html {  }
				format.json do
					body = JSON.parse(request.body.read)
					if body.is_a? Hash
						pascal = model.model_name.singular_route_key.camelize
						camel = model.model_name.singular_route_key.camelize(:lower)
						snake = model.model_name.singular_route_key
						# instance_name 
						if body.has_key? snake
							params.merge!(body)
						# instanceName
						elsif body.has_key? camel
							params.merge!({snake => body[camel]})
						# InstanceName
						elsif body.has_key? pascal
							params.merge!({snake => body[pascal]})
						else
							params[model.model_name.singular_route_key] = body
						end
					end
				end
			end
			return params.require(model.model_name.singular_route_key.to_sym).permit(model.attribute_names.collect{|x| x.to_sym} - [:id,:created_at,:updated_at])
		end

		def append_route(proc:nil,&block)
			begin
				_routes = Rails.application.routes
				_routes.disable_clear_and_finalize = true
				_routes.clear!
				Rails.application.routes_reloader.paths.each{ |path| load(path) }

				_routes.draw &proc unless proc.blank?
				_routes.draw &block if block_given? and proc.blank?

				_routes.finalize!
			ensure
				_routes.disable_clear_and_finalize = false
			end
		end

		alias_method :append_routes, :append_route

		def instantiate_paths
			route = eval %(lambda {resources :#{get_model.model_name.route_key}, controller: 'quick_dry'})
			append_route proc:route
			# append_route {resources get_model.model_name.route_key.to_sym, path: 'quick_dry'}
			# routes= Rails.application.routes.routes.map { |route| {alias: route.name, path: route.path.spec.to_s, method: "#{route.defaults[:controller]}##{route.defaults[:action]}"}}
		end

		# this will only work in conjunction with the routing provided with the engine
		def get_model
			model = request.params[:table_name].classify.constantize unless request.params[:table_name].blank?
			# model.blank? ? return nil : return model
		end

		# Assumes the existance of a User model
		def get_paged_search_results(params,user:nil,model:nil)
			params[:per_page] = 10 if params[:per_page].blank?
			params[:page] = 1 if params[:page].blank?
			# a ghetto user check, but for some reason a devise user is not a devise user...
			user = User.new if user.blank? or !user.class.to_s == User.to_s

			# get the model in question
			# there has got to be a better way to do this... I just can't find it
			# model = params[:controller].blank? ? self.class.name.gsub('Controller','').singularize.constantize : params[:controller].classify.constantize
			if model.blank? 
				model = request.params[:table_name].classify.constantize unless request.params[:table_name].blank?
				return nil if model.blank?
			end

			# initialize un-paged filtered result set
			result_set = model.none

			# create where clauses to filter result to just the customers the current user has access to
			customer_filter = ""
			user.customers.each do |cust|
				if model.column_names.include? "cust_id"
					customer_filter << "(cust_id = '#{cust.cust_id(true)}') OR " unless cust.cust_id.blank?
				elsif model.attribute_alias? "cust_id"
					customer_filter << "(#{model.attribute_alias "cust_id"} = '#{cust.cust_id(true)}') OR " unless cust.cust_id.blank?
				elsif model.column_names.include? "order_number"
					customer_filter << "(order_number like '#{cust.prefix}%') OR " unless cust.prefix.blank?
				elsif model.attribute_alias? "order_number"
					customer_filter << "(#{model.attribute_alias "order_number"} like '#{cust.prefix}%') OR " unless cust.prefix.blank?
				end
			end
			customer_filter << " (1=0)"

			# create where clauses for each search parameter
			if params[:columns].blank?
				result_set = model.where(customer_filter)
			else
				where_clause = ""
				params[:columns].each do |name, value|
					where_clause << "(#{model.table_name}.#{name} like '%#{value}%') AND " unless value.blank?
				end
				where_clause << " (1=1)"

				result_set = model.where(customer_filter).where(where_clause)
			end

			instances = model.paginate(page: params[:page], per_page: params[:per_page]).merge(result_set).order(updated_at: :desc)
			return {instances:instances,params:params}
		end

		def default_serializer_options
		  {
		    root: get_model.model_name.route_key#,
		    # model_class: get_model
		  }
		end



		# # POST /customer_orders
		# # POST /customer_orders.json
		# def create
		# @customer_order = CustomerOrder.new(customer_order_params)

		# respond_to do |format|
		# if @customer_order.save
		# format.html { redirect_to @customer_order, notice: 'Customer order was successfully created.' }
		# format.json { render :show, status: :created, location: @customer_order }
		# else
		# format.html { render :new }
		# format.json { render json: @customer_order.errors, status: :unprocessable_entity }
		# end
		# end
		# end

		# # PATCH/PUT /customer_orders/1
		# # PATCH/PUT /customer_orders/1.json
		# def update
		# respond_to do |format|
		# if @customer_order.update(customer_order_params)
		# format.html { redirect_to @customer_order, notice: 'Customer order was successfully updated.' }
		# format.json { render :show, status: :ok, location: @customer_order }
		# else
		# format.html { render :edit }
		# format.json { render json: @customer_order.errors, status: :unprocessable_entity }
		# end
		# end
		# end

		# # DELETE /customer_orders/1
		# # DELETE /customer_orders/1.json
		# def destroy
		# @customer_order.destroy
		# respond_to do |format|
		# format.html { redirect_to customer_orders_url, notice: 'Customer order was successfully destroyed.' }
		# format.json { head :no_content }
		# end
		# end

		# private
		# # Use callbacks to share common setup or constraints between actions.
		# def set_customer_order
		# @customer_order = CustomerOrder.find(params[:id])
		# end
	end
end
