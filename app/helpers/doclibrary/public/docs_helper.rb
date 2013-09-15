module Doclibrary::Public::DocsHelper

  def new_doclib_category_qstring()
    return "&cat=#{params[:cat]}"
  end

  def folder_doclib_category_qstring(item)
    ret = "?title_id=#{item.title_id}"
    ret += "&state=#{params[:state]}"
    ret += "&gcd=#{item.code}" if params[:state] == 'GROUP'
    ret += "&cat=#{item.id}" unless params[:state] == 'GROUP'
    ret += "#{ret}&limit=#{params[:limit]}" unless params[:limit].blank?
    return ret
  end

end
