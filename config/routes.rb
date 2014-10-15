QuickDry::Engine.routes.draw do

	# put these at the end of the routes.rb so as not to interfere with default rails routes
	get 	'/:table_name(.:format)', 			to: 'quick_dry#index',	table_name:/[^\/]*/, 			as: :instances
	post 	'/:table_name(.:format)', 			to: 'quick_dry#create', table_name:/[^\/]*/
	get 	'/:table_name/:id(.:format)', 		to: 'quick_dry#show', 	table_name:/[^\/]*/, id:/[\d]*/,as: :instance
	put 	'/:table_name/:id(.:format)', 		to: 'quick_dry#update', table_name:/[^\/]*/, id:/[\d]*/
	patch 	'/:table_name/:id(.:format)', 		to: 'quick_dry#update', table_name:/[^\/]*/, id:/[\d]*/
	delete	'/:table_name/:id(.:format)', 		to: 'quick_dry#destroy',table_name:/[^\/]*/, id:/[\d]*/
	get 	'/:table_name/:id/edit(.:format)', 	to: 'quick_dry#edit', 	table_name:/[^\/]*/, id:/[\d]*/,as: :edit_instance
	get 	'/:table_name/new(.:format)', 		to: 'quick_dry#new', 	table_name:/[^\/]*/, 			as: :new_instance


end
