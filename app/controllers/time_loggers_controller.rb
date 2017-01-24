class TimeLoggersController < ApplicationController
  unloadable

  def index
    if User.current.nil?
      @user_time_loggers = nil
      @time_loggers = TimeLogger.all
    else
      @user_time_loggers = TimeLogger.where(user_id: User.current.id)
      @time_loggers = TimeLogger.where('user_id != ?', User.current.id)
    end
  end

  def issues
    render json: TimeLogger.pluck(:issue_id)
  end

  def start
    @time_logger = current
    @time_logger.stop unless @time_logger.nil?

    @issue = Issue.find_by_id(params[:issue_id])
    @time_logger = TimeLogger.new({ issue_id: @issue.id,
                                    status_id: @issue.status_id })

    if @time_logger.save
      apply_status_transition(@issue) unless Setting.plugin_time_logger['status_transitions'] == nil
      render_toolbar
    else
      flash[:error] = l(:start_time_logger_error)
    end
  end

  def stop
    @time_logger = current
    if @time_logger.nil?
      flash[:error] = l(:no_time_logger_running)
      redirect_to :back
    else
      @time_logger.stop
      render_toolbar
    end
  end

  def delete
    time_logger = TimeLogger.find_by_id(params[:id])
    if !time_logger.nil?
      time_logger.destroy
      render text: l(:time_logger_delete_success)
    else
      render text: l(:time_logger_delete_fail)
    end
  end

  def render_toolbar
    @project = Project.find_by_id(params[:project_id])
    @issue = Issue.find_by_id(params[:issue_id])
    render partial: 'toolbar'
  end

  protected

  def current
    TimeLogger.find_by_user_id(User.current.id)
  end

  def apply_status_transition(issue)
    new_status_id = Setting.plugin_time_logger['status_transitions'][issue.status_id.to_s]
    new_status = IssueStatus.find_by_id(new_status_id)
    if issue.new_statuses_allowed_to(User.current).include?(new_status)
      journal = @issue.init_journal(User.current, notes = l(:time_logger_label_transition_journal))
      @issue.status_id = new_status_id
      @issue.save
    end
  end
end
