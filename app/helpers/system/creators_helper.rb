module System::CreatorsHelper
  def creator_form(form, item)
    return ''
  end
  
  def creator_view(item)
    return '' unless item.class.include?(System::Model::Unid::Creator)
    return render(:partial => 'system/admin/creators/view', :locals => {:item => item})
  end
end
