module NewSortingIssues
	
	def self.included(base)
		base.send(:include, InstanceMethods)				
		base.class_eval do
			alias_method_chain :sort_issues!, :custom_ordering
			alias_method_chain :line_for_issue, :double_line
		end
	end
	
	module InstanceMethods
		def sort_issues_with_custom_ordering!(issues)
			#issues.sort! { |a, b| gantt_issue_compare(a, b, issues) }
			root = issues.select {|i| i.root_id == i.id}
			sort_issues_by_start_date!(root)
			issues.replace(root.map {|i| all_desc(i, issues)}.flatten)
		end

		def all_desc(issue,all_issues)
			desc=all_issues.select {|i| i.parent_id == issue.id}
			sort_issues_by_start_date!(desc)
			desc.length > 0 ? [issue] << desc.map {|i|  all_desc(i,all_issues)} : issue
		end

		def sort_issues_by_start_date!(issues)
			issues.sort! do |a,b|
				if a.start_date && b.start_date
					a.start_date <=> b.start_date
				elsif !a.start_date && !b.start_date
					0
				elsif !a.start_date && b.start_date
					-1
				else
					1
				end
			end
		end
		
		def line_for_issue_with_double_line(issue, options)
                        # Skip issues that don't have a due_before (due_date or version's due_date)
			if issue.is_a?(Issue) && issue.due_before
			  
                          total_hours = issue.total_spent_hours
			  overbooked = false
			  if issue.estimated_hours && issue.estimated_hours > 0
				progress_hours = (total_hours/issue.estimated_hours * 100).round(2)
				if progress_hours > 100
					progress_hours = 100
					overbooked = true
				end
			  elsif (issue.estimated_hours == 0 || issue.estimated_hours.nil?) && issue.total_spent_hours > 0
                                progress_hours = 100
                                overbooked = true
                          else
				progress_hours = nil
			  end
			
			  coords = coordinates(issue.start_date, issue.due_before, issue.done_ratio, options[:zoom])
			  coords_for_hours = coordinates(issue.start_date, issue.due_before, progress_hours, options[:zoom])
			  label = issue.leaf? ? "#{ issue.done_ratio }%" : "#{issue.subject} #{issue.done_ratio}%"
			  label_for_hours = progress_hours ? "#{ total_hours || 0 }/#{ issue.estimated_hours || 0 }h" : ""

			  case options[:format]
				when :html
                                        if progress_hours
                                                html_task_hours(options, coords_for_hours, :css => "task " + "leaf", :label => label_for_hours, :issue => issue, :markers => false, :overbooked => overbooked)
                                                options[:top] += 5
                                                html_task(options, coords, :css => "task " + (issue.leaf? ? 'leaf' : 'parent'), :label => label, :issue => issue, :markers => !issue.leaf?)
                                                options[:top] -= 5
                                        else
                                                html_task(options, coords, :css => "task " + (issue.leaf? ? 'leaf' : 'parent'), :label => label, :issue => issue, :markers => !issue.leaf?)
                                        end
				when :image
					image_task(options, coords, :label => label)
				when :pdf
					pdf_task(options, coords, :label => label)
				end
			else
			  ActiveRecord::Base.logger.debug "GanttHelper#line_for_issue was not given an issue with a due_before"
			  ''
			end
      end
      
      def html_task_hours(params, coords, options={})
        output = ''
        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_todo'>&nbsp;</div>".html_safe
		  if coords[:bar_progress_end]
			if options[:overbooked]
				output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_progress_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_late'>&nbsp;</div>".html_safe
			else
				output << "<div style='top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_progress_end] - coords[:bar_start] - 2}px;' class='#{options[:css]} task_done'>&nbsp;</div>".html_safe
			end
          end
        end
        # Renders the markers
        if options[:markers]
          if coords[:start]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:start] }px;width:15px;' class='#{options[:css]} marker starting'>&nbsp;</div>".html_safe
          end
          if coords[:end]
            output << "<div style='top:#{ params[:top] }px;left:#{ coords[:end] + params[:zoom] }px;width:15px;' class='#{options[:css]} marker ending'>&nbsp;</div>".html_safe
          end
        end
        # Renders the label on the right
        if options[:label]
          output << "<div style='top:#{ params[:top] - 4}px;left:#{ (coords[:bar_end] || 0) + 8 }px;' class='#{options[:css]} label'>".html_safe
          output << options[:label]
          output << "</div>".html_safe
        end
        # Renders the tooltip
        if options[:issue] && coords[:bar_start] && coords[:bar_end]
          output << "<div class='tooltip' style='position: absolute;top:#{ params[:top] }px;left:#{ coords[:bar_start] }px;width:#{ coords[:bar_end] - coords[:bar_start] }px;height:12px;'>".html_safe
          output << '<span class="tip">'.html_safe
          output << view.render_issue_tooltip(options[:issue]).html_safe
          output << "</span></div>".html_safe
        end
        @lines << output
        output
      end
	
	end
end

unless Redmine::Helpers::Gantt.included_modules.include? NewSortingIssues
	Redmine::Helpers::Gantt.send(:include, NewSortingIssues)
end
