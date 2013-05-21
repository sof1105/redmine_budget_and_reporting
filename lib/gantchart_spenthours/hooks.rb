
module Redmine_budget_and_reporting

    class SpenthoursHooks < Redmine::Hook::ViewListener
        def controller_issues_edit_before_save(context = {})
            if !context[:issue].parent.nil?
                context[:issue].fixed_version = context[:issue].parent.fixed_version
            end
        end
        
        def controller_issues_new_before_save(context = {})
            if context[:issue].parent_issue_id && !(context[:issue].parent_issue_id.nil? || context[:issue].parent_issue_id.blank?)
                begin
                    context[:issue].fixed_version = Issue.find(context[:issue].parent_issue_id).fixed_version
                rescue ActiveRecord::RecordNotFound
                    return
                end
            end
        end
    end
end
