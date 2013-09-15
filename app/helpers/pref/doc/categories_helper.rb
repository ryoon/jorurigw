module Pref::Doc::CategoriesHelper
  def doc_category_form(form, item)
    return '' unless item.class.include?(Pref::Model::Doc::Category)
    return render(:partial => 'pref/admin/doc/categories/form', :locals => {:f => form, :item => item})
  end
  
  def doc_category_view(item)
    return '' unless item.class.include?(Pref::Model::Doc::Category)
    return render(:partial => 'pref/admin/doc/categories/view', :locals => {:item => item})
  end
end
