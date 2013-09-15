module Gwqa::Public::CategoriesHelper

  def link_to_list_gwqa_category(item)
    link_to '展開', url_for(item.link_list_path)
  end

end
