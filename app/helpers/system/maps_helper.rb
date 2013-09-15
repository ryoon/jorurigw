module System::MapsHelper
  def map_form(form, item)
    return '' unless item.class.include?(System::Model::Unid::Map)
    return render(:partial => 'system/admin/maps/form', :locals => {:f => form, :item => item})
  end
  
  def map_view(item)
    return '' unless item.class.include?(System::Model::Unid::Map)
    return render(:partial => 'system/admin/maps/view', :locals => {:item => item})
  end
end
