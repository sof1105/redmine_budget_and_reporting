module Redmine_budget_and_reporting

	class IssueTargethoursHook < Redmine::Hook::ViewListener
	
		def view_issues_form_details_bottom(context = {})
			if context[:controller] && context[:issue] && context[:controller].is_a?(IssuesController)
				if (User.current.admin?) 
					return context[:controller].send(:render_to_string, { :partial => 'weekeffort/ajax_target_hours', 
																																:locals =>{:issue => context[:issue]}})
				end
			end
		end
		
		def view_layouts_base_sidebar(context = {})
			if context[:controller] && User.current.admin? && 
				(context[:controller].is_a?(IssuesController) || context[:controller].is_a?(WeekeffortController))
				return context[:controller].send(:render_to_string, {:partial => "weekeffort/sidebar"})
			end
		end
	
	end

end
