# Helper access from the model
class TLHelper
  include Singleton
  include TimeLoggersHelper
end

def help
  TLHelper.instance
end

class TimeLogger < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  belongs_to :status, class_name: 'IssueStatus'

  attr_accessible :issue_id, :status_id
  validates_presence_of :issue_id, :status_id

  before_save :create_time_entry, if: :status_id_changed?

  def initialize(arguments = nil)
    super(arguments)
    self.user_id = User.current.id
    self.started_on = Time.now
    self.time_spent = 0.0
    self.paused = false
    self.ping_at = Time.now
  end

  def hours_spent
    running_time + time_spent
  end

  def time_spent_to_s
    total = hours_spent
    hours = total.to_i
    minutes = ((total - hours) * 60).to_i
    hours.to_s + l(:time_logger_hour_sym) + minutes.to_s.rjust(2, '0')
  end

  def zombie?
    user = help.user_from_id(user_id)
    return true if user.nil? || user.locked?
    ping_at.nil? || Time.now - ping_at >= 10.minutes
  end

  def stop
    if hours_spent.round(2) >= 0.01
      TimeEntry.create!(project: issue.project,
                        issue: issue,
                        user: user,
                        spent_on: User.current.today,
                        hours: hours_spent.round(2),
                        comments: status.name,
                        activity: TimeEntryActivity.find_by_name(status.name) || TimeEntryActivity.default)
    end
    destroy
  end

  protected

  def running_time
    if paused
      return 0
    else
      return ((Time.now.to_i - started_on.to_i) / 3600.0).to_f
    end
  end

  private

  def create_time_entry
    return true if new_record? || hours_spent.round(2) < 0.01
    status_name = IssueStatus.find(status_id_was).name
    TimeEntry.create!(project: issue.project,
                      issue: issue,
                      user: user,
                      spent_on: User.current.today,
                      hours: hours_spent.round(2),
                      comments: status_name,
                      activity: TimeEntryActivity.find_by_name(status_name) || TimeEntryActivity.default)
    self.started_on = Time.now
  end
end
