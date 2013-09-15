module System::RecognizersHelper
  def recognizer_form(form, item)
    return '' unless item.class.include?(System::Model::Unid::Recognition)
    return render(:partial => 'system/admin/recognizers/form', :locals => {:f => form, :item => item})
  end
  
  def recognizer_view(item)
    return '' unless item.class.include?(System::Model::Unid::Recognition)
    return render(:partial => 'system/admin/recognizers/view', :locals => {:item => item})
  end
end
