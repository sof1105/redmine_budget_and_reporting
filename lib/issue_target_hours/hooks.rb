module Redmine_budget_and_reporting

	class IssueTargetHook < Redmine::Hook::ViewListener
	
		def view_issues_form_details_bottom(context = {})
			if context[:controller] && context[:issue] && context[:controller].is_a?(IssuesController)
				if (User.current.admin?) 
					return context[:controller].send(:render_to_string, { :partial => 'weekeffort/ajax_target_hours', 
																																:locals =>{:issue => context[:issue]}})
				end
			end
		end
	
	end

end
