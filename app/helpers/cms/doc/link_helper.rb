module Cms::Doc::LinkHelper
  def link_to_clone(item)
    link_to '複製', url_for(:action => :show, :id => item, :do => :clone), :confirm => '複製してよろしいですか？'
  end
end