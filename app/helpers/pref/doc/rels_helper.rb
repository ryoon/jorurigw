module Pref::Doc::RelsHelper
  def doc_rel_form(form, item)
    return '' unless item.class.include?(Pref::Model::Doc::Rel)
    return render(:partial => 'pref/admin/doc/rels/form', :locals => {:f => form, :item => item})
  end
  
  def doc_rel_view(item)
    return '' unless item.class.include?(Pref::Model::Doc::Rel)
    return render(:partial => 'pref/admin/doc/rels/view', :locals => {:item => item})
  end
end
