module System::InquiriesHelper
  def inquiry_form(form, item, options = {})
    return '' unless item.class.include?(System::Model::Unid::Inquiry)
    return render(:partial => 'system/admin/inquiries/form', :locals => {:f => form, :item => item}, :options => options)
  end

  def inquiry_view(item)
    return '' unless item.class.include?(System::Model::Unid::Inquiry)
    return render(:partial => 'system/admin/inquiries/view', :locals => {:item => item})
  end
end
