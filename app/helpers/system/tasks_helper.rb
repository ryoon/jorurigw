module System::TasksHelper
  def task_form(form, item)
    return '' unless item.class.include?(System::Model::Unid::Task)
    return render(:partial => 'system/admin/tasks/form', :locals => {:f => form, :item => item})
  end
  
  def task_view(item)
    return '' unless item.class.include?(System::Model::Unid::Task)
    return render(:partial => 'system/admin/tasks/view', :locals => {:item => item})
  end
end
