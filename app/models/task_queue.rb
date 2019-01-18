class TaskQueue < ApplicationRecord
  belongs_to :task
  belongs_to :user

  def self.retrieve_tasks(user, task_type)
    tasks = []
    queue = TaskQueue.where(user_id: user.id, task_type_id: task_type).order(:position)
    queue.each do |item|
      tasks.push(Task.find_by_id(item.task_id))
    end
    return tasks
  end
end
