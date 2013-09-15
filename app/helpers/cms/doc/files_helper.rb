module Cms::Doc::FilesHelper
  def doc_file_form(form, item, file_path = './files/', form_id = '')
    return render(:partial => 'cms/admin/tool/files/form', :locals => {:f => form, :item => item, :file_path => file_path, :form_id => form_id })
  end
  
  def doc_file_view(item)
    return render(:partial => 'cms/admin/tool/files/view', :locals => {:item => item})
  end
end
