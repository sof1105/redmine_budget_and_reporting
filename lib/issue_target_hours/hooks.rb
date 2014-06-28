module Redmine_budget_and_reporting

	class IssueTargetHook < Redmine::Hook::ViewListener
	
		def view_issues_form_details_bottom(context = {})
			if context[:controller] && context[:issue] && context[:controller].is_a?(IssuesController)
				r = Role.where(:name => "Projektleiter").first
				u = context[:issue].try(:project).try(:users_by_role)
				custom_field = IssueCustomField.where(:name => "Aufwand/Woche").first
				
				if (User.current.admin?) || (r && u && u[r].try(:include?, User.current))
					return context[:controller].send(:render_to_string, { :partial => 'target_hours/ajax_target_hours', 
																																:locals =>{:issue => context[:issue], :custom => custom_field}})
				end
			end
		end
	
	end

end
