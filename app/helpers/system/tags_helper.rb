module System::TagsHelper
  def tag_form(form, item)
    return '' unless item.class.include?(System::Model::Unid::Tag)
    return render(:partial => 'system/admin/tags/form', :locals => {:f => form, :item => item})
  end
  
  def tag_view(item)
    return '' unless item.class.include?(System::Model::Unid::Tag)
    return render(:partial => 'system/admin/tags/view', :locals => {:item => item})
  end
end
