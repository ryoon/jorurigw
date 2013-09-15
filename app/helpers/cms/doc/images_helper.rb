module Cms::Doc::ImagesHelper
  def doc_image_form(form, item)
    return render(:partial => 'cms/admin/doc/images/form', :locals => {:f => form, :item => item})
  end

  def doc_image_view(item)
    return render(:partial => 'cms/admin/doc/images/view', :locals => {:item => item})
  end
end
