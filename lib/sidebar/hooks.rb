module Redmine_budget_and_reporting

  class ReportingSidebarHook < Redmine::Hook::ViewListener
  
    def view_layouts_base_sidebar(context ={})
      controller = context[:controller]
      sidebar = ''
      
      # make sure sidebar is only displayed for Budget- and ReportingController
      if controller && (controller.is_a?(BudgetController) || controller.is_a?(ReportingController))
        sidebar << controller.send(:render_to_string, {
            :partial => "/sidebar/menu"
            })
      end
      
      return sidebar
    end
  
  end

end
