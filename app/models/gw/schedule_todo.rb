class Gw::ScheduleTodo < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  belongs_to :schedule, :foreign_key => :schedule_id, :class_name => 'Gw::Schedule'

  def self.finished_select
    item = [['未完了', 0],['完了', 1]]
    return item
  end

  def self.finished_show(finished)
    item = [[0, '未完了'],[1, '完了']]
    show_str = item.assoc(finished)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.params_set(params)
    ret = ""
    'page:sort_keys:s_finished'.split(':').each_with_index do |col, idx|
      unless params[col.to_sym].blank?
        ret += "&" unless ret.blank?
        ret += "#{col}=#{params[col.to_sym]}"
      end
    end
    ret = '?' + ret unless ret.blank?
    return ret
  end

  def self.create_todo_url(request_url, todo = nil)

    if request_url.index('todo=1')
      return request_url.sub('todo=1', 'todo=0')
    elsif request_url.index('todo=0')
      return request_url.sub('todo=0', 'todo=1')

    else
      request_url_index_ret = request_url.index('?')
      if request_url_index_ret.blank?
        request_url = request_url + '?'
      else
        request_url = request_url + '&amp;'
      end

      todos_display = Gw::UserProperty.is_todos_display?(todo)
      if todos_display
         todo_url = request_url + 'todo=0'
      else
         todo_url = request_url + 'todo=1'
      end
      return todo_url
    end
  end
end
