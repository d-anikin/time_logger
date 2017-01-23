require_dependency 'issue'

module TimeLoggerIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      before_save :update_time_logger_status, if: :status_id_changed?
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def update_time_logger_status
      TimeLogger.where(issue_id: id).each do |time_logger|
        time_logger.status_id = status_id
        time_logger.save
      end
    end
  end
end

# Add module to Issue
Issue.send(:include, TimeLoggerIssuePatch)
